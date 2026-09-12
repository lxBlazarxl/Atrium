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
      'NavidromeHome renders bottom navigation bar and 7 album options',
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
          navidromeServerInfoProvider(navidrome).overrideWith(
            (ref) async => const NavidromeServerInfo(
              status: 'ok',
              subsonicVersion: '1.16.1',
              serverVersion: '0.52.5',
              type: 'navidrome',
            ),
          ),
          navidromeScanStatusProvider(navidrome).overrideWith(
            (ref) async => const NavidromeScanStatus(
              scanning: false,
              count: 4200,
            ),
          ),
          navidromeAlbumsProvider((navidrome, 'alphabeticalByName'))
              .overrideWith(
            (ref) async => [
              const NavidromeAlbum(
                id: 'alb-1',
                name: 'Discovery',
                artist: 'Daft Punk',
              ),
            ],
          ),
          navidromeAlbumsProvider((navidrome, 'random')).overrideWith(
            (ref) async => [],
          ),
          navidromeAlbumsProvider((navidrome, 'starred')).overrideWith(
            (ref) async => [],
          ),
          navidromeAlbumsProvider((navidrome, 'highest')).overrideWith(
            (ref) async => [],
          ),
          navidromeAlbumsProvider((navidrome, 'newest')).overrideWith(
            (ref) async => [],
          ),
          navidromeAlbumsProvider((navidrome, 'recent')).overrideWith(
            (ref) async => [],
          ),
          navidromeAlbumsProvider((navidrome, 'frequent')).overrideWith(
            (ref) async => [],
          ),
          navidromeArtistsProvider(navidrome).overrideWith(
            (ref) async => [
              const NavidromeArtistIndex(
                name: 'D',
                artists: [
                  NavidromeArtist(
                    id: 'art-1',
                    name: 'Daft Punk',
                    albumCount: 4,
                  ),
                ],
              ),
            ],
          ),
          navidromePlaylistsProvider(navidrome).overrideWith(
            (ref) async => [
              const NavidromePlaylist(
                id: 'pl-1',
                name: 'Favorites',
                songCount: 12,
                duration: 2400,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AtriumTheme.light(null),
          home: const NavidromeHome(
            instance: navidrome,
            drawer: Drawer(child: Text('Test Drawer Content')),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar title, Beta badge, and actions
    expect(find.text('My Navidrome'), findsOneWidget);
    expect(find.byType(BetaBadge), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.sync_rounded), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);

    // Verify Bottom NavigationBar with 3 destinations
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Albums'), findsOneWidget);
    expect(find.text('Artists'), findsOneWidget);
    expect(find.text('Playlists'), findsOneWidget);
    // Overview tab should NOT exist
    expect(find.text('Overview'), findsNothing);

    // Verify 7 Album filter options are present
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Random'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Top Rated'), findsOneWidget);
    expect(find.text('Recently Added'), findsOneWidget);
    expect(find.text('Recently Played'), findsOneWidget);
    expect(find.text('Most Played'), findsOneWidget);

    // Verify initial album item in grid
    expect(find.text('Discovery'), findsOneWidget);
    expect(find.text('Daft Punk'), findsOneWidget);

    // Switch to Artists destination
    await tester.tap(find.text('Artists'));
    await tester.pumpAndSettle();
    expect(find.text('D'), findsOneWidget);
    expect(find.text('4 Albums'), findsWidgets);

    // Switch to Playlists destination
    await tester.tap(find.text('Playlists'));
    await tester.pumpAndSettle();
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('12 songs • 40:00'), findsOneWidget);

    // Open drawer via hamburger button
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('Test Drawer Content'), findsOneWidget);
  });
}
