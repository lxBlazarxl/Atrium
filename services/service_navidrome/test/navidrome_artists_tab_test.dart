import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_navidrome/service_navidrome.dart';
import 'package:service_navidrome/src/widgets/navidrome_artists_tab.dart';

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
      'NavidromeArtistsTab renders alphabetical headers and artist cards',
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
              const NavidromeArtistIndex(
                name: 'M',
                artists: [
                  NavidromeArtist(
                    id: 'art-2',
                    name: 'Metallica',
                    albumCount: 11,
                  ),
                ],
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AtriumTheme.light(null),
          home: const Scaffold(
            body: NavidromeArtistsTab(instance: navidrome),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Alphabetical Section Headers exist
    expect(find.text('D'), findsOneWidget);
    expect(find.text('M'), findsOneWidget);

    // Verify Artist cards in list
    expect(find.text('Daft Punk'), findsOneWidget);
    expect(find.text('4 Albums'), findsOneWidget);
    expect(find.text('Metallica'), findsOneWidget);
    expect(find.text('11 Albums'), findsOneWidget);
  });
}
