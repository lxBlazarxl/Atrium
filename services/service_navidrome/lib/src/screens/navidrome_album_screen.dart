import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navidrome_api.dart';
import '../navidrome_providers.dart';
import '../widgets/navidrome_rating_bar.dart';
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

String _formatAlbumDuration(int seconds) {
  if (seconds <= 0) return '';
  final int m = seconds ~/ 60;
  if (m >= 60) {
    final int h = m ~/ 60;
    final int remM = m % 60;
    return remM > 0 ? '$h hr $remM min' : '$h hr';
  }
  return '$m min';
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
                                  navidromeAlbumDetailProvider((instance, albumId)),
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
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: <Widget>[
                                if (album.year != null)
                                  _AlbumBadge(
                                    icon: Icons.calendar_today_rounded,
                                    label: '${album.year}',
                                  ),
                                if (album.genre != null &&
                                    album.genre!.isNotEmpty)
                                  _AlbumBadge(
                                    icon: Icons.music_note_rounded,
                                    label: album.genre!,
                                  ),
                                _AlbumBadge(
                                  icon: Icons.queue_music_rounded,
                                  label:
                                      '${detail.songs.length} ${detail.songs.length == 1 ? 'Track' : 'Tracks'}',
                                ),
                                if (album.duration > 0)
                                  _AlbumBadge(
                                    icon: Icons.schedule_rounded,
                                    label: _formatAlbumDuration(album.duration),
                                  ),
                                _AlbumRatingBadge(
                                  rating: album.userRating ?? 0,
                                  onRatingChanged: (int newRating) async {
                                    try {
                                      await client?.setRating(album.id, newRating);
                                      ref.invalidate(
                                        navidromeAlbumDetailProvider(
                                          (instance, albumId),
                                        ),
                                      );
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to set album rating: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: Insets.lg,
                  vertical: Insets.sm,
                ),
                sliver: SliverToBoxAdapter(
                  child: Divider(height: 1),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.lg,
                  Insets.xs,
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

class _AlbumBadge extends StatelessWidget {
  const _AlbumBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 15,
            color: cs.onSecondaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSecondaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
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

class _AlbumRatingBadge extends StatefulWidget {
  const _AlbumRatingBadge({
    required this.rating,
    required this.onRatingChanged,
  });

  final int rating;
  final ValueChanged<int> onRatingChanged;

  @override
  State<_AlbumRatingBadge> createState() => _AlbumRatingBadgeState();
}

class _AlbumRatingBadgeState extends State<_AlbumRatingBadge> {
  late int _rating = widget.rating;

  @override
  void didUpdateWidget(covariant _AlbumRatingBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rating != widget.rating) {
      _rating = widget.rating;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: NavidromeRatingBar(
        rating: _rating,
        starSize: 17,
        activeColor: Colors.amber,
        inactiveColor: cs.onSecondaryContainer.withValues(alpha: 0.35),
        onRatingChanged: (int newRating) {
          setState(() {
            _rating = newRating;
          });
          widget.onRatingChanged(newRating);
        },
      ),
    );
  }
}

