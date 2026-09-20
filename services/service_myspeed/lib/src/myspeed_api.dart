import 'package:dio/dio.dart';

import 'models/myspeed_config.dart';
import 'models/myspeed_status.dart';
import 'models/myspeed_storage.dart';
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

  /// Fetches speedtests via `GET /api/speedtests`.
  ///
  /// Optional [limit] specifies max records (e.g. 1000 for all tests, 10 for incremental diff).
  /// Optional [afterId] specifies pagination cursor.
  Future<List<MySpeedTest>> getSpeedtests({int? limit, int? afterId}) async {
    final Map<String, dynamic> params = <String, dynamic>{};
    if (limit != null) params['limit'] = limit;
    if (afterId != null) params['afterId'] = afterId;

    final Response<dynamic> response = await _dio.get<dynamic>(
      'api/speedtests',
      queryParameters: params.isNotEmpty ? params : null,
    );

    return _parseTests(response.data);
  }

  /// Fetches speedtests from the past 24 hours via `GET /api/speedtests?hours=24`.
  ///
  /// Passes `hours=24` and `hour=24` query parameters to match various MySpeed backend
  /// implementations and performs a client-side cutoff timestamp filter as a safeguard.
  Future<List<MySpeedTest>> get24HourSpeedtests() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      'api/speedtests',
      queryParameters: <String, dynamic>{
        'hours': 24,
        'hour': 24,
      },
    );

    final List<MySpeedTest> tests = _parseTests(response.data);
    final DateTime cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return tests.where((MySpeedTest t) {
      if (t.createdAt == null) return true;
      return t.createdAt!.isAfter(cutoff);
    }).toList();
  }

  /// Fetches historical speedtests via `GET /api/speedtests`.
  ///
  /// Optional [hours] param supported if backend implements it.
  Future<List<MySpeedTest>> getHistory({int? hours, int? hour}) async {
    final Map<String, dynamic> params = <String, dynamic>{};
    if (hours != null) params['hours'] = hours;
    if (hour != null) params['hour'] = hour;

    final Response<dynamic> response = await _dio.get<dynamic>(
      'api/speedtests',
      queryParameters: params.isNotEmpty ? params : null,
    );

    return _parseTests(response.data);
  }

  /// Fetches a single speedtest by its ID via `GET /api/speedtests/:id`.
  Future<MySpeedTest?> getSpeedtestById(String id) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>('api/speedtests/$id');
      final dynamic data = response.data;
      if (data == null) return null;
      if (data is Map) {
        final Map<String, dynamic> map = data.cast<String, dynamic>();
        if (map.containsKey('data') && map['data'] is Map) {
          return MySpeedTest.fromJson((map['data'] as Map).cast<String, dynamic>());
        }
        return MySpeedTest.fromJson(map);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  /// Fetches MySpeed server configuration via `GET /api/config`.
  Future<MySpeedConfig> getConfig() async {
    final Response<dynamic> response = await _dio.get<dynamic>('api/config');
    return MySpeedConfig.fromResponse(response.data);
  }

  /// Fetches storage usage information via `GET /api/storage`.
  Future<MySpeedStorage> getStorage() async {
    final Response<dynamic> response = await _dio.get<dynamic>('api/storage');
    return MySpeedStorage.fromJson(response.data);
  }

  /// Triggers a manual speedtest run on the server.
  ///
  /// Calls `POST /api/speedtests/run` with fallback to `POST /api/speedtests`.
  Future<bool> runSpeedtest() async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>('api/speedtests/run');
      return (response.statusCode ?? 0) >= 200 && (response.statusCode ?? 0) < 300;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final Response<dynamic> alt = await _dio.post<dynamic>('api/speedtests');
        return (alt.statusCode ?? 0) >= 200 && (alt.statusCode ?? 0) < 300;
      }
      rethrow;
    }
  }

  List<MySpeedTest> _parseTests(dynamic data) {
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
}
