import 'dart:convert';
import 'dart:math';

import 'package:core_models/core_models.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import 'models/navidrome_models.dart';

export 'models/navidrome_models.dart';

class NavidromeServerInfo {
  const NavidromeServerInfo({
    required this.status,
    required this.subsonicVersion,
    required this.serverVersion,
    required this.type,
  });

  final String status;
  final String subsonicVersion;
  final String serverVersion;
  final String type;

  factory NavidromeServerInfo.fromJson(Map<String, dynamic> json) {
    final dynamic resp = json['subsonic-response'] ?? json;
    final Map<String, dynamic> map =
        resp is Map<String, dynamic> ? resp : const <String, dynamic>{};
    return NavidromeServerInfo(
      status: (map['status'] as String?) ?? 'ok',
      subsonicVersion: (map['version'] as String?) ?? '1.16.1',
      serverVersion: (map['serverVersion'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'navidrome',
    );
  }
}

class NavidromeScanStatus {
  const NavidromeScanStatus({
    required this.scanning,
    required this.count,
  });

  final bool scanning;
  final int count;

  factory NavidromeScanStatus.fromJson(Map<String, dynamic> json) {
    final dynamic resp = json['subsonic-response'] ?? json;
    final Map<String, dynamic> map =
        resp is Map<String, dynamic> ? resp : const <String, dynamic>{};
    final dynamic scan = map['scanStatus'];
    final Map<String, dynamic> scanMap =
        scan is Map<String, dynamic> ? scan : const <String, dynamic>{};
    return NavidromeScanStatus(
      scanning: (scanMap['scanning'] as bool?) ?? false,
      count: (scanMap['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class NavidromeClient {
  NavidromeClient({
    required this.instance,
    required this.dio,
  });

  final Instance instance;
  final Dio dio;

  static const String clientName = 'Atrium';
  static const String apiVersion = '1.16.1';

  Map<String, String> _buildAuthParams([Map<String, String>? extra]) {
    final Map<String, String> params = <String, String>{
      'v': apiVersion,
      'c': clientName,
      'f': 'json',
      if (extra != null) ...extra,
    };

    final InstanceAuth auth = instance.auth;
    if (auth is InstanceAuthUserPass) {
      if (auth.username.isNotEmpty) {
        params['u'] = auth.username;
        if (auth.password.isNotEmpty) {
          final String salt = _randomSalt();
          final String token =
              md5.convert(utf8.encode('${auth.password}$salt')).toString();
          params['t'] = token;
          params['s'] = salt;
        }
      }
    }

    return params;
  }

  static String _randomSalt([int length = 8]) {
    const String chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random rnd = Random();
    return List<String>.generate(
      length,
      (_) => chars[rnd.nextInt(chars.length)],
    ).join();
  }

  /// Builds a deterministic cover art URL so image caches can key properly.
  String? getCoverArtUrl(String? coverArtId, {int? size}) {
    if (coverArtId == null || coverArtId.isEmpty) return null;
    final String baseUrl = (instance.localUrl.isNotEmpty
            ? instance.localUrl
            : instance.externalUrl)
        .trim();
    if (baseUrl.isEmpty) return null;
    final String cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final Map<String, String> query = <String, String>{
      'id': coverArtId,
      'v': apiVersion,
      'c': clientName,
      'f': 'json',
    };
    if (size != null && size > 0) {
      query['size'] = size.toString();
    }

    final InstanceAuth auth = instance.auth;
    if (auth is InstanceAuthUserPass && auth.username.isNotEmpty) {
      query['u'] = auth.username;
      if (auth.password.isNotEmpty) {
        final String stableSalt = md5
            .convert(utf8.encode('${instance.id}_salt'))
            .toString()
            .substring(0, 8);
        final String stableToken =
            md5.convert(utf8.encode('${auth.password}$stableSalt')).toString();
        query['t'] = stableToken;
        query['s'] = stableSalt;
      }
    }

    return Uri.parse('$cleanBase/rest/getCoverArt.view')
        .replace(queryParameters: query)
        .toString();
  }

  Future<NavidromeServerInfo> ping() async {
    final Response<dynamic> response = await dio.get<dynamic>(
      'rest/ping.view',
      queryParameters: _buildAuthParams(),
    );
    if (response.data is Map<String, dynamic>) {
      return NavidromeServerInfo.fromJson(
        response.data as Map<String, dynamic>,
      );
    }
    return const NavidromeServerInfo(
      status: 'ok',
      subsonicVersion: '1.16.1',
      serverVersion: '',
      type: 'navidrome',
    );
  }

  Future<NavidromeScanStatus> getScanStatus() async {
    final Response<dynamic> response = await dio.get<dynamic>(
      'rest/getScanStatus.view',
      queryParameters: _buildAuthParams(),
    );
    if (response.data is Map<String, dynamic>) {
      return NavidromeScanStatus.fromJson(
        response.data as Map<String, dynamic>,
      );
    }
    return const NavidromeScanStatus(scanning: false, count: 0);
  }

  Future<NavidromeScanStatus> startScan({bool fullScan = false}) async {
    final Response<dynamic> response = await dio.get<dynamic>(
      'rest/startScan.view',
      queryParameters: _buildAuthParams(<String, String>{
        'fullScan': fullScan ? 'true' : 'false',
      }),
    );
    if (response.data is Map<String, dynamic>) {
      return NavidromeScanStatus.fromJson(
        response.data as Map<String, dynamic>,
      );
    }
    return const NavidromeScanStatus(scanning: true, count: 0);
  }

  Future<List<NavidromeArtistIndex>> getArtists() async {
    final Response<dynamic> response = await dio.get<dynamic>(
      'rest/getArtists.view',
      queryParameters: _buildAuthParams(),
    );
    if (response.data is! Map<String, dynamic>) {
      return const <NavidromeArtistIndex>[];
    }
    final Map<String, dynamic> data = response.data as Map<String, dynamic>;
    final dynamic resp = data['subsonic-response'] ?? data;
    if (resp is! Map<String, dynamic>) {
      return const <NavidromeArtistIndex>[];
    }
    final dynamic artists = resp['artists'];
    if (artists is! Map<String, dynamic>) {
      return const <NavidromeArtistIndex>[];
    }
    final dynamic index = artists['index'];
    if (index is List) {
      return index
          .whereType<Map<dynamic, dynamic>>()
          .map((m) => NavidromeArtistIndex.fromJson(m.cast<String, dynamic>()))
          .toList();
    } else if (index is Map) {
      return <NavidromeArtistIndex>[
        NavidromeArtistIndex.fromJson(index.cast<String, dynamic>()),
      ];
    }
    return const <NavidromeArtistIndex>[];
  }

  Future<NavidromeArtistDetail> getArtist(String artistId) async {
    final Response<dynamic> response = await dio.get<dynamic>(
      'rest/getArtist.view',
      queryParameters: _buildAuthParams(<String, String>{'id': artistId}),
    );
    if (response.data is Map<String, dynamic>) {
      return NavidromeArtistDetail.fromJson(
        response.data as Map<String, dynamic>,
      );
    }
    return NavidromeArtistDetail(
      artist: NavidromeArtist(id: artistId, name: 'Unknown Artist'),
      albums: const <NavidromeAlbum>[],
    );
  }

  Future<NavidromeArtistInfo?> getArtistInfo(String artistId) async {
    try {
      final Response<dynamic> response = await dio.get<dynamic>(
        'rest/getArtistInfo2.view',
        queryParameters: _buildAuthParams(<String, String>{'id': artistId}),
      );
      if (response.data is! Map<String, dynamic>) return null;
      final Map<String, dynamic> data = response.data as Map<String, dynamic>;
      final dynamic resp = data['subsonic-response'] ?? data;
      if (resp is! Map<String, dynamic>) return null;
      final dynamic info = resp['artistInfo2'] ?? resp['artistInfo'];
      if (info is Map<String, dynamic>) {
        return NavidromeArtistInfo.fromJson(info);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<NavidromeAlbum>> getAlbumList({
    String type = 'recent',
    int size = 50,
    int offset = 0,
  }) async {
    final Response<dynamic> response = await dio.get<dynamic>(
      'rest/getAlbumList2.view',
      queryParameters: _buildAuthParams(<String, String>{
        'type': type,
        'size': size.toString(),
        'offset': offset.toString(),
      }),
    );
    if (response.data is! Map<String, dynamic>) {
      return const <NavidromeAlbum>[];
    }
    final Map<String, dynamic> data = response.data as Map<String, dynamic>;
    final dynamic resp = data['subsonic-response'] ?? data;
    if (resp is! Map<String, dynamic>) {
      return const <NavidromeAlbum>[];
    }
    final dynamic albumList = resp['albumList2'];
    if (albumList is! Map<String, dynamic>) {
      return const <NavidromeAlbum>[];
    }
    final dynamic albums = albumList['album'];
    if (albums is List) {
      return albums
          .whereType<Map<dynamic, dynamic>>()
          .map((m) => NavidromeAlbum.fromJson(m.cast<String, dynamic>()))
          .toList();
    } else if (albums is Map) {
      return <NavidromeAlbum>[
        NavidromeAlbum.fromJson(albums.cast<String, dynamic>()),
      ];
    }
    return const <NavidromeAlbum>[];
  }

  Future<NavidromeAlbumDetail> getAlbum(String albumId) async {
    final Response<dynamic> response = await dio.get<dynamic>(
      'rest/getAlbum.view',
      queryParameters: _buildAuthParams(<String, String>{'id': albumId}),
    );
    if (response.data is Map<String, dynamic>) {
      return NavidromeAlbumDetail.fromJson(
        response.data as Map<String, dynamic>,
      );
    }
    return NavidromeAlbumDetail(
      album: NavidromeAlbum(id: albumId, name: 'Unknown Album'),
      songs: const <NavidromeSong>[],
    );
  }

  Future<List<NavidromePlaylist>> getPlaylists() async {
    final Response<dynamic> response = await dio.get<dynamic>(
      'rest/getPlaylists.view',
      queryParameters: _buildAuthParams(),
    );
    if (response.data is! Map<String, dynamic>) {
      return const <NavidromePlaylist>[];
    }
    final Map<String, dynamic> data = response.data as Map<String, dynamic>;
    final dynamic resp = data['subsonic-response'] ?? data;
    if (resp is! Map<String, dynamic>) {
      return const <NavidromePlaylist>[];
    }
    final dynamic playlists = resp['playlists'];
    if (playlists is! Map<String, dynamic>) {
      return const <NavidromePlaylist>[];
    }
    final dynamic playlist = playlists['playlist'];
    if (playlist is List) {
      return playlist
          .whereType<Map<dynamic, dynamic>>()
          .map((m) => NavidromePlaylist.fromJson(m.cast<String, dynamic>()))
          .toList();
    } else if (playlist is Map) {
      return <NavidromePlaylist>[
        NavidromePlaylist.fromJson(playlist.cast<String, dynamic>()),
      ];
    }
    return const <NavidromePlaylist>[];
  }

  Future<NavidromePlaylistDetail> getPlaylist(String playlistId) async {
    final Response<dynamic> response = await dio.get<dynamic>(
      'rest/getPlaylist.view',
      queryParameters: _buildAuthParams(<String, String>{'id': playlistId}),
    );
    if (response.data is Map<String, dynamic>) {
      return NavidromePlaylistDetail.fromJson(
        response.data as Map<String, dynamic>,
      );
    }
    return NavidromePlaylistDetail(
      playlist: NavidromePlaylist(id: playlistId, name: 'Untitled Playlist'),
      songs: const <NavidromeSong>[],
    );
  }

  Future<NavidromeSearchResult> search(String query) async {
    if (query.trim().isEmpty) {
      return const NavidromeSearchResult();
    }
    final Response<dynamic> response = await dio.get<dynamic>(
      'rest/search3.view',
      queryParameters: _buildAuthParams(<String, String>{
        'query': query,
        'artistCount': '20',
        'albumCount': '20',
        'songCount': '50',
      }),
    );
    if (response.data is Map<String, dynamic>) {
      return NavidromeSearchResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    }
    return const NavidromeSearchResult();
  }
}
