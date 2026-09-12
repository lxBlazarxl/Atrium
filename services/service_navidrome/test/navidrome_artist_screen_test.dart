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

  testWidgets('NavidromeArtistScreen renders half-page banner with gradient fade',
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
          navidromeArtistDetailProvider((navidrome, 'art-1')).overrideWith(
            (ref) async => const NavidromeArtistDetail(
              artist: NavidromeArtist(
                id: 'art-1',
                name: 'Daft Punk',
                albumCount: 2,
                coverArt: 'ar-101',
              ),
              info: NavidromeArtistInfo(
                biography:
                    'Daft Punk was a French electronic music duo formed in 1993 in Paris by Thomas Bangalter and Guy-Manuel de Homem-Christo. Widely regarded as one of the most influential acts in dance music history, they achieved widespread popularity in the late 1990s and continued to innovate throughout the 2000s and 2010s.',
              ),
              albums: [
                NavidromeAlbum(
                  id: 'alb-1',
                  name: 'Discovery',
                  artist: 'Daft Punk',
                  year: 2001,
                  coverArt: 'al-201',
                ),
                NavidromeAlbum(
                  id: 'alb-2',
                  name: 'Random Access Memories',
                  artist: 'Daft Punk',
                  year: 2013,
                  coverArt: 'al-202',
                ),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          theme: AtriumTheme.light(null),
          home: const NavidromeArtistScreen(
            instance: navidrome,
            artistId: 'art-1',
            initialArtistName: 'Daft Punk',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify top right actions for Rate and Favorite
    expect(find.byTooltip('Rate'), findsOneWidget);
    expect(find.byTooltip('Add to favorites'), findsOneWidget);

    // Verify artist name and album badge rendered on banner
    expect(find.text('Daft Punk'), findsOneWidget);
    expect(find.text('2 Albums'), findsOneWidget);

    // Verify biography section and Read more toggle
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Read more'), findsOneWidget);
    await tester.tap(find.text('Read more'));
    await tester.pumpAndSettle();
    expect(find.text('Read less'), findsOneWidget);

    // Verify section header and album grid
    expect(find.text('Albums'), findsOneWidget);
    expect(find.text('Discovery'), findsOneWidget);
    expect(find.text('2001'), findsOneWidget);
    expect(find.text('Random Access Memories'), findsOneWidget);
    expect(find.text('2013'), findsOneWidget);
  });
}
