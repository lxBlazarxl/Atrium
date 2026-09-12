import 'package:flutter_test/flutter_test.dart';
import 'package:service_navidrome/service_navidrome.dart';

void main() {
  group('Navidrome Models JSON parsing', () {
    test('NavidromeArtist parses correctly', () {
      final json = {
        'id': 'art-1',
        'name': 'Daft Punk',
        'albumCount': 4,
        'coverArt': 'al-123',
        'artistImageUrl': 'https://example.com/artist.jpg',
      };

      final artist = NavidromeArtist.fromJson(json);
      expect(artist.id, 'art-1');
      expect(artist.name, 'Daft Punk');
      expect(artist.albumCount, 4);
      expect(artist.coverArt, 'al-123');
      expect(artist.artistImageUrl, 'https://example.com/artist.jpg');
    });

    test('NavidromeArtistIndex parses single and list', () {
      final jsonWithList = {
        'name': 'D',
        'artist': [
          {'id': 'art-1', 'name': 'Daft Punk', 'albumCount': 4},
          {'id': 'art-2', 'name': 'David Bowie', 'albumCount': 20},
        ],
      };

      final index = NavidromeArtistIndex.fromJson(jsonWithList);
      expect(index.name, 'D');
      expect(index.artists.length, 2);
      expect(index.artists[0].name, 'Daft Punk');
      expect(index.artists[1].name, 'David Bowie');

      final jsonWithSingle = {
        'name': 'D',
        'artist': {'id': 'art-1', 'name': 'Daft Punk'},
      };

      final singleIndex = NavidromeArtistIndex.fromJson(jsonWithSingle);
      expect(singleIndex.artists.length, 1);
      expect(singleIndex.artists[0].name, 'Daft Punk');
    });

    test('NavidromeAlbum parses correctly', () {
      final json = {
        'id': 'alb-1',
        'name': 'Discovery',
        'artist': 'Daft Punk',
        'artistId': 'art-1',
        'coverArt': 'cov-1',
        'songCount': 14,
        'duration': 3650,
        'year': 2001,
        'genre': 'Electronic',
        'playCount': 120,
      };

      final album = NavidromeAlbum.fromJson(json);
      expect(album.id, 'alb-1');
      expect(album.name, 'Discovery');
      expect(album.artist, 'Daft Punk');
      expect(album.artistId, 'art-1');
      expect(album.coverArt, 'cov-1');
      expect(album.songCount, 14);
      expect(album.duration, 3650);
      expect(album.year, 2001);
      expect(album.genre, 'Electronic');
      expect(album.playCount, 120);
    });

    test('NavidromeSong parses correctly', () {
      final json = {
        'id': 'sng-1',
        'title': 'One More Time',
        'album': 'Discovery',
        'albumId': 'alb-1',
        'artist': 'Daft Punk',
        'artistId': 'art-1',
        'track': 1,
        'discNumber': 1,
        'year': 2001,
        'genre': 'Electronic',
        'coverArt': 'cov-1',
        'duration': 320,
        'bitRate': 320,
        'suffix': 'flac',
        'size': 25000000,
        'contentType': 'audio/flac',
        'path': 'Daft Punk/Discovery/01.flac',
        'playCount': 42,
      };

      final song = NavidromeSong.fromJson(json);
      expect(song.id, 'sng-1');
      expect(song.title, 'One More Time');
      expect(song.album, 'Discovery');
      expect(song.track, 1);
      expect(song.suffix, 'flac');
      expect(song.bitRate, 320);
      expect(song.playCount, 42);
    });

    test('NavidromePlaylist parses correctly', () {
      final json = {
        'id': 'pl-1',
        'name': 'Workout Beats',
        'comment': 'High BPM',
        'owner': 'blazar',
        'public': true,
        'songCount': 50,
        'duration': 12000,
        'coverArt': 'cov-pl',
      };

      final playlist = NavidromePlaylist.fromJson(json);
      expect(playlist.id, 'pl-1');
      expect(playlist.name, 'Workout Beats');
      expect(playlist.comment, 'High BPM');
      expect(playlist.public, true);
      expect(playlist.songCount, 50);
      expect(playlist.duration, 12000);
    });

    test('NavidromeAlbumDetail parses album and songs envelope', () {
      final json = {
        'subsonic-response': {
          'status': 'ok',
          'version': '1.16.1',
          'album': {
            'id': 'alb-1',
            'name': 'Random Access Memories',
            'artist': 'Daft Punk',
            'song': [
              {'id': 's1', 'title': 'Give Life Back to Music', 'duration': 275},
              {'id': 's2', 'title': 'Get Lucky', 'duration': 369},
            ],
          },
        },
      };

      final detail = NavidromeAlbumDetail.fromJson(json);
      expect(detail.album.name, 'Random Access Memories');
      expect(detail.songs.length, 2);
      expect(detail.songs[0].title, 'Give Life Back to Music');
      expect(detail.songs[1].title, 'Get Lucky');
    });

    test('NavidromeSearchResult parses searchResult3 envelope', () {
      final json = {
        'subsonic-response': {
          'status': 'ok',
          'version': '1.16.1',
          'searchResult3': {
            'artist': [
              {'id': 'art-1', 'name': 'Daft Punk'},
            ],
            'album': [
              {'id': 'alb-1', 'name': 'Homework'},
            ],
            'song': [
              {'id': 's1', 'title': 'Da Funk'},
            ],
          },
        },
      };

      final result = NavidromeSearchResult.fromJson(json);
      expect(result.isEmpty, false);
      expect(result.artists.length, 1);
      expect(result.albums.length, 1);
      expect(result.songs.length, 1);
      expect(result.artists[0].name, 'Daft Punk');
      expect(result.albums[0].name, 'Homework');
      expect(result.songs[0].title, 'Da Funk');
    });

    test('NavidromeArtistInfo parses biography and image URLs', () {
      final json = {
        'biography': 'Legendary French electronic duo.',
        'musicBrainzId': 'mb-123',
        'lastFmUrl': 'https://last.fm/music/Daft+Punk',
        'smallImageUrl': 'https://example.com/small.jpg',
        'mediumImageUrl': 'https://example.com/med.jpg',
        'largeImageUrl': 'https://example.com/large.jpg',
      };

      final info = NavidromeArtistInfo.fromJson(json);
      expect(info.biography, 'Legendary French electronic duo.');
      expect(info.musicBrainzId, 'mb-123');
      expect(info.lastFmUrl, 'https://last.fm/music/Daft+Punk');
      expect(info.smallImageUrl, 'https://example.com/small.jpg');
      expect(info.mediumImageUrl, 'https://example.com/med.jpg');
      expect(info.largeImageUrl, 'https://example.com/large.jpg');
    });
  });
}
