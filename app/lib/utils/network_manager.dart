import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_travel_app/utils/server_config.dart';

class NetworkManager {
  static final NetworkManager _instance = NetworkManager._internal();
  late Dio _dio;

  // Config ready signal - ensures all requests wait for config to load
  final _configReady = Completer<void>();
  bool _configLoaded = false;

  factory NetworkManager() {
    return _instance;
  }

  NetworkManager._internal() {
    _loadServerConfig();
  }

  Future<void> _loadServerConfig() async {
    final baseUrl = await ServerConfig.getBaseUrl();
    _dio = _createDio(baseUrl);
    _configLoaded = true;
    if (!_configReady.isCompleted) {
      _configReady.complete();
    }
  }

  /// Wait until config is loaded before making requests
  Future<void> ensureConfigReady() async {
    if (!_configLoaded) {
      await _configReady.future;
    }
  }

  Future<void> refreshBaseUrl() async {
    final baseUrl = await ServerConfig.getBaseUrl();
    _dio = _createDio(baseUrl);
  }

  String get baseUrl => _configLoaded ? _dio.options.baseUrl : '';

  Future<Response> health() async {
    await ensureConfigReady();
    final baseUri = Uri.parse(_dio.options.baseUrl);
    final healthUri = baseUri.replace(path: '/health', query: '');
    return await _dio.getUri(healthUri);
  }

  Dio _createDio(String baseUrl) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Content-Type'] = 'application/json';
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (kDebugMode) {
            debugPrint('Network error: ${e.message}');
          }
          return handler.next(e);
        },
      ),
    );

    return dio;
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    await ensureConfigReady();
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    await ensureConfigReady();
    return await _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    await ensureConfigReady();
    return await _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    await ensureConfigReady();
    return await _dio.delete(path);
  }
}
