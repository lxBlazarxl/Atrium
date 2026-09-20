import 'package:core_networking/core_networking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_transmission/service_transmission.dart';

import 'support/fake_transmission.dart';
import 'support/pump.dart';
import 'support/transmission_fixtures.dart';
import 'support/transmission_test_instance.dart';

void main() {
  testWidgets('the bottom bar switches between Torrents and Settings',
      (WidgetTester tester) async {
    final FakeTransmission fake = FakeTransmission()
      ..on('session-get', sessionJson())
      ..on('session-stats', statsJson())
      ..on('torrent-get', <String, Object?>{'torrents': <Object>[]});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          instanceDioProvider(transmissionTestInstance)
              .overrideWith((Ref ref) async => fakeTransmissionDio(fake)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TransmissionHome(instance: transmissionTestInstance),
          ),
        ),
      ),
    );
    await settle(tester);

    expect(find.text('No torrents'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await settle(tester);
    expect(find.text('This session'), findsOneWidget);
  });
}
