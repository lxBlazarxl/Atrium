/// An individual speedtest result record from MySpeed.
class MySpeedTest {
  const MySpeedTest({
    required this.id,
    required this.download,
    required this.upload,
    required this.ping,
    this.jitter,
    this.createdAt,
    this.server,
    this.raw,
  });

  final String id;

  /// Download speed in Mbps.
  final double download;

  /// Upload speed in Mbps.
  final double upload;

  /// Ping / latency in ms.
  final double ping;

  /// Jitter in ms, if available.
  final double? jitter;

  /// When the speed test occurred.
  final DateTime? createdAt;

  /// Server or provider information.
  final String? server;

  /// Raw payload from MySpeed API.
  final Map<String, dynamic>? raw;

  factory MySpeedTest.fromJson(Map<String, dynamic> json) {
    final dynamic idVal = json['id'] ?? json['_id'] ?? json['uuid'] ?? '';
    final double downloadVal = _parseDouble(json['download'] ?? json['down'] ?? json['downloadSpeed']);
    final double uploadVal = _parseDouble(json['upload'] ?? json['up'] ?? json['uploadSpeed']);
    final double pingVal = _parseDouble(json['ping'] ?? json['latency']);
    final double? jitterVal = json['jitter'] != null ? _parseDouble(json['jitter']) : null;

    DateTime? date;
    final dynamic rawDate = json['created_at'] ?? json['createdAt'] ?? json['time'] ?? json['date'];
    if (rawDate is String) {
      date = DateTime.tryParse(rawDate)?.toLocal();
    } else if (rawDate is int) {
      date = DateTime.fromMillisecondsSinceEpoch(rawDate).toLocal();
    }

    String? serverName;
    if (json['server'] is String) {
      serverName = json['server'] as String;
    } else if (json['server'] is Map) {
      final Map<dynamic, dynamic> sMap = json['server'] as Map<dynamic, dynamic>;
      serverName = (sMap['name'] ?? sMap['sponsor'] ?? sMap['location'])?.toString();
    }

    return MySpeedTest(
      id: idVal.toString(),
      download: downloadVal,
      upload: uploadVal,
      ping: pingVal,
      jitter: jitterVal,
      createdAt: date,
      server: serverName,
      raw: json,
    );
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  String get formattedDownload => '${download.toStringAsFixed(1)} Mbps';
  String get formattedUpload => '${upload.toStringAsFixed(1)} Mbps';
  String get formattedPing => '${ping.toStringAsFixed(0)} ms';
  String? get formattedJitter => jitter != null ? '${jitter!.toStringAsFixed(0)} ms' : null;

  String get formattedTime {
    if (createdAt == null) return '';
    final String hour = createdAt!.hour.toString().padLeft(2, '0');
    final String min = createdAt!.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  String get formattedDate {
    if (createdAt == null) return '';
    final String month = createdAt!.month.toString().padLeft(2, '0');
    final String day = createdAt!.day.toString().padLeft(2, '0');
    return '$month/$day $formattedTime';
  }
}
