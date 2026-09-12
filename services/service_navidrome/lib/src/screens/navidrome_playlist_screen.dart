import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navidrome_api.dart';
import '../navidrome_providers.dart';
import '../widgets/navidrome_rating_bar.dart';

String _formatDuration(int seconds) {
  if (seconds <= 0) return '0:00';
  final int m = seconds ~/ 60;
  final int s = seconds % 60;
  if (m >= 60) {
    final int h = m ~/ 60;
    final int remM = m % 60;
    return '$h:${remM.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}

class NavidromePlaylistScreen extends ConsumerWidget {
  const NavidromePlaylistScreen({
    required this.instance,
    required this.playlistId,
    this.initialName,
    super.key,
  });

  final Instance instance;
  final String playlistId;
  final String? initialName;

  void _showSongDetails(
    BuildContext context,
    WidgetRef ref,
    NavidromeSong song, {
    String? coverUrl,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    int currentRating = song.userRating ?? 0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.lg,
                  vertical: Insets.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: Insets.md),
                    Row(
                      children: <Widget>[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 48,
                            height: 48,
                            color: cs.primaryContainer,
                            child: coverUrl != null
                                ? AtriumNetworkImage(
                                    imageUrl: coverUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Icon(
                                      Icons.music_note_rounded,
                                      color: cs.onPrimaryContainer,
                                    ),
                                  )
                                : Icon(
                                    Icons.music_note_rounded,
                                    color: cs.onPrimaryContainer,
                                  ),
                          ),
                        ),
                        const SizedBox(width: Insets.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                song.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                song.artist,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Insets.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Insets.md,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(
                                'Rating',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (currentRating > 0) ...<Widget>[
                                const SizedBox(width: 8),
                                Text(
                                  '$currentRating / 5',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: Colors.amber[800] ?? Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          NavidromeRatingBar(
                            rating: currentRating,
                            starSize: 24,
                            spacing: 4,
                            onRatingChanged: (int newRating) async {
                              setModalState(() {
                                currentRating = newRating;
                              });
                              final NavidromeClient? client =
                                  ref.read(navidromeClientProvider(instance)).value;
                              try {
                                await client?.setRating(song.id, newRating);
                                ref.invalidate(
                                  navidromePlaylistDetailProvider(
                                    (instance, playlistId),
                                  ),
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to set rating: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Insets.md),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.schedule_rounded,
                            size: 18,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: Insets.sm),
                          Text(
                            'Duration',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDuration(song.duration),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Insets.sm),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    final AsyncValue<NavidromePlaylistDetail> detailAsync =
        ref.watch(navidromePlaylistDetailProvider((instance, playlistId)));
    final AsyncValue<NavidromeClient> clientAsync =
        ref.watch(navidromeClientProvider(instance));
    final NavidromeClient? client = clientAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(initialName ?? 'Playlist'),
      ),
      body: detailAsync.when(
        data: (NavidromePlaylistDetail detail) {
          final NavidromePlaylist pl = detail.playlist;
          final String? coverUrl =
              client?.getCoverArtUrl(pl.coverArt, size: 300);

          return CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(Insets.lg),
                  child: Row(
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 80,
                          height: 80,
                          color: cs.primaryContainer,
                          child: coverUrl != null
                              ? AtriumNetworkImage(
                                  imageUrl: coverUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Icon(
                                    Icons.queue_music_rounded,
                                    size: 40,
                                    color: cs.onPrimaryContainer,
                                  ),
                                )
                              : Icon(
                                  Icons.queue_music_rounded,
                                  size: 40,
                                  color: cs.onPrimaryContainer,
                                ),
                        ),
                      ),
                      const SizedBox(width: Insets.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              pl.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (pl.comment != null &&
                                pl.comment!.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 2),
                              Text(
                                pl.comment!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '${detail.songs.length} tracks • ${_formatDuration(pl.duration)}',
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
              const SliverToBoxAdapter(child: Divider()),
              if (detail.songs.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text('This playlist has no songs'),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext ctx, int index) {
                      final NavidromeSong song = detail.songs[index];
                      final String? songCoverUrl = client?.getCoverArtUrl(
                        song.coverArt,
                        size: 160,
                      );

                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: songCoverUrl != null
                                ? AtriumNetworkImage(
                                    imageUrl: songCoverUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      color: cs.surfaceContainerHighest,
                                      child: const Icon(
                                        Icons.music_note_rounded,
                                        size: 22,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: cs.surfaceContainerHighest,
                                    child: const Icon(
                                      Icons.music_note_rounded,
                                      size: 22,
                                    ),
                                  ),
                          ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Row(
                          children: <Widget>[
                            if (song.userRating != null &&
                                song.userRating! > 0) ...<Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 11,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${song.userRating}',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Colors.amber[800] ?? Colors.amber,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              _formatDuration(song.duration),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                              ),
                              onPressed: () => _showSongDetails(
                                context,
                                ref,
                                song,
                                coverUrl: songCoverUrl,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _showSongDetails(
                          context,
                          ref,
                          song,
                          coverUrl: songCoverUrl,
                        ),
                      );
                    },
                    childCount: detail.songs.length,
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: Insets.md),
              Text('Failed to load playlist: $err'),
              const SizedBox(height: Insets.md),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(
                  navidromePlaylistDetailProvider((instance, playlistId)),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
