import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';

import 'models/transmission_torrent.dart';
import 'transmission_format.dart';
import 'transmission_row_strings.dart';
import 'transmission_torrent_actions.dart';

/// One torrent in the list, full or compact, selectable.
class TransmissionTorrentRow extends StatelessWidget {
  const TransmissionTorrentRow({
    required this.torrent,
    required this.compact,
    required this.selected,
    required this.selectionMode,
    required this.labelsSupported,
    required this.onTap,
    required this.onLongPress,
    required this.onAction,
    super.key,
  });

  final TransmissionTorrent torrent;
  final bool compact;
  final bool selected;
  final bool selectionMode;
  final bool labelsSupported;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final void Function(TransmissionTorrentAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final Color color = trStatusColor(scheme, torrent);
    final bool moving = torrent.downloadRate > 0 || torrent.uploadRate > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: Insets.sm),
      color: selected ? scheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: Radii.card,
        child: Padding(
          padding: EdgeInsets.all(compact ? Insets.sm : Insets.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    selectionMode
                        ? (selected
                            ? Icons.check_circle
                            : Icons.circle_outlined)
                        : trStatusIcon(torrent),
                    size: 18,
                    color: selectionMode ? scheme.primary : color,
                  ),
                  const SizedBox(width: Insets.sm),
                  Expanded(
                    child: Text(
                      torrent.name,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (!selectionMode)
                    PopupMenuButton<TransmissionTorrentAction>(
                      tooltip: 'Torrent actions',
                      itemBuilder: (BuildContext _) =>
                          transmissionActionMenuItems(
                        anyStopped: torrent.status.isStopped,
                        single: true,
                        labelsSupported: labelsSupported,
                      ),
                      onSelected: onAction,
                    ),
                ],
              ),
              if (!compact &&
                  labelsSupported &&
                  torrent.labels.isNotEmpty) ...<Widget>[
                const SizedBox(height: Insets.xs),
                Wrap(
                  spacing: Insets.xs,
                  runSpacing: Insets.xs,
                  children: <Widget>[
                    for (final String label in torrent.labels)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(label, style: text.labelSmall),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: Insets.sm),
              LinearProgressIndicatorM3E(
                value: trBarValue(torrent),
                // The expressive wave reads as "moving right now", so it is
                // spent only on torrents actually shifting bytes.
                shape: moving ? ProgressM3EShape.wavy : ProgressM3EShape.flat,
                size: LinearProgressM3ESize.s,
                activeColor: color,
                trackColor: scheme.surfaceContainerHighest,
              ),
              const SizedBox(height: Insets.xs),
              if (compact)
                Text(
                  trCompactLine(torrent),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: torrent.hasError
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                  ),
                )
              else ...<Widget>[
                Text(
                  trProgressLine(torrent),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: Insets.xxs),
                Text(
                  trStatusLine(torrent),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: torrent.hasError ? scheme.error : color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
