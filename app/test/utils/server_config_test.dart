import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_travel_app/utils/server_config.dart';

/// TDD 测试集: ServerConfig URL 构建逻辑
///
/// 覆盖:
/// - defaultHost 平台感知
/// - getHost/setHost 持久化
/// - getPort/setPort 持久化
/// - getUseHttps/setUseHttps 持久化
/// - _baseUrlFromRawHost URL 解析 (通过 getBaseUrl 测试)
/// - getBaseUrl 完整 URL 构建
void main() {
  // =========================================================================
  // defaultHost — 平台感知默认值
  // =========================================================================
  group('defaultHost', () {
    test('返回非空字符串', () {
      expect(ServerConfig.defaultHost, isNotEmpty);
    });

    test('Web 平台返回 localhost', () {
      if (kIsWeb) {
        expect(ServerConfig.defaultHost, 'localhost');
      }
    });

    test('非 Web 平台返回 10.0.2.2 (Android 模拟器)', () {
      if (!kIsWeb) {
        expect(ServerConfig.defaultHost, '10.0.2.2');
      }
    });

    test('defaultPort 为 3000', () {
      expect(ServerConfig.defaultPort, '3000');
    });
  });

  // =========================================================================
  // Host 持久化
  // =========================================================================
  group('Host 持久化', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('getHost 未设置时返回 defaultHost', () async {
      final host = await ServerConfig.getHost();
      expect(host, ServerConfig.defaultHost);
    });

    test('setHost 后 getHost 返回设置值', () async {
      await ServerConfig.setHost('192.168.1.100');
      final host = await ServerConfig.getHost();
      expect(host, '192.168.1.100');
    });

    test('setHost 覆盖之前的值', () async {
      await ServerConfig.setHost('10.0.0.1');
      await ServerConfig.setHost('192.168.1.200');
      final host = await ServerConfig.getHost();
      expect(host, '192.168.1.200');
    });
  });

  // =========================================================================
  // Port 持久化
  // =========================================================================
  group('Port 持久化', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('getPort 未设置时返回 3000', () async {
      final port = await ServerConfig.getPort();
      expect(port, '3000');
    });

    test('setPort 后 getPort 返回设置值', () async {
      await ServerConfig.setPort('8080');
      final port = await ServerConfig.getPort();
      expect(port, '8080');
    });
  });

  // =========================================================================
  // HTTPS 持久化
  // =========================================================================
  group('HTTPS 持久化', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('getUseHttps 未设置时返回 false', () async {
      final useHttps = await ServerConfig.getUseHttps();
      expect(useHttps, false);
    });

    test('setUseHttps(true) 后 getUseHttps 返回 true', () async {
      await ServerConfig.setUseHttps(true);
      final useHttps = await ServerConfig.getUseHttps();
      expect(useHttps, true);
    });

    test('setUseHttps(false) 后仍返回 false', () async {
      await ServerConfig.setUseHttps(true);
      await ServerConfig.setUseHttps(false);
      final useHttps = await ServerConfig.getUseHttps();
      expect(useHttps, false);
    });
  });

  // =========================================================================
  // getBaseUrl — 完整 URL 构建 + _baseUrlFromRawHost 集成测试
  // =========================================================================
  group('getBaseUrl 默认配置', () {
    test('默认配置返回默认 URL', () async {
      SharedPreferences.setMockInitialValues({});
      final url = await ServerConfig.getBaseUrl();
      final expectedHost = ServerConfig.defaultHost;
      expect(url, 'http://$expectedHost:3000/api');
    });

    test('设置 host 后 URL 使用自定义 host', () async {
      SharedPreferences.setMockInitialValues({
        'server_host': '192.168.0.100',
      });
      final url = await ServerConfig.getBaseUrl();
      expect(url, 'http://192.168.0.100:3000/api');
    });

    test('设置 port 后 URL 使用自定义 port', () async {
      SharedPreferences.setMockInitialValues({
        'server_port': '9090',
      });
      final url = await ServerConfig.getBaseUrl();
      final host = ServerConfig.defaultHost;
      expect(url, 'http://$host:9090/api');
    });

    test('启用 HTTPS 后 URL 使用 https scheme', () async {
      SharedPreferences.setMockInitialValues({
        'server_use_https': true,
      });
      final url = await ServerConfig.getBaseUrl();
      final host = ServerConfig.defaultHost;
      expect(url, 'https://$host:3000/api');
    });

    test('同时设置 host + port + https', () async {
      SharedPreferences.setMockInitialValues({
        'server_host': 'api.myserver.com',
        'server_port': '8443',
        'server_use_https': true,
      });
      final url = await ServerConfig.getBaseUrl();
      expect(url, 'https://api.myserver.com:8443/api');
    });
  });

  // =========================================================================
  // _baseUrlFromRawHost 集成测试 — 在 host 中嵌入完整 URL
  // =========================================================================
  group('rawHost 含 http(s):// 前缀 (走 _baseUrlFromRawHost 分支)', () {
    test('http:// 前缀 — 使用 rawHost 的 scheme 和 port', () async {
      SharedPreferences.setMockInitialValues({
        'server_host': 'http://10.0.0.5:4000',
        'server_use_https': true, // rawHost 指定了 http，忽略 useHttps
      });
      final url = await ServerConfig.getBaseUrl();
      expect(url, 'http://10.0.0.5:4000/api');
    });

    test('https:// 前缀 — 使用 rawHost 的 scheme', () async {
      SharedPreferences.setMockInitialValues({
        'server_host': 'https://secure.example.com',
        'server_use_https': false, // rawHost 指定了 https，忽略 useHttps
      });
      final url = await ServerConfig.getBaseUrl();
      expect(url, startsWith('https://'));
    });

    test('rawHost 含 /api 路径时不重复添加', () async {
      SharedPreferences.setMockInitialValues({
        'server_host': 'http://192.168.1.1:8080/api',
      });
      final url = await ServerConfig.getBaseUrl();
      expect(url, 'http://192.168.1.1:8080/api');
    });

    test('rawHost 含 /api/ 尾部斜杠时正确处理', () async {
      SharedPreferences.setMockInitialValues({
        'server_host': 'http://192.168.1.1:8080/api/',
      });
      final url = await ServerConfig.getBaseUrl();
      expect(url, 'http://192.168.1.1:8080/api');
    });

    test('rawHost 含自定义路径时追加 /api', () async {
      SharedPreferences.setMockInitialValues({
        'server_host': 'https://api.example.com/v1',
      });
      final url = await ServerConfig.getBaseUrl();
      expect(url, 'https://api.example.com:3000/v1/api');
    });

    test('rawHost 含多级路径时正确追加', () async {
      SharedPreferences.setMockInitialValues({
        'server_host': 'http://example.com/some/path',
        'server_port': '8080',
      });
      final url = await ServerConfig.getBaseUrl();
      expect(url, 'http://example.com:8080/some/path/api');
    });

    test('rawHost 为无效 URI(http://) 时 _baseUrlFromRawHost 返回 null', () async {
      // _baseUrlFromRawHost 返回 null（无效 URI），但 rawHost 非空
      // 所以 getBaseUrl 使用 rawHost 直接拼接
      SharedPreferences.setMockInitialValues({
        'server_host': 'http://',
      });
      final url = await ServerConfig.getBaseUrl();
      // rawHost='http://' non-empty, useHttps=false(default) → http://http://:3000/api
      expect(url, isNotEmpty);
      expect(url, contains('http://'));
    });

    test('rawHost 为 https:///path 时 _baseUrlFromRawHost 返回 null', () async {
      // 同样，rawHost 非空，getBaseUrl 使用 rawHost 直接拼接
      SharedPreferences.setMockInitialValues({
        'server_host': 'https:///path',
      });
      final url = await ServerConfig.getBaseUrl();
      expect(url, isNotEmpty);
      expect(url, contains('https:///path'));
    });

    test('rawHost 含尾部多斜杠路径时正确去除', () async {
      SharedPreferences.setMockInitialValues({
        'server_host': 'http://192.168.1.1/foo/bar///',
        'server_port': '4000',
      });
      final url = await ServerConfig.getBaseUrl();
      expect(url, 'http://192.168.1.1:4000/foo/bar/api');
    });
  });

  // =========================================================================
  // getBaseUrl 边界条件
  // =========================================================================
  group('getBaseUrl 边界条件', () {
    test('rawHost 为空时回退到 defaultHost', () async {
      SharedPreferences.setMockInitialValues({
        'server_host': '',
      });
      final url = await ServerConfig.getBaseUrl();
      final host = ServerConfig.defaultHost;
      expect(url, 'http://$host:3000/api');
    });

    test('仅设置 host 为 IP 地址', () async {
      SharedPreferences.setMockInitialValues({
        'server_host': '127.0.0.1',
      });
      final url = await ServerConfig.getBaseUrl();
      expect(url, 'http://127.0.0.1:3000/api');
    });

    test('host 含端口（非 http 前缀，走默认分支）', () async {
      SharedPreferences.setMockInitialValues({
        'server_host': 'myhost:9090',
      });
      final url = await ServerConfig.getBaseUrl();
      // 不走 _baseUrlFromRawHost（不是 http(s) 前缀），直接拼接
      expect(url, 'http://myhost:9090:3000/api');
    });
  });
}
