import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/myspeed_status.dart';
import '../models/myspeed_test.dart';
import '../myspeed_providers.dart';
import '../widgets/myspeed_test_card.dart';

class MySpeedStatusTab extends ConsumerWidget {
  const MySpeedStatusTab({required this.instance, super.key});

  final Instance instance;

  Future<void> _runSpeedtest(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Run Speedtest'),
        content: Text('Start a new speedtest on ${instance.name}?'),
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

    if (confirmed != true || !context.mounted) return;

    try {
      final api = await ref.read(myspeedApiProvider(instance).future);
      await api.runSpeedtest();
      ref.invalidate(myspeedStatusProvider(instance));
      ref.invalidate(myspeed24HourTestsProvider(instance));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speedtest triggered successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to trigger speedtest: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final AsyncValue<MySpeedStatus> statusAsync =
        ref.watch(myspeedStatusProvider(instance));
    final MySpeedTest? latestTest = ref.watch(myspeedLatestTestProvider(instance));
    final AsyncValue<List<MySpeedTest>> speedtests24hAsync =
        ref.watch(myspeed24HourTestsProvider(instance));

    return AsyncValueView<MySpeedStatus>(
      value: statusAsync,
      onRetry: () {
        ref.invalidate(myspeedStatusProvider(instance));
        ref.invalidate(myspeed24HourTestsProvider(instance));
      },
      data: (MySpeedStatus status) {
        return EasyRefresh(
          onRefresh: () async {
            ref.invalidate(myspeedStatusProvider(instance));
            ref.invalidate(myspeed24HourTestsProvider(instance));
            await Future.wait(<Future<dynamic>>[
              ref.read(myspeedStatusProvider(instance).future),
              ref.read(myspeed24HourTestsProvider(instance).future),
            ]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: Insets.page,
            children: <Widget>[
              _buildStatusCard(context, status),
              const SizedBox(height: Insets.md),
              _buildRunCard(context, ref, status),
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
    final Color accent = ServiceVisuals.accent(instance.kind);
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

  Widget _buildRunCard(BuildContext context, WidgetRef ref, MySpeedStatus status) {
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
              onPressed: isRunning ? null : () => _runSpeedtest(context, ref),
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
