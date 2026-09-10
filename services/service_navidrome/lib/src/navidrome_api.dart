import 'dart:convert';
import 'dart:math';

import 'package:core_models/core_models.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

class NavidromeServerInfo {
  const NavidromeServerInfo({
    required this.status,
    required this.subsonicVersion,
    required this.serverVersion,
    required this.type,
  });

  final String status;
  final String subsonicVersion;
  final String serverVersion;
  final String type;

  factory NavidromeServerInfo.fromJson(Map<String, dynamic> json) {
    final dynamic resp = json['subsonic-response'] ?? json;
    final Map<String, dynamic> map =
        resp is Map<String, dynamic> ? resp : const <String, dynamic>{};
    return NavidromeServerInfo(
      status: (map['status'] as String?) ?? 'ok',
      subsonicVersion: (map['version'] as String?) ?? '1.16.1',
      serverVersion: (map['serverVersion'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'navidrome',
    );
  }
}

class NavidromeScanStatus {
  const NavidromeScanStatus({
    required this.scanning,
    required this.count,
  });

  final bool scanning;
  final int count;

  factory NavidromeScanStatus.fromJson(Map<String, dynamic> json) {
    final dynamic resp = json['subsonic-response'] ?? json;
    final Map<String, dynamic> map =
        resp is Map<String, dynamic> ? resp : const <String, dynamic>{};
    final dynamic scan = map['scanStatus'];
    final Map<String, dynamic> scanMap =
        scan is Map<String, dynamic> ? scan : const <String, dynamic>{};
    return NavidromeScanStatus(
      scanning: (scanMap['scanning'] as bool?) ?? false,
      count: (scanMap['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class NavidromeClient {
  NavidromeClient({
    required this.instance,
    required this.dio,
  });

  final Instance instance;
  final Dio dio;

  static const String clientName = 'Atrium';
  static const String apiVersion = '1.16.1';

  Map<String, String> _buildAuthParams() {
    final Map<String, String> params = <String, String>{
      'v': apiVersion,
      'c': clientName,
      'f': 'json',
    };

    final InstanceAuth auth = instance.auth;
    if (auth is InstanceAuthUserPass) {
      if (auth.username.isNotEmpty) {
        params['u'] = auth.username;
        if (auth.password.isNotEmpty) {
          // Token + salt auth for Subsonic API compatibility:
          // token = md5(password + salt)
          final String salt = _randomSalt();
          final String token =
              md5.convert(utf8.encode('${auth.password}$salt')).toString();
          params['t'] = token;
          params['s'] = salt;
        }
      }
    }

    return params;
  }

  static String _randomSalt([int length = 8]) {
    const String chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random rnd = Random();
    return List<String>.generate(
      length,
      (_) => chars[rnd.nextInt(chars.length)],
    ).join();
  }

  Future<NavidromeServerInfo> ping() async {
    final Response<dynamic> response = await dio.get<dynamic>(
      'rest/ping.view',
      queryParameters: _buildAuthParams(),
    );
    if (response.data is Map<String, dynamic>) {
      return NavidromeServerInfo.fromJson(
        response.data as Map<String, dynamic>,
      );
    }
    return const NavidromeServerInfo(
      status: 'ok',
      subsonicVersion: '1.16.1',
      serverVersion: '',
      type: 'navidrome',
    );
  }

  Future<NavidromeScanStatus> getScanStatus() async {
    final Response<dynamic> response = await dio.get<dynamic>(
      'rest/getScanStatus.view',
      queryParameters: _buildAuthParams(),
    );
    if (response.data is Map<String, dynamic>) {
      return NavidromeScanStatus.fromJson(
        response.data as Map<String, dynamic>,
      );
    }
    return const NavidromeScanStatus(scanning: false, count: 0);
  }
}
