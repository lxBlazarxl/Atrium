import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/myspeed_status.dart';
import '../models/myspeed_test.dart';
import '../myspeed_providers.dart';

/// Tab 0: Status & control tab.
///
/// Displays whether a speedtest is currently running, triggers manual tests,
/// and presents the most recent speedtest result.
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
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.bolt_rounded),
            label: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final api = await ref.read(myspeedApiProvider(instance).future);
      await api.runSpeedtest();
      ref.invalidate(myspeedStatusProvider(instance));
      ref.invalidate(myspeedHistoryProvider(instance));
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
    final AsyncValue<MySpeedStatus> statusAsync =
        ref.watch(myspeedStatusProvider(instance));
    final MySpeedTest? latestTest = ref.watch(myspeedLatestTestProvider(instance));
    final AsyncValue<List<MySpeedTest>> historyAsync =
        ref.watch(myspeedHistoryProvider(instance));

    return AsyncValueView<MySpeedStatus>(
      value: statusAsync,
      onRetry: () {
        ref.invalidate(myspeedStatusProvider(instance));
        ref.invalidate(myspeedHistoryProvider(instance));
      },
      data: (MySpeedStatus status) {
        return EasyRefresh(
          onRefresh: () async {
            ref.invalidate(myspeedStatusProvider(instance));
            ref.invalidate(myspeedHistoryProvider(instance));
            await Future.wait(<Future<dynamic>>[
              ref.read(myspeedStatusProvider(instance).future),
              ref.read(myspeedHistoryProvider(instance).future),
            ]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: Insets.page,
            children: <Widget>[
              _buildStatusCard(context, ref, status),
              const SizedBox(height: Insets.md),
              _buildRunCard(context, ref, status),
              const SizedBox(height: Insets.md),
              _buildLatestResultCard(context, latestTest, historyAsync),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(BuildContext context, WidgetRef ref, MySpeedStatus status) {
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
          width: isRunning ? 1.5 : 1.0,
        ),
      ),
      color: isRunning
          ? accent.withValues(alpha: 0.08)
          : colors.surfaceContainerHighest.withValues(alpha: 0.3),
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
                      Row(
                        children: <Widget>[
                          Text(
                            isRunning ? 'Running' : 'Idle',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isRunning ? accent : colors.onSurface,
                            ),
                          ),
                          const SizedBox(width: Insets.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isRunning
                                  ? accent.withValues(alpha: 0.2)
                                  : colors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isRunning ? accent : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isRunning ? 'ACTIVE' : 'IDLE',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: isRunning ? accent : colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.md),
            Divider(color: colors.outlineVariant.withValues(alpha: 0.3)),
            const SizedBox(height: Insets.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                isRunning
                    ? 'A speedtest is currently executing on your MySpeed instance.'
                    : 'No speedtest is currently running. Server is ready.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            if (status.message != null && status.message!.isNotEmpty) ...<Widget>[
              const SizedBox(height: Insets.xs),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Message: ${status.message}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.outline,
                  ),
                ),
              ),
            ],
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
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      color: colors.surfaceContainerLow,
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
                    isRunning
                        ? 'Speedtest is currently in progress...'
                        : 'Trigger an immediate test run',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: isRunning ? null : () => _runSpeedtest(context, ref),
              icon: isRunning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bolt_rounded),
              label: Text(isRunning ? 'Testing' : 'Run Test'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestResultCard(
    BuildContext context,
    MySpeedTest? latest,
    AsyncValue<List<MySpeedTest>> historyAsync,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      color: colors.surfaceContainerLow,
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
                if (latest?.createdAt != null)
                  Text(
                    latest!.formattedDate,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Insets.lg),
            if (latest != null) ...<Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  _metricTile(
                    context,
                    label: 'DOWNLOAD',
                    value: latest.download.toStringAsFixed(1),
                    unit: 'Mbps',
                    icon: Icons.arrow_downward_rounded,
                    color: Colors.green,
                  ),
                  _metricTile(
                    context,
                    label: 'UPLOAD',
                    value: latest.upload.toStringAsFixed(1),
                    unit: 'Mbps',
                    icon: Icons.arrow_upward_rounded,
                    color: Colors.blue,
                  ),
                  _metricTile(
                    context,
                    label: 'PING',
                    value: latest.ping.toStringAsFixed(0),
                    unit: 'ms',
                    icon: Icons.timer_outlined,
                    color: Colors.orange,
                  ),
                ],
              ),
              if (latest.server != null && latest.server!.isNotEmpty) ...<Widget>[
                const SizedBox(height: Insets.md),
                Divider(color: colors.outlineVariant.withValues(alpha: 0.3)),
                const SizedBox(height: Insets.xs),
                Text(
                  'Server: ${latest.server}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ] else if (historyAsync.isLoading) ...<Widget>[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(Insets.lg),
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else ...<Widget>[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: Insets.lg),
                  child: Text('No completed speedtests in the last 24 hours.'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metricTile(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Column(
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        Text(
          unit,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
