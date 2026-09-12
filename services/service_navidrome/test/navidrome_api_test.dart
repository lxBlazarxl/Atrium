import 'dart:convert';
import 'dart:typed_data';

import 'package:core_models/core_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_navidrome/service_navidrome.dart';

void main() {
  const Instance instance = Instance(
    id: 'navi-inst-1',
    name: 'Navidrome Server',
    kind: ServiceKind.navidrome,
    localUrl: 'http://192.168.1.50:4533',
    externalUrl: '',
    urlMode: UrlMode.auto,
    auth: InstanceAuth.userPass(username: 'alice', password: 'secretpassword'),
  );

  group('NavidromeClient', () {
    test('getCoverArtUrl generates deterministic URL with auth tokens', () {
      final dio = Dio();
      final client = NavidromeClient(instance: instance, dio: dio);

      final url1 = client.getCoverArtUrl('cov-123', size: 300);
      final url2 = client.getCoverArtUrl('cov-123', size: 300);

      expect(url1, isNotNull);
      expect(url1, equals(url2)); // Deterministic!
      expect(url1, contains('http://192.168.1.50:4533/rest/getCoverArt.view'));
      expect(url1, contains('id=cov-123'));
      expect(url1, contains('size=300'));
      expect(url1, contains('u=alice'));
      expect(url1, contains('v=1.16.1'));
      expect(url1, contains('c=Atrium'));
      expect(url1, contains('f=json'));
      expect(url1, contains('&t='));
      expect(url1, contains('&s='));
    });

    test('getArtists sends auth and parses response', () async {
      final adapter = _MockAdapter((options) {
        expect(options.path, 'rest/getArtists.view');
        expect(options.queryParameters['u'], 'alice');
        expect(options.queryParameters['v'], '1.16.1');
        expect(options.queryParameters['f'], 'json');
        return {
          'subsonic-response': {
            'status': 'ok',
            'version': '1.16.1',
            'artists': {
              'index': [
                {
                  'name': 'D',
                  'artist': [
                    {'id': 'a1', 'name': 'Daft Punk', 'albumCount': 4},
                  ],
                },
              ],
            },
          },
        };
      });

      final dio = Dio(BaseOptions(baseUrl: 'http://192.168.1.50:4533/'))
        ..httpClientAdapter = adapter;
      final client = NavidromeClient(instance: instance, dio: dio);

      final artists = await client.getArtists();
      expect(artists.length, 1);
      expect(artists.first.name, 'D');
      expect(artists.first.artists.first.name, 'Daft Punk');
    });

    test('getAlbumList sends type, size, and offset', () async {
      final adapter = _MockAdapter((options) {
        expect(options.path, 'rest/getAlbumList2.view');
        expect(options.queryParameters['type'], 'frequent');
        expect(options.queryParameters['size'], '25');
        expect(options.queryParameters['offset'], '0');
        return {
          'subsonic-response': {
            'status': 'ok',
            'version': '1.16.1',
            'albumList2': {
              'album': [
                {'id': 'alb-1', 'name': 'Discovery', 'artist': 'Daft Punk'},
              ],
            },
          },
        };
      });

      final dio = Dio(BaseOptions(baseUrl: 'http://192.168.1.50:4533/'))
        ..httpClientAdapter = adapter;
      final client = NavidromeClient(instance: instance, dio: dio);

      final albums = await client.getAlbumList(type: 'frequent', size: 25);
      expect(albums.length, 1);
      expect(albums.first.name, 'Discovery');
    });

    test('getAlbum returns detail with songs', () async {
      final adapter = _MockAdapter((options) {
        expect(options.path, 'rest/getAlbum.view');
        expect(options.queryParameters['id'], 'alb-1');
        return {
          'subsonic-response': {
            'status': 'ok',
            'version': '1.16.1',
            'album': {
              'id': 'alb-1',
              'name': 'Discovery',
              'song': [
                {'id': 's1', 'title': 'One More Time', 'duration': 320},
              ],
            },
          },
        };
      });

      final dio = Dio(BaseOptions(baseUrl: 'http://192.168.1.50:4533/'))
        ..httpClientAdapter = adapter;
      final client = NavidromeClient(instance: instance, dio: dio);

      final detail = await client.getAlbum('alb-1');
      expect(detail.album.name, 'Discovery');
      expect(detail.songs.length, 1);
      expect(detail.songs.first.title, 'One More Time');
    });

    test('getPlaylists and getPlaylist work correctly', () async {
      final adapter = _MockAdapter((options) {
        if (options.path == 'rest/getPlaylists.view') {
          return {
            'subsonic-response': {
              'status': 'ok',
              'playlists': {
                'playlist': [
                  {'id': 'p1', 'name': 'Favorites', 'songCount': 10},
                ],
              },
            },
          };
        } else if (options.path == 'rest/getPlaylist.view') {
          return {
            'subsonic-response': {
              'status': 'ok',
              'playlist': {
                'id': 'p1',
                'name': 'Favorites',
                'entry': [
                  {'id': 's1', 'title': 'Aerodynamic'},
                ],
              },
            },
          };
        }
        return {};
      });

      final dio = Dio(BaseOptions(baseUrl: 'http://192.168.1.50:4533/'))
        ..httpClientAdapter = adapter;
      final client = NavidromeClient(instance: instance, dio: dio);

      final playlists = await client.getPlaylists();
      expect(playlists.length, 1);
      expect(playlists.first.name, 'Favorites');

      final detail = await client.getPlaylist('p1');
      expect(detail.playlist.name, 'Favorites');
      expect(detail.songs.length, 1);
      expect(detail.songs.first.title, 'Aerodynamic');
    });

    test('search queries search3.view with query', () async {
      final adapter = _MockAdapter((options) {
        expect(options.path, 'rest/search3.view');
        expect(options.queryParameters['query'], 'Punk');
        return {
          'subsonic-response': {
            'status': 'ok',
            'searchResult3': {
              'artist': [
                {'id': 'a1', 'name': 'Daft Punk'},
              ],
            },
          },
        };
      });

      final dio = Dio(BaseOptions(baseUrl: 'http://192.168.1.50:4533/'))
        ..httpClientAdapter = adapter;
      final client = NavidromeClient(instance: instance, dio: dio);

      final result = await client.search('Punk');
      expect(result.artists.length, 1);
      expect(result.artists.first.name, 'Daft Punk');
    });

    test('startScan sends fullScan flag', () async {
      final adapter = _MockAdapter((options) {
        expect(options.path, 'rest/startScan.view');
        expect(options.queryParameters['fullScan'], 'true');
        return {
          'subsonic-response': {
            'status': 'ok',
            'scanStatus': {'scanning': true, 'count': 100},
          },
        };
      });

      final dio = Dio(BaseOptions(baseUrl: 'http://192.168.1.50:4533/'))
        ..httpClientAdapter = adapter;
      final client = NavidromeClient(instance: instance, dio: dio);

      final scan = await client.startScan(fullScan: true);
      expect(scan.scanning, true);
      expect(scan.count, 100);
    });

    test('getArtistInfo sends artist id and parses response', () async {
      final adapter = _MockAdapter((options) {
        expect(options.path, 'rest/getArtistInfo2.view');
        expect(options.queryParameters['id'], 'art-1');
        return {
          'subsonic-response': {
            'status': 'ok',
            'version': '1.16.1',
            'artistInfo2': {
              'biography': 'Bio of artist',
              'largeImageUrl': 'https://example.com/large.jpg',
            },
          },
        };
      });

      final dio = Dio(BaseOptions(baseUrl: 'http://192.168.1.50:4533/'))
        ..httpClientAdapter = adapter;
      final client = NavidromeClient(instance: instance, dio: dio);

      final info = await client.getArtistInfo('art-1');
      expect(info, isNotNull);
      expect(info!.biography, 'Bio of artist');
      expect(info.largeImageUrl, 'https://example.com/large.jpg');
    });
  });
}

class _MockAdapter implements HttpClientAdapter {
  _MockAdapter(this.handler);

  final Map<String, dynamic> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final data = handler(options);
    return ResponseBody.fromString(
      jsonEncode(data),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
