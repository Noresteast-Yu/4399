import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class ServerConfig {
  static const String _hostKey = 'server_host';
  static const String _portKey = 'server_port';
  static const String _useHttpsKey = 'server_use_https';

  // Platform-aware default: localhost for Web, 10.0.2.2 for Android
  static String get defaultHost => kIsWeb ? 'localhost' : '10.0.2.2';
  static const String defaultPort = '3000';

  static Future<String> getHost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_hostKey) ?? defaultHost;
  }

  static Future<void> setHost(String host) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hostKey, host);
  }

  static Future<String> getPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_portKey) ?? defaultPort;
  }

  static Future<void> setPort(String port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_portKey, port);
  }

  static Future<bool> getUseHttps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useHttpsKey) ?? false;
  }

  static Future<void> setUseHttps(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useHttpsKey, value);
  }

  static Future<String> getBaseUrl() async {
    final rawHost = (await getHost()).trim();
    final port = (await getPort()).trim();
    final useHttps = await getUseHttps();
    final normalizedUrl = _baseUrlFromRawHost(rawHost, port);
    if (normalizedUrl != null) {
      return normalizedUrl;
    }

    final host = rawHost.isEmpty ? defaultHost : rawHost;
    final scheme = useHttps ? 'https' : 'http';
    return '$scheme://$host:$port/api';
  }

  static String? _baseUrlFromRawHost(String rawHost, String configuredPort) {
    if (!rawHost.startsWith('http://') && !rawHost.startsWith('https://')) {
      return null;
    }

    final uri = Uri.tryParse(rawHost);
    if (uri == null || uri.host.isEmpty) {
      return null;
    }

    final scheme = uri.scheme.isEmpty ? 'http' : uri.scheme;
    final port = uri.hasPort
        ? ':${uri.port}'
        : configuredPort.isEmpty
            ? ''
            : ':$configuredPort';
    final basePath = uri.path.replaceAll(RegExp(r'/+$'), '');
    final apiPath = basePath.endsWith('/api') ? basePath : '$basePath/api';
    return '$scheme://${uri.host}$port$apiPath';
  }
}
