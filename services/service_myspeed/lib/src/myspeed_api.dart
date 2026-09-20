import 'package:dio/dio.dart';

import 'models/myspeed_config.dart';
import 'models/myspeed_status.dart';
import 'models/myspeed_test.dart';

/// API client for interacting with MySpeed (`gnmyt/myspeed`).
class MySpeedApi {
  const MySpeedApi(this._dio);

  final Dio _dio;

  /// Queries whether a speedtest is currently running via `GET /api/speedtests/status`.
  Future<MySpeedStatus> getSpeedtestStatus() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      'api/speedtests/status',
    );
    return MySpeedStatus.fromResponse(response.data);
  }

  /// Fetches historical speedtests via `GET /api/speedtests?hours=24`.
  Future<List<MySpeedTest>> getHistory({int hours = 24}) async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      'api/speedtests',
      queryParameters: <String, dynamic>{'hours': hours},
    );

    final dynamic data = response.data;
    final List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['data'] is List) {
      list = data['data'] as List<dynamic>;
    } else if (data is Map && data['results'] is List) {
      list = data['results'] as List<dynamic>;
    } else {
      list = const <dynamic>[];
    }

    final List<MySpeedTest> tests = <MySpeedTest>[];
    for (final dynamic item in list) {
      if (item is Map) {
        tests.add(MySpeedTest.fromJson(item.cast<String, dynamic>()));
      }
    }

    // Sort descending by date (most recent first)
    tests.sort((a, b) {
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });

    return tests;
  }

  /// Fetches MySpeed server configuration via `GET /api/config`.
  Future<MySpeedConfig> getConfig() async {
    final Response<dynamic> response = await _dio.get<dynamic>('api/config');
    return MySpeedConfig.fromResponse(response.data);
  }

  /// Triggers a manual speedtest run on the server.
  Future<bool> runSpeedtest() async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>('api/speedtests');
      return (response.statusCode ?? 0) >= 200 && (response.statusCode ?? 0) < 300;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Fallback to alternative endpoint if available
        final Response<dynamic> alt = await _dio.post<dynamic>('api/speedtests/run');
        return (alt.statusCode ?? 0) >= 200 && (alt.statusCode ?? 0) < 300;
      }
      rethrow;
    }
  }
}
