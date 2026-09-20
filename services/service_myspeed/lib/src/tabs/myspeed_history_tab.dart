import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/myspeed_test.dart';
import '../myspeed_providers.dart';

/// Tab 1: Historical speedtests in the last 24 hours.
///
/// Fetches `GET /api/speedtests?hours=24`, displaying summary averages and a list
/// of speedtest cards.
class MySpeedHistoryTab extends ConsumerWidget {
  const MySpeedHistoryTab({required this.instance, super.key});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MySpeedTest>> historyAsync =
        ref.watch(myspeedHistoryProvider(instance));

    return AsyncValueView<List<MySpeedTest>>(
      value: historyAsync,
      onRetry: () => ref.invalidate(myspeedHistoryProvider(instance)),
      data: (List<MySpeedTest> tests) {
        return EasyRefresh(
          onRefresh: () async {
            ref.invalidate(myspeedHistoryProvider(instance));
            await ref.read(myspeedHistoryProvider(instance).future);
          },
          child: tests.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: Insets.page,
                  children: const <Widget>[
                    SizedBox(height: 60),
                    EmptyView(
                      icon: Icons.history_rounded,
                      title: 'No Speedtests',
                      message: 'No speedtests recorded in the past 24 hours.',
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: Insets.page,
                  itemCount: tests.length + 1,
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Insets.md),
                        child: _buildSummaryCard(context, tests),
                      );
                    }
                    final MySpeedTest test = tests[index - 1];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: Insets.sm),
                      child: _buildTestCard(context, test),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<MySpeedTest> tests) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color accent = ServiceVisuals.accent(instance.kind);

    double sumDown = 0;
    double sumUp = 0;
    double sumPing = 0;
    for (final MySpeedTest t in tests) {
      sumDown += t.download;
      sumUp += t.upload;
      sumPing += t.ping;
    }
    final double avgDown = tests.isNotEmpty ? sumDown / tests.length : 0;
    final double avgUp = tests.isNotEmpty ? sumUp / tests.length : 0;
    final double avgPing = tests.isNotEmpty ? sumPing / tests.length : 0;

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
                  '24-Hour Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tests.length} tests',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _summaryStat(
                  context,
                  label: 'Avg Down',
                  value: '${avgDown.toStringAsFixed(1)} Mbps',
                  icon: Icons.arrow_downward_rounded,
                  color: Colors.green,
                ),
                _summaryStat(
                  context,
                  label: 'Avg Up',
                  value: '${avgUp.toStringAsFixed(1)} Mbps',
                  icon: Icons.arrow_upward_rounded,
                  color: Colors.blue,
                ),
                _summaryStat(
                  context,
                  label: 'Avg Ping',
                  value: '${avgPing.toStringAsFixed(0)} ms',
                  icon: Icons.timer_outlined,
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryStat(
    BuildContext context, {
    required String label,
    required String value,
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
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTestCard(BuildContext context, MySpeedTest test) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      color: colors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(Insets.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.access_time_rounded, size: 14, color: colors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      test.formattedDate.isNotEmpty ? test.formattedDate : 'Recent Test',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
                if (test.server != null && test.server!.isNotEmpty)
                  Flexible(
                    child: Text(
                      test.server!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Insets.sm),
            Divider(color: colors.outlineVariant.withValues(alpha: 0.2)),
            const SizedBox(height: Insets.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _metricPill(
                  context,
                  icon: Icons.arrow_downward_rounded,
                  label: 'Down',
                  value: test.formattedDownload,
                  color: Colors.green,
                ),
                _metricPill(
                  context,
                  icon: Icons.arrow_upward_rounded,
                  label: 'Up',
                  value: test.formattedUpload,
                  color: Colors.blue,
                ),
                _metricPill(
                  context,
                  icon: Icons.timer_outlined,
                  label: 'Ping',
                  value: test.formattedPing,
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final ThemeData theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
