import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navidrome_api.dart';
import '../navidrome_providers.dart';
import '../screens/navidrome_artist_screen.dart';

/// Modern Artists tab featuring alphabetical section headers with gradient badges,
/// M3 metadata pills, and seamless List / Grid view toggling.
class NavidromeArtistsTab extends ConsumerStatefulWidget {
  const NavidromeArtistsTab({
    required this.instance,
    super.key,
  });

  final Instance instance;

  @override
  ConsumerState<NavidromeArtistsTab> createState() =>
      _NavidromeArtistsTabState();
}

class _NavidromeArtistsTabState extends ConsumerState<NavidromeArtistsTab> {
  final ScrollController _scrollController = ScrollController();
  bool _isGridView = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final NavidromeClient? client =
        ref.watch(navidromeClientProvider(widget.instance)).value;
    final AsyncValue<List<NavidromeArtistIndex>> artistsAsync =
        ref.watch(navidromeArtistsProvider(widget.instance));

    return EasyRefresh(
      onRefresh: () async {
        ref.invalidate(navidromeArtistsProvider(widget.instance));
      },
      child: artistsAsync.when(
        data: (List<NavidromeArtistIndex> indexes) {
          final List<NavidromeArtistIndex> nonEmptyGroups =
              indexes.where((NavidromeArtistIndex g) => g.artists.isNotEmpty).toList();

          if (nonEmptyGroups.isEmpty) {
            return const Center(child: Text('No artists found'));
          }

          final int totalArtists = nonEmptyGroups.fold<int>(
            0,
            (int sum, NavidromeArtistIndex g) => sum + g.artists.length,
          );
          final int totalAlbums = nonEmptyGroups.fold<int>(
            0,
            (int sum, NavidromeArtistIndex g) =>
                sum +
                g.artists.fold<int>(
                  0,
                  (int aSum, NavidromeArtist a) => aSum + a.albumCount,
                ),
          );

          return CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              // Top Toolbar: metrics + view mode switch
              SliverToBoxAdapter(
                child: _buildTopToolbar(
                  theme,
                  cs,
                  totalArtists,
                  totalAlbums,
                ),
              ),

              // Content Groups (List or Grid)
              for (final NavidromeArtistIndex group in nonEmptyGroups) ...<Widget>[
                SliverToBoxAdapter(
                  child: _buildSectionHeader(theme, cs, group),
                ),
                if (!_isGridView)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext ctx, int idx) {
                        return _buildArtistRow(
                          ctx,
                          theme,
                          cs,
                          group.artists[idx],
                          client,
                        );
                      },
                      childCount: group.artists.length,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Insets.lg,
                      vertical: Insets.xs,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 130,
                        childAspectRatio: 0.74,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext ctx, int idx) {
                          return _buildArtistGridCard(
                            ctx,
                            theme,
                            cs,
                            group.artists[idx],
                            client,
                          );
                        },
                        childCount: group.artists.length,
                      ),
                    ),
                  ),
              ],

              // Bottom padding clearance for navigation bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object err, _) => Center(
          child: Text('Failed to load artists: $err'),
        ),
      ),
    );
  }

  Widget _buildTopToolbar(
    ThemeData theme,
    ColorScheme cs,
    int totalArtists,
    int totalAlbums,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.lg,
        vertical: Insets.sm,
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.people_alt_rounded, size: 14, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  '$totalArtists ${totalArtists == 1 ? 'Artist' : 'Artists'}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '•',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(width: 6),
                Text(
                  '$totalAlbums ${totalAlbums == 1 ? 'Album' : 'Albums'}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  iconSize: 17,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    Icons.view_list_rounded,
                    color: !_isGridView ? cs.primary : cs.onSurfaceVariant,
                  ),
                  tooltip: 'List view',
                  onPressed: _isGridView
                      ? () => setState(() => _isGridView = false)
                      : null,
                ),
                IconButton(
                  iconSize: 17,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    Icons.grid_view_rounded,
                    color: _isGridView ? cs.primary : cs.onSurfaceVariant,
                  ),
                  tooltip: 'Grid view',
                  onPressed: !_isGridView
                      ? () => setState(() => _isGridView = true)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    ColorScheme cs,
    NavidromeArtistIndex group,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.lg,
        Insets.md,
        Insets.lg,
        Insets.xs,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  cs.primaryContainer,
                  cs.primaryContainer.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              group.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Divider(
              height: 1,
              thickness: 1,
              color: cs.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: Insets.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${group.artists.length}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistRow(
    BuildContext context,
    ThemeData theme,
    ColorScheme cs,
    NavidromeArtist artist,
    NavidromeClient? client,
  ) {
    final String cleanId =
        artist.id.startsWith('ar-') ? artist.id.substring(3) : artist.id;
    final String artistArtId =
        (artist.coverArt != null && artist.coverArt!.startsWith('ar-'))
            ? artist.coverArt!
            : 'ar-$cleanId';
    final String? coverUrl =
        (artist.artistImageUrl != null && artist.artistImageUrl!.isNotEmpty)
            ? artist.artistImageUrl
            : client?.getCoverArtUrl(artistArtId, size: 160);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.md,
        vertical: 2,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.sm,
              vertical: 8,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primaryContainer,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: coverUrl != null
                      ? AtriumNetworkImage(
                          imageUrl: coverUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Icon(
                            Icons.person_rounded,
                            size: 26,
                            color: cs.onPrimaryContainer,
                          ),
                        )
                      : Icon(
                          Icons.person_rounded,
                          size: 26,
                          color: cs.onPrimaryContainer,
                        ),
                ),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        artist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.album_rounded,
                              size: 12,
                              color: cs.onSecondaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${artist.albumCount} ${artist.albumCount == 1 ? 'Album' : 'Albums'}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtistGridCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme cs,
    NavidromeArtist artist,
    NavidromeClient? client,
  ) {
    final String cleanId =
        artist.id.startsWith('ar-') ? artist.id.substring(3) : artist.id;
    final String artistArtId =
        (artist.coverArt != null && artist.coverArt!.startsWith('ar-'))
            ? artist.coverArt!
            : 'ar-$cleanId';
    final String? coverUrl =
        (artist.artistImageUrl != null && artist.artistImageUrl!.isNotEmpty)
            ? artist.artistImageUrl
            : client?.getCoverArtUrl(artistArtId, size: 240);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primaryContainer,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: coverUrl != null
                    ? AtriumNetworkImage(
                        imageUrl: coverUrl,
                        width: 78,
                        height: 78,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Icon(
                          Icons.person_rounded,
                          size: 36,
                          color: cs.onPrimaryContainer,
                        ),
                      )
                    : Icon(
                        Icons.person_rounded,
                        size: 36,
                        color: cs.onPrimaryContainer,
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                artist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '${artist.albumCount} ${artist.albumCount == 1 ? 'Album' : 'Albums'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
