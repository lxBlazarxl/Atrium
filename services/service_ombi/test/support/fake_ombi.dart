import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// One request the fake was sent.
class SeenRequest {
  const SeenRequest(this.method, this.path, this.body, this.headers);

  final String method;
  final String path;
  final Object? body;
  final Map<String, dynamic> headers;
}

/// Ombi, as far as the tests need it: canned answers keyed by method and
/// path, and a record of every request. Anything unconfigured is a 404.
class FakeOmbi implements HttpClientAdapter {
  final Map<String, Object?> _bodies = <String, Object?>{};
  final Map<String, int> _statuses = <String, int>{};
  final List<SeenRequest> seen = <SeenRequest>[];

  /// Answers `method path` with [json], encoded, and [status].
  void on(String method, String path, Object? json, {int status = 200}) {
    _bodies['$method $path'] = json;
    _statuses['$method $path'] = status;
  }

  /// The requests made to [path] with [method].
  List<SeenRequest> to(String method, String path) => <SeenRequest>[
        for (final SeenRequest r in seen)
          if (r.method == method && r.path == path) r,
      ];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final String path = options.uri.path;
    seen.add(SeenRequest(options.method, path, options.data, options.headers));
    final String key = '${options.method} $path';
    if (!_bodies.containsKey(key)) {
      return ResponseBody.fromString(
        '{"error":"no route"}',
        404,
        headers: _json,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(_bodies[key]),
      _statuses[key]!,
      headers: _json,
    );
  }

  static final Map<String, List<String>> _json = <String, List<String>>{
    Headers.contentTypeHeader: <String>['application/json'],
  };

  @override
  void close({bool force = false}) {}
}

/// A Dio set up the way an instance's would be, talking to [fake].
Dio fakeOmbiDio(FakeOmbi fake, {String base = 'http://ombi.test/'}) =>
    Dio(BaseOptions(baseUrl: base))..httpClientAdapter = fake;
