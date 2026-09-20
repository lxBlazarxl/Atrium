import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/myspeed_config.dart';
import '../myspeed_providers.dart';

/// Tab 2: Configuration information.
///
/// Fetches `GET /api/config` and displays settings, cron schedule, and provider info.
class MySpeedConfigTab extends ConsumerStatefulWidget {
  const MySpeedConfigTab({required this.instance, super.key});

  final Instance instance;

  @override
  ConsumerState<MySpeedConfigTab> createState() => _MySpeedConfigTabState();
}

class _MySpeedConfigTabState extends ConsumerState<MySpeedConfigTab> {
  String _filterQuery = '';

  @override
  Widget build(BuildContext context) {
    final AsyncValue<MySpeedConfig> configAsync =
        ref.watch(myspeedConfigProvider(widget.instance));

    return AsyncValueView<MySpeedConfig>(
      value: configAsync,
      onRetry: () => ref.invalidate(myspeedConfigProvider(widget.instance)),
      data: (MySpeedConfig config) {
        final Map<String, dynamic> filteredEntries = <String, dynamic>{
          for (final MapEntry<String, dynamic> entry in config.entries.entries)
            if (_filterQuery.isEmpty ||
                entry.key.toLowerCase().contains(_filterQuery.toLowerCase()) ||
                entry.value.toString().toLowerCase().contains(_filterQuery.toLowerCase()))
              entry.key: entry.value,
        };

        return EasyRefresh(
          onRefresh: () async {
            ref.invalidate(myspeedConfigProvider(widget.instance));
            await ref.read(myspeedConfigProvider(widget.instance).future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: Insets.page,
            children: <Widget>[
              _buildOverviewCard(context, config),
              const SizedBox(height: Insets.md),
              _buildSearchBar(context),
              const SizedBox(height: Insets.sm),
              _buildEntriesCard(context, filteredEntries),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(BuildContext context, MySpeedConfig config) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color accent = ServiceVisuals.accent(widget.instance.kind);

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
            Text(
              'Configuration Overview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Insets.md),
            if (config.cron != null && config.cron!.isNotEmpty) ...<Widget>[
              _overviewRow(
                context,
                icon: Icons.schedule_rounded,
                label: 'Cron Schedule',
                value: config.cron!,
                accent: accent,
              ),
              const SizedBox(height: Insets.sm),
            ],
            if (config.provider != null && config.provider!.isNotEmpty) ...<Widget>[
              _overviewRow(
                context,
                icon: Icons.hub_rounded,
                label: 'Test Provider',
                value: config.provider!,
                accent: accent,
              ),
              const SizedBox(height: Insets.sm),
            ],
            if (config.server != null && config.server!.isNotEmpty) ...<Widget>[
              _overviewRow(
                context,
                icon: Icons.dns_rounded,
                label: 'Server / Node',
                value: config.server!,
                accent: accent,
              ),
              const SizedBox(height: Insets.sm),
            ],
            _overviewRow(
              context,
              icon: Icons.settings_ethernet_rounded,
              label: 'Active Properties',
              value: '${config.entries.length} keys loaded',
              accent: accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _overviewRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: accent),
        const SizedBox(width: Insets.sm),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Filter configuration keys...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: _filterQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => setState(() => _filterQuery = ''),
              )
            : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      onChanged: (String val) => setState(() => _filterQuery = val.trim()),
    );
  }

  Widget _buildEntriesCard(BuildContext context, Map<String, dynamic> entries) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Insets.xl),
        child: Center(
          child: Text(
            'No matching configuration keys.',
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.outline),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      color: colors.surfaceContainerLowest,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: colors.outlineVariant.withValues(alpha: 0.2),
        ),
        itemBuilder: (BuildContext context, int index) {
          final String key = entries.keys.elementAt(index);
          final dynamic value = entries.values.elementAt(index);

          return ListTile(
            title: Text(
              key,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              value.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              tooltip: 'Copy value',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value.toString()));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied "$key" to clipboard'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
