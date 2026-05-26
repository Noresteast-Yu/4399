import 'package:dio/dio.dart';
import 'package:smart_travel_app/utils/server_config.dart';

class NetworkManager {
  static final NetworkManager _instance = NetworkManager._internal();
  late Dio _dio;
  String _baseUrl = 'http://localhost:3000/api';

  factory NetworkManager() {
    return _instance;
  }

  NetworkManager._internal() {
    _dio = _createDio(_baseUrl);
    _loadServerConfig();
  }

  Future<void> _loadServerConfig() async {
    final baseUrl = await ServerConfig.getBaseUrl();
    _baseUrl = baseUrl;
    _dio = _createDio(baseUrl);
  }

  Future<void> refreshBaseUrl() async {
    final baseUrl = await ServerConfig.getBaseUrl();
    _baseUrl = baseUrl;
    _dio = _createDio(baseUrl);
  }

  String get baseUrl => _baseUrl;

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
          print('Network error: ${e.message}');
          return handler.next(e);
        },
      ),
    );

    return dio;
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }
}
