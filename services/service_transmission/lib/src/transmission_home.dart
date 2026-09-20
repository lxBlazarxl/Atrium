import 'package:core_models/core_models.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'transmission_providers.dart';
import 'transmission_settings_tab.dart';
import 'transmission_torrents_tab.dart';

/// Transmission's per-instance UI: the torrent list and the settings, under
/// a bottom bar, the shape qBittorrent's screen has.
///
/// Back unwinds one thing at a time, selection then tab, before it leaves
/// the screen, so a long-press selection is not lost to a reflex back press.
class TransmissionHome extends ConsumerWidget {
  const TransmissionHome({required this.instance, super.key});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int tab = ref.watch(transmissionTabProvider(instance));
    final bool selecting =
        ref.watch(transmissionSelectionProvider(instance)).isNotEmpty;
    return PopScope(
      canPop: !selecting && tab == 0,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (didPop) return;
        if (selecting) {
          ref.invalidate(transmissionSelectionProvider(instance));
          return;
        }
        ref.read(transmissionTabProvider(instance).notifier).state = 0;
      },
      child: Scaffold(
        body: IndexedStack(
          index: tab,
          children: <Widget>[
            TransmissionTorrentsTab(instance: instance),
            TransmissionSettingsTab(instance: instance),
          ],
        ),
        bottomNavigationBar: AtriumBottomNav(
          visible: true,
          selectedIndex: tab,
          onDestinationSelected: (int i) =>
              ref.read(transmissionTabProvider(instance).notifier).state = i,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.download_outlined),
              selectedIcon: Icon(Icons.download),
              label: 'Torrents',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
