import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_navidrome/service_navidrome.dart';

void main() {
  const Instance navidrome = Instance(
    id: 'navidrome-1',
    name: 'My Navidrome',
    kind: ServiceKind.navidrome,
    localUrl: 'http://192.168.1.100:4533',
    externalUrl: '',
    urlMode: UrlMode.auto,
    auth: InstanceAuth.userPass(username: 'admin', password: 'password'),
  );

  testWidgets(
      'NavidromeAlbumScreen renders half-page banner with gradient fade and tracklist',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          navidromeAlbumDetailProvider((navidrome, 'alb-1')).overrideWith(
            (ref) async => const NavidromeAlbumDetail(
              album: NavidromeAlbum(
                id: 'alb-1',
                name: 'Discovery',
                artist: 'Daft Punk',
                artistId: 'art-1',
                year: 2001,
                genre: 'Electronic',
                duration: 3660,
                coverArt: 'al-101',
              ),
              songs: [
                NavidromeSong(
                  id: 's-1',
                  title: 'One More Time',
                  artist: 'Daft Punk',
                  track: 1,
                  duration: 320,
                  suffix: 'flac',
                ),
                NavidromeSong(
                  id: 's-2',
                  title: 'Aerodynamic',
                  artist: 'Daft Punk',
                  track: 2,
                  duration: 207,
                  suffix: 'flac',
                ),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          theme: AtriumTheme.light(null),
          home: const NavidromeAlbumScreen(
            instance: navidrome,
            albumId: 'alb-1',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify album name, artist name, and badges on banner
    expect(find.text('Discovery'), findsOneWidget);
    expect(find.text('Daft Punk'), findsWidgets);
    expect(find.text('2001'), findsOneWidget);
    expect(find.text('Electronic'), findsOneWidget);
    expect(find.text('2 Tracks'), findsOneWidget);
    expect(find.text('1 hr 1 min'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
    expect(find.byIcon(Icons.music_note_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.queue_music_rounded), findsOneWidget);
    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);

    // Verify tracklist
    expect(find.text('Tracks'), findsOneWidget);
    expect(find.text('One More Time'), findsOneWidget);
    expect(find.text('Aerodynamic'), findsOneWidget);
    expect(find.text('FLAC'), findsNWidgets(2));
  });
}
