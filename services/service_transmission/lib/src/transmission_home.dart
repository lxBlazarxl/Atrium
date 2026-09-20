import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';

import 'transmission_torrents_tab.dart';

/// Transmission's per-instance UI. Grows a Settings tab and a bottom bar in
/// a later change; for now it is the torrent list.
class TransmissionHome extends StatelessWidget {
  const TransmissionHome({required this.instance, super.key});

  final Instance instance;

  @override
  Widget build(BuildContext context) =>
      TransmissionTorrentsTab(instance: instance);
}
