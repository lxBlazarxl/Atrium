import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/myspeed_test.dart';
import '../myspeed_providers.dart';
import '../widgets/myspeed_test_card.dart';

class MySpeedHistoryTab extends ConsumerWidget {
  const MySpeedHistoryTab({required this.instance, super.key});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<MySpeedTest>> historyAsync =
        ref.watch(myspeedHistoryProvider(instance));

    return AsyncValueView<List<MySpeedTest>>(
      value: historyAsync,
      onRetry: () => ref.read(myspeedHistoryProvider(instance).notifier).reload(),
      data: (List<MySpeedTest> tests) {
        return EasyRefresh(
          onRefresh: () async {
            await ref.read(myspeedHistoryProvider(instance).notifier).reload();
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: Insets.page,
            itemCount: tests.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                final ThemeData theme = Theme.of(context);
                final ColorScheme colors = theme.colorScheme;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildSummaryCard(context, tests),
                    const SizedBox(height: Insets.lg),
                    Divider(color: colors.outlineVariant.withValues(alpha: 0.4)),
                    const SizedBox(height: Insets.md),
                  ],
                );
              }
              final MySpeedTest test = tests[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: Insets.sm),
                child: MySpeedTestCard(test: test),
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
                  'Historical Summary',
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
            const SizedBox(height: Insets.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: MySpeedMetricBox(
                    icon: Icons.arrow_downward_rounded,
                    label: 'AVG DOWN',
                    value: avgDown.toStringAsFixed(1),
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
                    label: 'AVG UP',
                    value: avgUp.toStringAsFixed(1),
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
                    label: 'AVG PING',
                    value: avgPing.toStringAsFixed(0),
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
}
