import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navidrome_api.dart';
import '../navidrome_providers.dart';
import 'navidrome_artist_screen.dart';

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

String _formatFileSize(int? bytes) {
  if (bytes == null || bytes <= 0) return '';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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

  void _showSongDetails(BuildContext context, NavidromeSong song) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
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
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.music_note_rounded,
                        color: cs.onPrimaryContainer,
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
                const SizedBox(height: Insets.lg),
                const Divider(),
                _DetailTile(
                  label: 'Duration',
                  value: _formatDuration(song.duration),
                  icon: Icons.schedule_rounded,
                ),
                if (song.track != null)
                  _DetailTile(
                    label: 'Track',
                    value:
                        '${song.track}${song.discNumber != null ? ' (Disc ${song.discNumber})' : ''}',
                    icon: Icons.numbers_rounded,
                  ),
                if (song.suffix != null && song.suffix!.isNotEmpty)
                  _DetailTile(
                    label: 'Format',
                    value:
                        '${song.suffix!.toUpperCase()}${song.bitRate != null ? ' • ${song.bitRate} kbps' : ''}',
                    icon: Icons.audio_file_rounded,
                  ),
                if (song.size != null && song.size! > 0)
                  _DetailTile(
                    label: 'File Size',
                    value: _formatFileSize(song.size),
                    icon: Icons.storage_rounded,
                  ),
                if (song.genre != null && song.genre!.isNotEmpty)
                  _DetailTile(
                    label: 'Genre',
                    value: song.genre!,
                    icon: Icons.category_rounded,
                  ),
                if (song.playCount > 0)
                  _DetailTile(
                    label: 'Play Count',
                    value: '${song.playCount} plays',
                    icon: Icons.play_arrow_rounded,
                  ),
                const SizedBox(height: Insets.sm),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    final AsyncValue<NavidromeAlbumDetail> detailAsync =
        ref.watch(navidromeAlbumDetailProvider((instance, albumId)));
    final AsyncValue<NavidromeClient> clientAsync =
        ref.watch(navidromeClientProvider(instance));

    final NavidromeClient? client = clientAsync.value;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: detailAsync.when(
        data: (NavidromeAlbumDetail detail) {
          final NavidromeAlbum album = detail.album;
          final String? coverUrl =
              client?.getCoverArtUrl(album.coverArt, size: 1000);
          final double bannerHeight = MediaQuery.sizeOf(context).height * 0.48;
          final TextStyle metaStyle = theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
                shadows: const <Shadow>[
                  Shadow(
                    color: Colors.black87,
                    offset: Offset(0, 1),
                    blurRadius: 4,
                  ),
                ],
              ) ??
              const TextStyle(color: Colors.white70);

          return CustomScrollView(
            slivers: <Widget>[
              // Top Section: Half-page album cover banner with bottom fade
              SliverToBoxAdapter(
                child: SizedBox(
                  height: bannerHeight,
                  child: Stack(
                    children: <Widget>[
                      // 1. Background cover image or placeholder
                      Positioned.fill(
                        child: coverUrl != null
                            ? AtriumNetworkImage(
                                key: ValueKey<String>(coverUrl),
                                imageUrl: coverUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  color: cs.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.album_rounded,
                                    size: 72,
                                    color: cs.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              )
                            : Container(
                                color: cs.surfaceContainerHighest,
                                child: Icon(
                                  Icons.album_rounded,
                                  size: 72,
                                  color: cs.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                      ),
                      // 2. Dim overlay for readability
                      Positioned.fill(
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: 0.35),
                        ),
                      ),
                      // 3. Bottom gradient fade into surface
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                cs.surface.withValues(alpha: 0.0),
                                cs.surface.withValues(alpha: 0.2),
                                cs.surface.withValues(alpha: 0.7),
                                cs.surface,
                              ],
                              stops: const <double>[0.3, 0.55, 0.85, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // 4. Album header info at the bottom of the banner
                      Positioned(
                        left: Insets.lg,
                        right: Insets.lg,
                        bottom: Insets.sm,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              album.name,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                shadows: const <Shadow>[
                                  Shadow(
                                    color: Colors.black87,
                                    offset: Offset(0, 1.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: album.artistId != null
                                  ? () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              NavidromeArtistScreen(
                                            instance: instance,
                                            artistId: album.artistId!,
                                            initialArtistName: album.artist,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Flexible(
                                    child: Text(
                                      album.artist,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: cs.primary,
                                        fontWeight: FontWeight.w600,
                                        shadows: const <Shadow>[
                                          Shadow(
                                            color: Colors.black87,
                                            offset: Offset(0, 1),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (album.artistId != null) ...<Widget>[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: cs.primary,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: <Widget>[
                                if (album.year != null) ...<Widget>[
                                  Text(
                                    '${album.year}',
                                    style: metaStyle,
                                  ),
                                  _buildBullet(metaStyle),
                                ],
                                if (album.genre != null &&
                                    album.genre!.isNotEmpty) ...<Widget>[
                                  Text(
                                    album.genre!,
                                    style: metaStyle,
                                  ),
                                  _buildBullet(metaStyle),
                                ],
                                Text(
                                  '${detail.songs.length} ${detail.songs.length == 1 ? 'Track' : 'Tracks'}',
                                  style: metaStyle,
                                ),
                                if (album.duration > 0) ...<Widget>[
                                  _buildBullet(metaStyle),
                                  Text(
                                    _formatDuration(album.duration),
                                    style: metaStyle,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.lg,
                  Insets.md,
                  Insets.lg,
                  Insets.xs,
                ),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Tracks',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (detail.songs.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('No tracks found in this album'),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: Insets.xl),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext ctx, int index) {
                        final NavidromeSong song = detail.songs[index];
                        final String? songCoverArt =
                            song.coverArt ?? album.coverArt;
                        final String? songCoverUrl = client?.getCoverArtUrl(
                          songCoverArt,
                          size: 160,
                        );

                        return ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              SizedBox(
                                width: 24,
                                child: Text(
                                  song.track != null
                                      ? '${song.track}'
                                      : '${index + 1}',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: Insets.xs),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: songCoverUrl != null
                                      ? AtriumNetworkImage(
                                          imageUrl: songCoverUrl,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) =>
                                              Container(
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
                            ],
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
                              if (song.suffix != null &&
                                  song.suffix!.isNotEmpty) ...<Widget>[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    song.suffix!.toUpperCase(),
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(fontSize: 9),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (song.artist != album.artist)
                                Expanded(
                                  child: Text(
                                    song.artist,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                                onPressed: () =>
                                    _showSongDetails(context, song),
                              ),
                            ],
                          ),
                          onTap: () => _showSongDetails(context, song),
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
              Text('Failed to load album: $err'),
              const SizedBox(height: Insets.md),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(
                  navidromeAlbumDetailProvider((instance, albumId)),
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

Widget _buildBullet(TextStyle style) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Text(
      '•',
      style: style.copyWith(
        color: Colors.white.withValues(alpha: 0.5),
      ),
    ),
  );
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: Insets.sm),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
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
      ),
    );
  }
}
