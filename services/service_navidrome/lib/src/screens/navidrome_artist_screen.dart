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

    return Scaffold(
      appBar: AppBar(
        title: Text(initialArtistName ?? 'Artist'),
      ),
      body: detailAsync.when(
        data: (NavidromeArtistDetail detail) {
          final NavidromeArtist artist = detail.artist;
          return CustomScrollView(
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.all(Insets.lg),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          artist.name,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ServiceVisuals.accent(ServiceKind.navidrome),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${detail.albums.length} ${detail.albums.length == 1 ? 'Album' : 'Albums'}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
                        final NavidromeClient? client =
                            ref.watch(navidromeClientProvider(instance)).value;
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
