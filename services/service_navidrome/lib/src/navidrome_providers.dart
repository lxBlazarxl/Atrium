import 'package:core_models/core_models.dart';
import 'package:core_networking/core_networking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'navidrome_api.dart';

final navidromeClientProvider =
    Provider.family<Future<NavidromeClient>, Instance>((ref, instance) async {
  final DioFactory factory = ref.watch(dioFactoryProvider);
  final dio = await factory.create(instance);
  return NavidromeClient(instance: instance, dio: dio);
});

final navidromeServerInfoProvider =
    FutureProvider.family<NavidromeServerInfo, Instance>((ref, instance) async {
  final NavidromeClient client =
      await ref.watch(navidromeClientProvider(instance));
  return client.ping();
});

final navidromeScanStatusProvider =
    FutureProvider.family<NavidromeScanStatus, Instance>((ref, instance) async {
  final NavidromeClient client =
      await ref.watch(navidromeClientProvider(instance));
  return client.getScanStatus();
});
