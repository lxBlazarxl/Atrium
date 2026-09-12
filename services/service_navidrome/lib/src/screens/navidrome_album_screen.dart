import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navidrome_api.dart';
import '../navidrome_providers.dart';

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

class NavidromeAlbumScreen extends ConsumerWidget {
  const NavidromeAlbumScreen({
    required this.instance,
    required this.albumId,
    this.initialAlbum,
    super.key,
  });

  final Instance instance;
  final String albumId;
  final NavidromeAlbum? initialAlbum;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AsyncValue<NavidromeAlbumDetail> detailAsync =
        ref.watch(navidromeAlbumDetailProvider((instance, albumId)));

    return Scaffold(
      appBar: AppBar(
        title: Text(initialAlbum?.name ?? 'Album'),
      ),
      body: detailAsync.when(
        data: (NavidromeAlbumDetail detail) {
          final NavidromeAlbum album = detail.album;
          return CustomScrollView(
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.all(Insets.lg),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        album.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        album.artist,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${detail.songs.length} Tracks • ${_formatDuration(album.duration)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext ctx, int index) {
                      final NavidromeSong song = detail.songs[index];
                      return ListTile(
                        title: Text(song.title),
                        subtitle: Text(song.artist),
                        trailing: Text(_formatDuration(song.duration)),
                      );
                    },
                    childCount: detail.songs.length,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace st) => Center(
          child: Text('Failed to load album: $e'),
        ),
      ),
    );
  }
}
