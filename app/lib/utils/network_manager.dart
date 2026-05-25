import 'package:dio/dio.dart';

class NetworkManager {
  static final NetworkManager _instance = NetworkManager._internal();
  late Dio _dio;

  // 修改为你的电脑局域网IP地址（手机连接同一WiFi时使用）
  // 查看方法：在电脑终端运行 ipconfig，找到 IPv4 地址
  static const String serverIP = '100.79.206.167';

  factory NetworkManager() {
    return _instance;
  }

  NetworkManager._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://$serverIP:3000/api',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Content-Type'] = 'application/json';
          options.headers['Authorization'] = 'Bearer token';
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
