import 'package:core_models/core_models.dart';
import 'package:core_networking/core_networking.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'models/myspeed_config.dart';
import 'models/myspeed_status.dart';
import 'models/myspeed_test.dart';
import 'myspeed_api.dart';

/// Active bottom navbar tab index for [instance] (0: Status, 1: History, 2: Config).
final myspeedActiveTabBarIndexProvider =
    StateProvider.autoDispose.family<int, Instance>((ref, instance) => 0);

/// Provides a [MySpeedApi] client instance configured for the given [Instance].
final myspeedApiProvider =
    FutureProvider.autoDispose.family<MySpeedApi, Instance>((
  Ref ref,
  Instance instance,
) async {
  final Dio dio = await ref.watch(instanceDioProvider(instance).future);
  return MySpeedApi(dio);
});

/// Fetches the current speedtest execution status from `GET /api/speedtests/status`.
final myspeedStatusProvider =
    FutureProvider.autoDispose.family<MySpeedStatus, Instance>((
  Ref ref,
  Instance instance,
) async {
  final MySpeedApi api = await ref.watch(myspeedApiProvider(instance).future);
  return api.getSpeedtestStatus();
});

/// Fetches the last 24 hours of speedtests from `GET /api/speedtests?hours=24`.
final myspeedHistoryProvider =
    FutureProvider.autoDispose.family<List<MySpeedTest>, Instance>((
  Ref ref,
  Instance instance,
) async {
  final MySpeedApi api = await ref.watch(myspeedApiProvider(instance).future);
  return api.getHistory();
});

/// Provides the single most recent speedtest result, or null if no results exist.
final myspeedLatestTestProvider =
    Provider.autoDispose.family<MySpeedTest?, Instance>((
  Ref ref,
  Instance instance,
) {
  final AsyncValue<List<MySpeedTest>> history =
      ref.watch(myspeedHistoryProvider(instance));
  final List<MySpeedTest>? list = history.asData?.value;
  if (list == null || list.isEmpty) return null;
  return list.first;
});

/// Fetches server configuration from `GET /api/config`.
final myspeedConfigProvider =
    FutureProvider.autoDispose.family<MySpeedConfig, Instance>((
  Ref ref,
  Instance instance,
) async {
  final MySpeedApi api = await ref.watch(myspeedApiProvider(instance).future);
  return api.getConfig();
});
