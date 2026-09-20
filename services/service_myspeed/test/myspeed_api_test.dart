import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_myspeed/service_myspeed.dart';

void main() {
  group('MySpeedStatus.fromResponse', () {
    test('parses boolean responses', () {
      expect(MySpeedStatus.fromResponse(true).isRunning, isTrue);
      expect(MySpeedStatus.fromResponse(false).isRunning, isFalse);
    });

    test('parses map with running boolean', () {
      expect(MySpeedStatus.fromResponse(<String, dynamic>{'running': true}).isRunning, isTrue);
      expect(MySpeedStatus.fromResponse(<String, dynamic>{'running': false}).isRunning, isFalse);
    });

    test('parses map with status string', () {
      final running = MySpeedStatus.fromResponse(<String, dynamic>{
        'status': 'running',
        'message': 'Testing download',
      });
      expect(running.isRunning, isTrue);
      expect(running.message, 'Testing download');

      final idle = MySpeedStatus.fromResponse(<String, dynamic>{
        'status': 'idle',
      });
      expect(idle.isRunning, isFalse);
    });

    test('parses string response', () {
      expect(MySpeedStatus.fromResponse('running').isRunning, isTrue);
      expect(MySpeedStatus.fromResponse('idle').isRunning, isFalse);
    });

    test('parses null safely', () {
      expect(MySpeedStatus.fromResponse(null).isRunning, isFalse);
    });
  });

  group('MySpeedTest.fromJson', () {
    test('parses speed test record correctly', () {
      final test = MySpeedTest.fromJson(<String, dynamic>{
        'id': 101,
        'download': 250.5,
        'upload': 50.1,
        'ping': 14.2,
        'jitter': 2.1,
        'created_at': '2026-09-20T12:00:00.000Z',
        'server': 'Cloudflare',
      });

      expect(test.id, '101');
      expect(test.download, 250.5);
      expect(test.upload, 50.1);
      expect(test.ping, 14.2);
      expect(test.jitter, 2.1);
      expect(test.formattedDownload, '250.5 Mbps');
      expect(test.formattedUpload, '50.1 Mbps');
      expect(test.formattedPing, '14 ms');
      expect(test.server, 'Cloudflare');
    });
  });

  group('MySpeedConfig.fromResponse', () {
    test('parses map config', () {
      final config = MySpeedConfig.fromResponse(<String, dynamic>{
        'cron': '*/30 * * * *',
        'provider': 'ookla',
        'server': 'node-1',
        'custom_key': 'custom_val',
      });

      expect(config.cron, '*/30 * * * *');
      expect(config.provider, 'ookla');
      expect(config.server, 'node-1');
      expect(config.entries['custom_key'], 'custom_val');
    });

    test('parses list of key-values', () {
      final config = MySpeedConfig.fromResponse(<dynamic>[
        <String, dynamic>{'key': 'cron', 'value': '0 * * * *'},
        <String, dynamic>{'key': 'provider', 'value': 'librespeed'},
      ]);

      expect(config.cron, '0 * * * *');
      expect(config.provider, 'librespeed');
    });
  });

  group('MySpeedApi', () {
    test('getSpeedtestStatus calls api/speedtests/status', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter(
        handler: (options) {
          if (options.path.contains('status')) {
            return ResponseBody.fromString(
              '{"running": true, "message": "Ookla test in progress"}',
              200,
              headers: <String, List<String>>{
                Headers.contentTypeHeader: <String>[Headers.jsonContentType],
              },
            );
          }
          return ResponseBody.fromString('{}', 200);
        },
      );

      final api = MySpeedApi(dio);
      final status = await api.getSpeedtestStatus();

      expect(status.isRunning, isTrue);
      expect(status.message, 'Ookla test in progress');
    });

    test('getHistory calls api/speedtests with hours param', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter(
        handler: (options) {
          expect(options.queryParameters['hours'], 48);
          return ResponseBody.fromString(
            '[{"id": 1, "download": 100.0, "upload": 20.0, "ping": 10.0}]',
            200,
            headers: <String, List<String>>{
              Headers.contentTypeHeader: <String>[Headers.jsonContentType],
            },
          );
        },
      );

      final api = MySpeedApi(dio);
      final history = await api.getHistory(hours: 48);

      expect(history.length, 1);
      expect(history.first.download, 100.0);
    });

    test('getConfig calls api/config', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter(
        handler: (options) {
          return ResponseBody.fromString(
            '{"cron": "0 * * * *", "provider": "ookla"}',
            200,
            headers: <String, List<String>>{
              Headers.contentTypeHeader: <String>[Headers.jsonContentType],
            },
          );
        },
      );

      final api = MySpeedApi(dio);
      final config = await api.getConfig();

      expect(config.cron, '0 * * * *');
      expect(config.provider, 'ookla');
    });

    test('runSpeedtest sends POST', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter(
        handler: (options) {
          expect(options.method, 'POST');
          return ResponseBody.fromString('{"success": true}', 200);
        },
      );

      final api = MySpeedApi(dio);
      final result = await api.runSpeedtest();
      expect(result, isTrue);
    });
  });
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({required this.handler});

  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}
