import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'navidrome_api.dart';
import 'navidrome_providers.dart';

/// Main home screen for Navidrome music server instances.
class NavidromeHome extends ConsumerWidget {
  const NavidromeHome({required this.instance, super.key});

  final Instance instance;

  Future<void> _launchWeb(BuildContext context) async {
    final String url =
        instance.localUrl.isNotEmpty ? instance.localUrl : instance.externalUrl;
    if (url.isEmpty) return;
    final Uri? uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Color accent = ServiceVisuals.accent(ServiceKind.navidrome);

    final AsyncValue<NavidromeServerInfo> infoAsync =
        ref.watch(navidromeServerInfoProvider(instance));
    final AsyncValue<NavidromeScanStatus> scanAsync =
        ref.watch(navidromeScanStatusProvider(instance));

    return EasyRefresh(
      header: const ClassicHeader(
        dragText: 'Pull to refresh',
        armedText: 'Release ready',
        readyText: 'Refreshing...',
        processingText: 'Refreshing...',
        processedText: 'Succeeded',
        failedText: 'Failed',
        messageText: 'Last updated at %T',
      ),
      onRefresh: () async {
        ref.invalidate(navidromeServerInfoProvider(instance));
        ref.invalidate(navidromeScanStatusProvider(instance));
      },
      child: ListView(
        padding: Insets.page,
        children: <Widget>[
          // Hero banner card
          _HeroCard(
            instance: instance,
            accent: accent,
            infoAsync: infoAsync,
            onOpenWeb: () => _launchWeb(context),
          ),
          const SizedBox(height: Insets.md),

          // Library & Server stats
          Text(
            'Server Overview',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Insets.sm),

          Row(
            children: <Widget>[
              Expanded(
                child: _StatCard(
                  title: 'Subsonic API',
                  value: infoAsync.maybeWhen(
                    data: (info) => 'v${info.subsonicVersion}',
                    orElse: () => 'v1.16.1',
                  ),
                  subtitle: infoAsync.maybeWhen(
                    data: (info) => info.serverVersion.isNotEmpty
                        ? 'Navidrome ${info.serverVersion}'
                        : 'Connected',
                    orElse: () => 'Subsonic compatible',
                  ),
                  icon: Icons.api_rounded,
                  accent: accent,
                ),
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: _StatCard(
                  title: 'Library Scan',
                  value: scanAsync.maybeWhen(
                    data: (scan) =>
                        scan.scanning ? 'Scanning...' : '${scan.count} items',
                    orElse: () => 'Ready',
                  ),
                  subtitle: scanAsync.maybeWhen(
                    data: (scan) =>
                        scan.scanning ? 'Updating database' : 'Up to date',
                    orElse: () => 'Subsonic scanner',
                  ),
                  icon: Icons.sync_rounded,
                  accent: cs.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),

          // Connection info card
          Card(
            elevation: 0,
            color: cs.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Insets.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.link_rounded, size: 20, color: cs.primary),
                      const SizedBox(width: Insets.xs),
                      Text(
                        'Connection Details',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Insets.sm),
                  _InfoRow(
                    label: 'Endpoint',
                    value: instance.localUrl.isNotEmpty
                        ? instance.localUrl
                        : (instance.externalUrl.isNotEmpty
                            ? instance.externalUrl
                            : 'Not configured'),
                  ),
                  const SizedBox(height: Insets.xs),
                  _InfoRow(
                    label: 'Auth mode',
                    value: switch (instance.auth) {
                      InstanceAuthUserPass(:final String username) =>
                        username.isNotEmpty
                            ? 'User: $username'
                            : 'Username & password',
                      _ => 'Credentials',
                    },
                  ),
                  const SizedBox(height: Insets.xs),
                  _InfoRow(
                    label: 'Status',
                    value: infoAsync.maybeWhen(
                      data: (info) => 'Online (${info.status})',
                      error: (_, __) => 'Connection error',
                      loading: () => 'Connecting...',
                      orElse: () => 'Ready',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Insets.md),

          // Future player card
          Card(
            elevation: 0,
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Insets.md),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.headphones_rounded,
                      color: accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: Insets.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Music Player & Library Browser',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Native music streaming, albums, and playlists are coming in an upcoming release.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.instance,
    required this.accent,
    required this.infoAsync,
    required this.onOpenWeb,
  });

  final Instance instance;
  final Color accent;
  final AsyncValue<NavidromeServerInfo> infoAsync;
  final VoidCallback onOpenWeb;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accent.withValues(alpha: 0.22),
            accent.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
        ),
      ),
      padding: const EdgeInsets.all(Insets.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.queue_music_rounded,
                  color: accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      instance.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Navidrome Music Server',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              infoAsync.maybeWhen(
                data: (info) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Insets.sm,
                    vertical: Insets.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: Colors.green,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          FilledButton.tonalIcon(
            onPressed: onOpenWeb,
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('Open Web Player'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: Insets.xs),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.xs),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
