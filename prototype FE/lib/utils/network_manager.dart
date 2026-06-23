import 'package:dio/dio.dart';

class NetworkManager {
  static final NetworkManager _instance = NetworkManager._internal();
  late Dio _dio;
  
  factory NetworkManager() {
    return _instance;
  }
  
  NetworkManager._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.smarttravel.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    
    // 添加请求拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 添加请求头
          options.headers['Content-Type'] = 'application/json';
          options.headers['Authorization'] = 'Bearer token';
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // 统一处理响应
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // 统一处理错误
          print('Network error: ${e.message}');
          return handler.next(e);
        },
      ),
    );
  }
  
  // GET请求
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }
  
  // POST请求
  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }
  
  // PUT请求
  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }
  
  // DELETE请求
  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }
}
