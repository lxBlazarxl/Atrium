import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_myspeed/service_myspeed.dart';

void main() {
  testWidgets('MySpeedHome renders placeholder empty view',
      (WidgetTester tester) async {
    const Instance instance = Instance(
      id: 'test-myspeed',
      name: 'MySpeed Test',
      kind: ServiceKind.myspeed,
      localUrl: 'http://localhost:5216',
      externalUrl: '',
      urlMode: UrlMode.auto,
      auth: const InstanceAuth.apiKey(apiKey: ''),
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MySpeedHome(instance: instance),
          ),
        ),
      ),
    );

    expect(find.text('MySpeed'), findsOneWidget);
    expect(find.text('MySpeed service integration ready.'), findsOneWidget);
    expect(find.byIcon(Icons.network_check_outlined), findsOneWidget);
  });
}
