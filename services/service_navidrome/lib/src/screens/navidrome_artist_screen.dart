import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navidrome_api.dart';
import '../navidrome_providers.dart';
import 'navidrome_album_screen.dart';

class NavidromeArtistScreen extends ConsumerWidget {
  const NavidromeArtistScreen({
    required this.instance,
    required this.artistId,
    this.initialArtistName,
    super.key,
  });

  final Instance instance;
  final String artistId;
  final String? initialArtistName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AsyncValue<NavidromeArtistDetail> detailAsync =
        ref.watch(navidromeArtistDetailProvider((instance, artistId)));
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
        data: (NavidromeArtistDetail detail) {
          final NavidromeArtist artist = detail.artist;
          final String cleanArtistId = artist.id.replaceFirst(RegExp(r'^ar-'), '');

          // True artist artwork resolution:
          // 1. High-res Last.fm/Spotify artist banner from getArtistInfo2
          // 2. OpenSubsonic artistImageUrl
          // 3. Server artist artwork ID ar-<artistId>
          // NEVER fall back to 'al-' album covers or compilation album art!
          String? bannerUrl;
          if (detail.info?.largeImageUrl != null &&
              detail.info!.largeImageUrl!.trim().isNotEmpty) {
            bannerUrl = detail.info!.largeImageUrl!.trim();
          } else if (detail.info?.mediumImageUrl != null &&
              detail.info!.mediumImageUrl!.trim().isNotEmpty) {
            bannerUrl = detail.info!.mediumImageUrl!.trim();
          } else if (artist.artistImageUrl != null &&
              artist.artistImageUrl!.trim().isNotEmpty) {
            bannerUrl = artist.artistImageUrl!.trim();
          } else if (artist.coverArt != null &&
              artist.coverArt!.startsWith('ar-')) {
            bannerUrl = client?.getCoverArtUrl(artist.coverArt, size: 1000);
          } else if (cleanArtistId.isNotEmpty) {
            bannerUrl = client?.getCoverArtUrl('ar-$cleanArtistId', size: 1000);
          }

          final double bannerHeight = MediaQuery.sizeOf(context).height * 0.48;

          return CustomScrollView(
            slivers: <Widget>[
              // Top Section: Half-page artist banner with bottom fade
              SliverToBoxAdapter(
                child: SizedBox(
                  height: bannerHeight,
                  child: Stack(
                    children: <Widget>[
                      // 1. Background image or artist placeholder
                      Positioned.fill(
                        child: bannerUrl != null
                            ? AtriumNetworkImage(
                                key: ValueKey<String>(bannerUrl),
                                imageUrl: bannerUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  color: cs.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 72,
                                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                                  ),
                                ),
                              )
                            : Container(
                                color: cs.surfaceContainerHighest,
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 72,
                                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
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
                      // 4. Artist header info at the bottom of the banner
                      Positioned(
                        left: Insets.lg,
                        right: Insets.lg,
                        bottom: Insets.sm,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              artist.name,
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: cs.secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${detail.albums.length} ${detail.albums.length == 1 ? 'Album' : 'Albums'}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: cs.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (detail.info?.biography != null &&
                  detail.info!.biography!.trim().isNotEmpty) ...<Widget>[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Insets.lg,
                    Insets.md,
                    Insets.lg,
                    Insets.xs,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'About',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Insets.lg,
                    0,
                    Insets.lg,
                    Insets.sm,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      detail.info!.biography!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ],
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.lg,
                  Insets.md,
                  Insets.lg,
                  Insets.xs,
                ),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Albums',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (detail.albums.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('No albums found for this artist'),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Insets.lg,
                    0,
                    Insets.lg,
                    Insets.xl,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: Insets.md,
                      mainAxisSpacing: Insets.md,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext ctx, int index) {
                        final NavidromeAlbum album = detail.albums[index];
                        final String? coverUrl = client?.getCoverArtUrl(
                          album.coverArt,
                          size: 300,
                        );

                        return Card(
                          clipBehavior: Clip.antiAlias,
                          elevation: 0,
                          color: cs.surfaceContainerHighest,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => NavidromeAlbumScreen(
                                    instance: instance,
                                    albumId: album.id,
                                    initialAlbum: album,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: coverUrl != null
                                      ? AtriumNetworkImage(
                                          imageUrl: coverUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorWidget: (_, __, ___) =>
                                              Container(
                                            color: cs.surfaceContainerHighest,
                                            child: const Icon(
                                              Icons.album,
                                              size: 36,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: cs.surfaceContainerHighest,
                                          child: const Icon(
                                            Icons.album,
                                            size: 36,
                                          ),
                                        ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(Insets.sm),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        album.name,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (album.year != null)
                                        Text(
                                          '${album.year}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: detail.albums.length,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace st) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: Insets.md),
              Text('Failed to load artist: $e'),
              const SizedBox(height: Insets.md),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(
                  navidromeArtistDetailProvider((instance, artistId)),
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
