import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_myspeed/service_myspeed.dart';

void main() {
  const Instance instance = Instance(
    id: 'test-myspeed',
    name: 'MySpeed Test',
    kind: ServiceKind.myspeed,
    localUrl: 'http://localhost:5216',
    externalUrl: '',
    urlMode: UrlMode.auto,
    auth: InstanceAuth.apiKey(apiKey: ''),
  );

  final List<MySpeedTest> sampleTests = <MySpeedTest>[
    MySpeedTest(
      id: '1',
      download: 320.5,
      upload: 45.2,
      ping: 12.0,
      createdAt: DateTime.now(),
      server: 'Local ISP',
    ),
  ];

  const MySpeedConfig sampleConfig = MySpeedConfig(
    entries: <String, dynamic>{
      'cron': '0 * * * *',
      'provider': 'ookla',
      'server_name': 'myspeed-node',
    },
    cron: '0 * * * *',
    provider: 'ookla',
  );

  List<Override> overridesForTab({
    bool isRunning = false,
    int activeTab = 0,
  }) {
    return <Override>[
      myspeedActiveTabBarIndexProvider(instance).overrideWith((ref) => activeTab),
      myspeedStatusProvider(instance).overrideWith(
        (ref) async => MySpeedStatus(isRunning: isRunning),
      ),
      myspeedHistoryProvider(instance).overrideWith(
        (ref) async => sampleTests,
      ),
      myspeedConfigProvider(instance).overrideWith(
        (ref) async => sampleConfig,
      ),
    ];
  }

  testWidgets('MySpeedHome renders bottom NavigationBar with 3 destinations',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesForTab(),
        child: const MaterialApp(
          home: MySpeedHome(instance: instance),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Config'), findsOneWidget);
  });

  testWidgets('Tab 0 renders status, run action, and latest result',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesForTab(),
        child: const MaterialApp(
          home: MySpeedHome(instance: instance),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Execution Status'), findsOneWidget);
    expect(find.text('Idle'), findsOneWidget);
    expect(find.text('Manual Speedtest'), findsOneWidget);
    expect(find.text('Run Test'), findsOneWidget);
    expect(find.text('Most Recent Result'), findsOneWidget);
    expect(find.text('320.5'), findsOneWidget);
    expect(find.text('45.2'), findsOneWidget);
  });

  testWidgets('Tab 1 renders 24-hour summary and test card',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesForTab(activeTab: 1),
        child: const MaterialApp(
          home: MySpeedHome(instance: instance),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('24-Hour Summary'), findsOneWidget);
    expect(find.text('1 tests'), findsOneWidget);
    expect(find.text('320.5 Mbps'), findsNWidgets(2)); // summary + card
  });

  testWidgets('Tab 2 renders config overview and properties',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesForTab(activeTab: 2),
        child: const MaterialApp(
          home: MySpeedHome(instance: instance),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Configuration Overview'), findsOneWidget);
    expect(find.text('0 * * * *'), findsNWidgets(2));
    expect(find.text('ookla'), findsNWidgets(2));
    expect(find.text('server_name'), findsOneWidget);
  });
}
