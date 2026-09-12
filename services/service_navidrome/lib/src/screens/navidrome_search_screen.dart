import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navidrome_api.dart';
import '../navidrome_providers.dart';
import 'navidrome_album_screen.dart';
import 'navidrome_artist_screen.dart';

String _formatDuration(int seconds) {
  if (seconds <= 0) return '0:00';
  final int m = seconds ~/ 60;
  final int s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

class NavidromeSearchScreen extends ConsumerStatefulWidget {
  const NavidromeSearchScreen({required this.instance, super.key});

  final Instance instance;

  @override
  ConsumerState<NavidromeSearchScreen> createState() =>
      _NavidromeSearchScreenState();
}

class _NavidromeSearchScreenState extends ConsumerState<NavidromeSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _query = val.trim();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    final AsyncValue<NavidromeClient> clientAsync =
        ref.watch(navidromeClientProvider(widget.instance));
    final NavidromeClient? client = clientAsync.value;

    final AsyncValue<NavidromeSearchResult> resultsAsync = _query.isNotEmpty
        ? ref.watch(navidromeSearchProvider((widget.instance, _query)))
        : const AsyncValue<NavidromeSearchResult>.data(
            NavidromeSearchResult(),
          );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onQueryChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search artists, albums, songs...',
            border: InputBorder.none,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
        actions: <Widget>[
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _controller.clear();
                _onQueryChanged('');
              },
            ),
        ],
      ),
      body: _query.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.search_rounded,
                    size: 64,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: Insets.md),
                  Text(
                    'Search Navidrome library',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : resultsAsync.when(
              data: (NavidromeSearchResult result) {
                if (result.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.music_off_rounded,
                          size: 64,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: Insets.md),
                        Text(
                          'No matches found for "$_query"',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: Insets.md),
                  children: <Widget>[
                    if (result.artists.isNotEmpty) ...<Widget>[
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: Insets.lg),
                        child: Text(
                          'Artists',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: Insets.sm),
                      SizedBox(
                        height: 104,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding:
                              const EdgeInsets.symmetric(horizontal: Insets.lg),
                          itemCount: result.artists.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: Insets.md),
                          itemBuilder: (BuildContext ctx, int index) {
                            final NavidromeArtist artist =
                                result.artists[index];
                            final String cleanId = artist.id.startsWith('ar-')
                                ? artist.id.substring(3)
                                : artist.id;
                            final String artistArtId =
                                (artist.coverArt != null &&
                                        artist.coverArt!.startsWith('ar-'))
                                    ? artist.coverArt!
                                    : 'ar-$cleanId';
                            final String? coverUrl =
                                (artist.artistImageUrl != null &&
                                        artist.artistImageUrl!.isNotEmpty)
                                    ? artist.artistImageUrl
                                    : client?.getCoverArtUrl(
                                        artistArtId,
                                        size: 200,
                                      );

                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => NavidromeArtistScreen(
                                      instance: widget.instance,
                                      artistId: artist.id,
                                      initialArtistName: artist.name,
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: cs.primaryContainer,
                                    child: coverUrl != null
                                        ? ClipOval(
                                            child: AtriumNetworkImage(
                                              imageUrl: coverUrl,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) => Icon(
                                                Icons.person_rounded,
                                                size: 30,
                                                color: cs.onPrimaryContainer,
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.person_rounded,
                                            size: 30,
                                            color: cs.onPrimaryContainer,
                                          ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      artist.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: Insets.lg),
                    ],
                    if (result.albums.isNotEmpty) ...<Widget>[
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: Insets.lg),
                        child: Text(
                          'Albums',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: Insets.sm),
                      SizedBox(
                        height: 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding:
                              const EdgeInsets.symmetric(horizontal: Insets.lg),
                          itemCount: result.albums.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: Insets.md),
                          itemBuilder: (BuildContext ctx, int index) {
                            final NavidromeAlbum album = result.albums[index];
                            final String? coverUrl = client
                                ?.getCoverArtUrl(album.coverArt, size: 250);

                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => NavidromeAlbumScreen(
                                      instance: widget.instance,
                                      albumId: album.id,
                                      initialAlbum: album,
                                    ),
                                  ),
                                );
                              },
                              child: SizedBox(
                                width: 120,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    AspectRatio(
                                      aspectRatio: 1.0,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: coverUrl != null
                                            ? AtriumNetworkImage(
                                                imageUrl: coverUrl,
                                                fit: BoxFit.cover,
                                                errorWidget: (_, __, ___) =>
                                                    Container(
                                                  color: cs
                                                      .surfaceContainerHighest,
                                                  child: const Icon(
                                                    Icons.album_rounded,
                                                    size: 32,
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                color:
                                                    cs.surfaceContainerHighest,
                                                child: const Icon(
                                                  Icons.album_rounded,
                                                  size: 32,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      album.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      album.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: Insets.lg),
                    ],
                    if (result.songs.isNotEmpty) ...<Widget>[
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: Insets.lg),
                        child: Text(
                          'Tracks',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: Insets.xs),
                      ...result.songs.map((NavidromeSong song) {
                        final String? trackCover =
                            client?.getCoverArtUrl(song.coverArt, size: 100);

                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: trackCover != null
                                  ? AtriumNetworkImage(
                                      imageUrl: trackCover,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(
                                        color: cs.surfaceContainerHighest,
                                        child: const Icon(
                                          Icons.music_note,
                                          size: 20,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: cs.surfaceContainerHighest,
                                      child: const Icon(
                                        Icons.music_note,
                                        size: 20,
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
                          subtitle: Text(
                            '${song.artist} • ${song.album}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          trailing: Text(
                            _formatDuration(song.duration),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          onTap: song.albumId != null
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => NavidromeAlbumScreen(
                                        instance: widget.instance,
                                        albumId: song.albumId!,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                        );
                      }),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object err, _) => Center(
                child: Text('Search failed: $err'),
              ),
            ),
    );
  }
}
