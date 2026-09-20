import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/transmission_detail.dart';
import 'models/transmission_torrent.dart';
import 'transmission_api.dart';
import 'transmission_dialogs.dart';
import 'transmission_files_tree.dart';
import 'transmission_format.dart';
import 'transmission_info_strings.dart';
import 'transmission_providers.dart';
import 'transmission_row_strings.dart';
import 'transmission_torrent_actions.dart';

/// Everything the web UI's inspector shows for one torrent, and every action
/// its context menu offers, from the app bar.
///
/// The live scalars (status, speeds, progress) come from the list provider
/// that is already polling, so opening this screen does not start a second
/// poll of the same data.
class TransmissionDetailScreen extends ConsumerWidget {
  const TransmissionDetailScreen({
    required this.instance,
    required this.hashString,
    required this.initialName,
    super.key,
  });

  final Instance instance;

  /// Infohash, not the numeric id: Transmission reassigns ids when the daemon
  /// restarts, which would otherwise point this screen at another torrent.
  final String hashString;

  /// Shown until the list provider resolves, so the title is never empty.
  final String initialName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TransmissionTorrent? torrent = ref
        .watch(transmissionRawTorrentsProvider(instance))
        .value
        ?.where((TransmissionTorrent t) => t.hashString == hashString)
        .firstOrNull;
    final AsyncValue<TransmissionDetail> detail =
        ref.watch(transmissionDetailProvider((instance, hashString)));
    final bool labels = ref
            .watch(transmissionSessionProvider(instance))
            .value
            ?.supportsLabels ??
        false;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(torrent?.name ?? initialName, maxLines: 1),
          actions: <Widget>[
            if (torrent != null)
              PopupMenuButton<TransmissionTorrentAction>(
                tooltip: 'Torrent actions',
                itemBuilder: (BuildContext _) => transmissionActionMenuItems(
                  anyStopped: torrent.status.isStopped,
                  single: true,
                  labelsSupported: labels,
                ),
                onSelected: (TransmissionTorrentAction a) async {
                  await performTransmissionAction(
                    context,
                    ref,
                    instance,
                    a,
                    <TransmissionTorrent>[torrent],
                  );
                  // A removed torrent has no screen to stay on.
                  final bool removing = a == TransmissionTorrentAction.remove ||
                      a == TransmissionTorrentAction.trash;
                  if (!removing || !context.mounted) return;
                  final List<TransmissionTorrent> now =
                      ref.read(transmissionRawTorrentsProvider(instance)).value ??
                          const <TransmissionTorrent>[];
                  if (!now.any(
                    (TransmissionTorrent t) => t.hashString == hashString,
                  )) {
                    Navigator.of(context).pop();
                  }
                },
              ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: <Widget>[
              Tab(text: 'Info'),
              Tab(text: 'Files'),
              Tab(text: 'Peers'),
              Tab(text: 'Trackers'),
            ],
          ),
        ),
        body: AsyncValueView<TransmissionDetail>(
          value: detail,
          onRetry: () => ref.invalidate(
            transmissionDetailProvider((instance, hashString)),
          ),
          data: (TransmissionDetail d) => TabBarView(
            children: <Widget>[
              _InfoTab(torrent: torrent, detail: d, labelsSupported: labels),
              _FilesTab(instance: instance, hashString: hashString, detail: d),
              _PeersTab(detail: d),
              _TrackersTab(detail: d),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({
    required this.torrent,
    required this.detail,
    required this.labelsSupported,
  });

  final TransmissionTorrent? torrent;
  final TransmissionDetail detail;
  final bool labelsSupported;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final TransmissionTorrent? t = torrent;
    final TransmissionDetail d = detail;
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    Widget header(String title) => Padding(
          padding: const EdgeInsets.only(top: Insets.md, bottom: Insets.xs),
          child: Text(
            title,
            style: text.titleSmall?.copyWith(color: scheme.primary),
          ),
        );
    final bool commentIsLink =
        d.comment.startsWith('http://') || d.comment.startsWith('https://');
    return ListView(
      padding: Insets.page,
      children: <Widget>[
        if (t != null) ...<Widget>[
          LinearProgressIndicatorM3E(
            value: trBarValue(t),
            shape: (t.downloadRate > 0 || t.uploadRate > 0)
                ? ProgressM3EShape.wavy
                : ProgressM3EShape.flat,
            activeColor: trStatusColor(scheme, t),
            trackColor: scheme.surfaceContainerHighest,
          ),
          header('Activity'),
          _KeyValue('Have', trHaveLine(t, d)),
          _KeyValue('Availability', trAvailability(t, d)),
          _KeyValue('Uploaded', trUploadedLine(t, d)),
          _KeyValue('Downloaded', trDownloadedLine(d)),
          _KeyValue('State', t.stateString),
          _KeyValue('Running time', trRunningTime(t, d, now: now)),
          _KeyValue('Remaining', trRemaining(t)),
          _KeyValue('Last activity', trLastActivity(t, now: now)),
          if (t.errorString.isNotEmpty) _KeyValue('Error', t.errorString),
          header('Details'),
          _KeyValue('Size', trSizeLine(t, d)),
          _KeyValue('Location', t.downloadDir),
          _KeyValue('Hash', t.hashString),
          _KeyValue('Privacy', trPrivacy(d)),
          _KeyValue('Origin', trOrigin(d)),
          if (t.addedDate > 0)
            _KeyValue('Date added', trTimestamp(t.addedDate)),
          _KeyValue(
            'Comment',
            d.comment.isEmpty ? 'None' : d.comment,
            onTap: commentIsLink
                ? () => launchUrl(
                      Uri.parse(d.comment),
                      mode: LaunchMode.externalApplication,
                    )
                : null,
          ),
          if (labelsSupported)
            _KeyValue(
              'Labels',
              t.labels.isEmpty ? 'None' : t.labels.join(', '),
            ),
          _KeyValue(
            'Magnet link',
            d.magnetLink.isEmpty ? 'None' : d.magnetLink,
            trailing: d.magnetLink.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Copy magnet link',
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: d.magnetLink),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Magnet link copied')),
                        );
                      }
                    },
                  ),
          ),
        ],
      ],
    );
  }
}

class _FilesTab extends ConsumerStatefulWidget {
  const _FilesTab({
    required this.instance,
    required this.hashString,
    required this.detail,
  });

  final Instance instance;
  final String hashString;
  final TransmissionDetail detail;

  @override
  ConsumerState<_FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends ConsumerState<_FilesTab> {
  bool _busy = false;

  Future<void> _write(Future<void> Function(TransmissionApi api) action) async {
    setState(() => _busy = true);
    await runTransmissionAction(context, ref, widget.instance, action);
    ref.invalidate(
      transmissionDetailProvider((widget.instance, widget.hashString)),
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final List<TransmissionFile> files = widget.detail.files;
    if (files.isEmpty) {
      return const EmptyView(
        icon: Icons.insert_drive_file_outlined,
        title: 'No files',
        message: 'Transmission has no file list for this torrent yet.',
      );
    }
    final List<int> all = <int>[for (int i = 0; i < files.length; i++) i];
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            const SizedBox(width: Insets.sm),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _write(
                        (TransmissionApi api) => api.setFileWanted(
                          widget.hashString,
                          all,
                          wanted: true,
                        ),
                      ),
              child: const Text('Select all'),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _write(
                        (TransmissionApi api) => api.setFileWanted(
                          widget.hashString,
                          all,
                          wanted: false,
                        ),
                      ),
              child: const Text('Select none'),
            ),
          ],
        ),
        Expanded(
          child: TransmissionFilesTree(
            root: buildTransmissionFileTree(files),
            busy: _busy,
            onWanted: (List<int> indices, bool wanted) => _write(
              (TransmissionApi api) => api.setFileWanted(
                widget.hashString,
                indices,
                wanted: wanted,
              ),
            ),
            onPriority: (List<int> indices, TransmissionPriority p) => _write(
              (TransmissionApi api) =>
                  api.setFilePriority(widget.hashString, indices, p),
            ),
          ),
        ),
      ],
    );
  }
}

class _PeersTab extends StatelessWidget {
  const _PeersTab({required this.detail});

  final TransmissionDetail detail;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return ListView(
      padding: Insets.page,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('Peers (${detail.peers.length})', style: text.titleSmall),
            const Spacer(),
            IconButton(
              tooltip: 'Peer flags',
              icon: const Icon(Icons.help_outline),
              onPressed: () => showTransmissionPeerFlagsSheet(context),
            ),
          ],
        ),
        if (detail.peers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Insets.lg),
            child: Text('Nothing is connected right now.'),
          ),
        for (final TransmissionPeer p in detail.peers)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              p.isEncrypted ? Icons.lock_outline : Icons.lock_open_outlined,
            ),
            title: Text('${p.address}:${p.port}'),
            subtitle: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${p.clientName.isEmpty ? 'Unknown client' : p.clientName}'
                    ' - ${trPct(p.progress)}%',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  p.flagStr,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ],
            ),
            trailing: Text(
              '↓ ${trFmtRate(p.rateToClient)}\n↑ ${trFmtRate(p.rateToPeer)}',
              textAlign: TextAlign.right,
              style: text.bodySmall,
            ),
          ),
        if (detail.webseeds.isNotEmpty) ...<Widget>[
          const SizedBox(height: Insets.md),
          Text('Web seeds', style: text.titleSmall),
          for (final String url in detail.webseeds)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.public),
              title: Text(url, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
        ],
      ],
    );
  }
}

class _TrackersTab extends StatelessWidget {
  const _TrackersTab({required this.detail});

  final TransmissionDetail detail;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    if (detail.trackers.isEmpty) {
      return const EmptyView(
        icon: Icons.dns_outlined,
        title: 'No trackers',
        message: 'This torrent announces to no trackers.',
      );
    }
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final List<Widget> rows = <Widget>[];
    int? tier;
    for (final TransmissionTracker tr in detail.trackers) {
      if (tr.tier != tier) {
        tier = tr.tier;
        rows.add(
          Padding(
            padding: const EdgeInsets.only(top: Insets.md, bottom: Insets.xs),
            // Transmission counts tiers from zero; the web UI shows them
            // from one.
            child: Text(
              'Tier ${tier + 1}',
              style: text.titleSmall?.copyWith(color: scheme.primary),
            ),
          ),
        );
      }
      final (String announceLabel, String announceValue) = trLastAnnounce(tr);
      final (String scrapeLabel, String scrapeValue) = trLastScrape(tr);
      rows.add(
        Card(
          margin: const EdgeInsets.only(bottom: Insets.sm),
          child: Padding(
            padding: const EdgeInsets.all(Insets.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  tr.sitename.isNotEmpty
                      ? tr.sitename
                      : (tr.host.isEmpty ? tr.announce : tr.host),
                  style: text.titleSmall,
                ),
                Text(
                  tr.announce,
                  style:
                      text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: Insets.xs),
                Text(trAnnounceState(tr, now: now)),
                Text('$announceLabel: $announceValue'),
                Text('$scrapeLabel: $scrapeValue'),
                Text(
                  'Seeders ${trFmtPeerCount(tr.seederCount)}, '
                  'leechers ${trFmtPeerCount(tr.leecherCount)}, '
                  'downloads ${trFmtPeerCount(tr.downloadCount)}',
                ),
              ],
            ),
          ),
        ),
      );
    }
    return ListView(padding: Insets.page, children: rows);
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue(this.label, this.value, {this.onTap, this.trailing});

  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Text(
                value,
                style: onTap == null
                    ? null
                    : TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
