import 'package:core_models/core_models.dart';
import 'package:core_networking/core_networking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'navidrome_api.dart';

final navidromeClientProvider =
    FutureProvider.family<NavidromeClient, Instance>(
        (Ref ref, Instance instance) async {
  final DioFactory factory = ref.watch(dioFactoryProvider);
  final dio = await factory.create(instance);
  return NavidromeClient(instance: instance, dio: dio);
});

final navidromeServerInfoProvider =
    FutureProvider.family<NavidromeServerInfo, Instance>(
        (Ref ref, Instance instance) async {
  final NavidromeClient client =
      await ref.watch(navidromeClientProvider(instance).future);
  return client.ping();
});

final navidromeScanStatusProvider =
    FutureProvider.family<NavidromeScanStatus, Instance>(
        (Ref ref, Instance instance) async {
  final NavidromeClient client =
      await ref.watch(navidromeClientProvider(instance).future);
  return client.getScanStatus();
});

/// Fetches albums by category: 'recent', 'frequent', 'starred', 'newest', 'random'.
final navidromeAlbumsProvider =
    FutureProvider.family<List<NavidromeAlbum>, (Instance, String)>((
  Ref ref,
  (Instance, String) args,
) async {
  final (Instance instance, String type) = args;
  final NavidromeClient client =
      await ref.watch(navidromeClientProvider(instance).future);
  return client.getAlbumList(type: type);
});

/// Fetches all artists indexed alphabetically.
final navidromeArtistsProvider =
    FutureProvider.family<List<NavidromeArtistIndex>, Instance>((
  Ref ref,
  Instance instance,
) async {
  final NavidromeClient client =
      await ref.watch(navidromeClientProvider(instance).future);
  return client.getArtists();
});

/// Fetches an artist's full detail including their albums and external artist info.
final navidromeArtistDetailProvider =
    FutureProvider.family<NavidromeArtistDetail, (Instance, String)>((
  Ref ref,
  (Instance, String) args,
) async {
  final (Instance instance, String artistId) = args;
  final NavidromeClient client =
      await ref.watch(navidromeClientProvider(instance).future);
  final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
    client.getArtist(artistId),
    client.getArtistInfo(artistId),
  ]);
  final NavidromeArtistDetail detail = results[0] as NavidromeArtistDetail;
  final NavidromeArtistInfo? info = results[1] as NavidromeArtistInfo?;
  return detail.copyWith(info: info);
});

/// Fetches an album's full detail including tracklist.
final navidromeAlbumDetailProvider =
    FutureProvider.family<NavidromeAlbumDetail, (Instance, String)>((
  Ref ref,
  (Instance, String) args,
) async {
  final (Instance instance, String albumId) = args;
  final NavidromeClient client =
      await ref.watch(navidromeClientProvider(instance).future);
  return client.getAlbum(albumId);
});

/// Fetches all playlists.
final navidromePlaylistsProvider =
    FutureProvider.family<List<NavidromePlaylist>, Instance>((
  Ref ref,
  Instance instance,
) async {
  final NavidromeClient client =
      await ref.watch(navidromeClientProvider(instance).future);
  return client.getPlaylists();
});

/// Fetches a playlist's full detail including songs.
final navidromePlaylistDetailProvider =
    FutureProvider.family<NavidromePlaylistDetail, (Instance, String)>((
  Ref ref,
  (Instance, String) args,
) async {
  final (Instance instance, String playlistId) = args;
  final NavidromeClient client =
      await ref.watch(navidromeClientProvider(instance).future);
  return client.getPlaylist(playlistId);
});

/// Searches artists, albums, and tracks.
final navidromeSearchProvider =
    FutureProvider.family<NavidromeSearchResult, (Instance, String)>((
  Ref ref,
  (Instance, String) args,
) async {
  final (Instance instance, String query) = args;
  if (query.trim().isEmpty) {
    return const NavidromeSearchResult();
  }
  final NavidromeClient client =
      await ref.watch(navidromeClientProvider(instance).future);
  return client.search(query);
});

/// Persists active tab across screen transitions.
final navidromeActiveTabIndexProvider =
    StateProvider.family<int, Instance>((Ref ref, Instance instance) => 0);

/// Controls bottom navbar visibility during scroll.
final navidromeBottomNavVisibleProvider =
    StateProvider.family<bool, Instance>((Ref ref, Instance instance) => true);
