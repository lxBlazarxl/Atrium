import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/myspeed_status.dart';
import '../models/myspeed_test.dart';
import '../myspeed_providers.dart';
import '../widgets/myspeed_test_card.dart';

class MySpeedStatusTab extends ConsumerStatefulWidget {
  const MySpeedStatusTab({required this.instance, super.key});

  final Instance instance;

  @override
  ConsumerState<MySpeedStatusTab> createState() => _MySpeedStatusTabState();
}

class _MySpeedStatusTabState extends ConsumerState<MySpeedStatusTab> {
  Timer? _pollingTimer;
  bool _isLocallyRunning = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  Future<void> _poll() async {
    if (!mounted) return;
    final int activeTab = ref.read(myspeedActiveTabBarIndexProvider(widget.instance));
    final bool wasRunning = _isLocallyRunning ||
        (ref.read(myspeedStatusProvider(widget.instance)).value?.isRunning ?? false);
    if (activeTab != 0 && !wasRunning) return;

    ref.invalidate(myspeedStatusProvider(widget.instance));
    ref.invalidate(myspeed24HourTestsProvider(widget.instance));

    MySpeedStatus? newStatus;
    try {
      newStatus = await ref.read(myspeedStatusProvider(widget.instance).future);
    } catch (_) {
      newStatus = null;
    }

    if (!mounted) return;

    if (_isLocallyRunning && (newStatus == null || !newStatus.isRunning)) {
      setState(() => _isLocallyRunning = false);
      ref.invalidate(myspeed24HourTestsProvider(widget.instance));
      ref.read(myspeedHistoryProvider(widget.instance).notifier).fetchDiff();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _runSpeedtest() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Run Speedtest'),
        content: Text('Start a new speedtest on ${widget.instance.name}?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLocallyRunning = true);

    try {
      final api = await ref.read(myspeedApiProvider(widget.instance).future);
      await api.runSpeedtest();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speedtest triggered successfully')),
      );
      await _poll();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLocallyRunning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to trigger speedtest: $e')),
      );
      ref.invalidate(myspeedStatusProvider(widget.instance));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final AsyncValue<MySpeedStatus> statusAsync =
        ref.watch(myspeedStatusProvider(widget.instance));
    final MySpeedTest? latestTest = ref.watch(myspeedLatestTestProvider(widget.instance));
    final AsyncValue<List<MySpeedTest>> speedtests24hAsync =
        ref.watch(myspeed24HourTestsProvider(widget.instance));

    return AsyncValueView<MySpeedStatus>(
      value: statusAsync,
      onRetry: () {
        ref.invalidate(myspeedStatusProvider(widget.instance));
        ref.invalidate(myspeed24HourTestsProvider(widget.instance));
      },
      data: (MySpeedStatus status) {
        final MySpeedStatus effectiveStatus = _isLocallyRunning
            ? const MySpeedStatus(
                isRunning: true,
                message: 'Speedtest in progress...',
              )
            : status;

        return EasyRefresh(
          onRefresh: () async {
            ref.invalidate(myspeedStatusProvider(widget.instance));
            ref.invalidate(myspeed24HourTestsProvider(widget.instance));
            await Future.wait(<Future<dynamic>>[
              ref.read(myspeedStatusProvider(widget.instance).future),
              ref.read(myspeed24HourTestsProvider(widget.instance).future),
              ref.read(myspeedHistoryProvider(widget.instance).notifier).fetchDiff(),
            ]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: Insets.page,
            children: <Widget>[
              _buildStatusCard(context, effectiveStatus),
              const SizedBox(height: Insets.md),
              _buildRunCard(context, effectiveStatus),
              const SizedBox(height: Insets.md),
              _buildLatestResultCard(context, latestTest),
              const SizedBox(height: Insets.lg),
              Divider(color: colors.outlineVariant.withValues(alpha: 0.4)),
              const SizedBox(height: Insets.md),
              _build24HourResultsSection(context, speedtests24hAsync),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(BuildContext context, MySpeedStatus status) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color accent = ServiceVisuals.accent(widget.instance.kind);
    final bool isRunning = status.isRunning;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isRunning
              ? accent.withValues(alpha: 0.6)
              : colors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      color: isRunning
          ? accent.withValues(alpha: 0.08)
          : colors.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isRunning
                        ? accent.withValues(alpha: 0.2)
                        : colors.surfaceContainerHigh,
                  ),
                  child: Icon(
                    isRunning ? Icons.network_check_rounded : Icons.speed_rounded,
                    color: isRunning ? accent : colors.onSurfaceVariant,
                    size: 28,
                  ),
                ),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Execution Status',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isRunning ? 'Speedtest Running' : 'Idle',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isRunning ? accent : colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isRunning
                        ? accent.withValues(alpha: 0.15)
                        : colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isRunning ? 'ACTIVE' : 'IDLE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isRunning ? accent : colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunCard(BuildContext context, MySpeedStatus status) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isRunning = status.isRunning;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      color: colors.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Manual Speedtest',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Trigger an immediate test run',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: isRunning ? null : _runSpeedtest,
              child: const Text('Run Test'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestResultCard(BuildContext context, MySpeedTest? latest) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      color: colors.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Most Recent Result',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (latest != null)
                  Text(
                    '#${latest.id}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Insets.md),
            if (latest != null)
              Row(
                children: <Widget>[
                  Expanded(
                    child: MySpeedMetricBox(
                      icon: Icons.arrow_downward_rounded,
                      label: 'DOWN',
                      value: latest.download.toStringAsFixed(1),
                      unit: 'Mbps',
                      iconColor: colors.primary,
                      boxColor: colors.primaryContainer.withValues(alpha: 0.25),
                      borderColor: colors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  const SizedBox(width: Insets.xs),
                  Expanded(
                    child: MySpeedMetricBox(
                      icon: Icons.arrow_upward_rounded,
                      label: 'UP',
                      value: latest.upload.toStringAsFixed(1),
                      unit: 'Mbps',
                      iconColor: colors.tertiary,
                      boxColor: colors.tertiaryContainer.withValues(alpha: 0.25),
                      borderColor: colors.tertiary.withValues(alpha: 0.25),
                    ),
                  ),
                  const SizedBox(width: Insets.xs),
                  Expanded(
                    child: MySpeedMetricBox(
                      icon: Icons.timer_outlined,
                      label: 'PING',
                      value: latest.ping.toStringAsFixed(0),
                      unit: 'ms',
                      iconColor: colors.secondary,
                      boxColor: colors.secondaryContainer.withValues(alpha: 0.25),
                      borderColor: colors.secondary.withValues(alpha: 0.25),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _build24HourResultsSection(
    BuildContext context,
    AsyncValue<List<MySpeedTest>> speedtests24hAsync,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '24-Hour Results',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Insets.sm),
        speedtests24hAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (List<MySpeedTest> tests) {
            if (tests.isEmpty) {
              return const Text('No results in last 24 hours');
            }
            return Column(
              children: tests.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: Insets.sm),
                child: MySpeedTestCard(test: t),
              )).toList(),
            );
          },
        ),
      ],
    );
  }
}
