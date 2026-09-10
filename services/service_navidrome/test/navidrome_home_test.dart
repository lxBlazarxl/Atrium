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

  testWidgets('NavidromeHome renders header, connection, and overview info',
      (WidgetTester tester) async {
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
        ],
        child: MaterialApp(
          theme: AtriumTheme.light(null),
          home: const Scaffold(
            body: NavidromeHome(instance: navidrome),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('My Navidrome'), findsOneWidget);
    expect(find.text('Navidrome Music Server'), findsOneWidget);
    expect(find.text('Open Web Player'), findsOneWidget);
    expect(find.text('Server Overview'), findsOneWidget);
    expect(find.text('Subsonic API'), findsOneWidget);
    expect(find.text('v1.16.1'), findsOneWidget);
    expect(find.text('Navidrome 0.52.5'), findsOneWidget);
    expect(find.text('Library Scan'), findsOneWidget);
    expect(find.text('4200 items'), findsOneWidget);
    expect(find.text('Connection Details'), findsOneWidget);
    expect(find.text('http://192.168.1.100:4533'), findsOneWidget);
    expect(find.text('User: admin'), findsOneWidget);
    expect(find.text('Online (ok)'), findsOneWidget);
    expect(find.text('Music Player & Library Browser'), findsOneWidget);
  });
}
