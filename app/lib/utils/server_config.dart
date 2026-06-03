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
    final host = await getHost();
    final port = await getPort();
    final useHttps = await getUseHttps();
    final scheme = useHttps ? 'https' : 'http';
    return '$scheme://$host:$port/api';
  }
}
