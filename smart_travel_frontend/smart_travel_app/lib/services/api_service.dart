import 'package:dio/dio.dart';
import '../utils/network_manager.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  final NetworkManager _networkManager = NetworkManager();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  Future<ApiResponse<T>> _handleApiCall<T>(Future<T> Function() call) async {
    try {
      final result = await call();
      return ApiResponse<T>(success: true, data: result);
    } on DioException catch (e) {
      return ApiResponse<T>(
        success: false,
        error: '网络错误: ${e.message ?? '未知错误'}',
      );
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        error: '请求失败: $e',
      );
    }
  }

  Future<ApiResponse<List<dynamic>>> getRoutePlans(String start, String end) {
    return _handleApiCall<List<dynamic>>(() async {
      final response = await _networkManager.post('/route-plan/plan', data: {
        'start': start,
        'end': end,
      });
      return response.data is List ? response.data : [];
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getStationInfo(String stationId) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response =
          await _networkManager.get('/subway-service/station/$stationId');
      return Map<String, dynamic>.from(response.data);
    });
  }

  Future<ApiResponse<List<dynamic>>> getSubwayLines() {
    return _handleApiCall<List<dynamic>>(() async {
      final response = await _networkManager.get('/subway-service/lines');
      return response.data is List ? response.data : [];
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getTrainInfo(String trainNumber) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response =
          await _networkManager.get('/high-speed-rail/train/$trainNumber');
      return Map<String, dynamic>.from(response.data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getTrainGuide({
    required String trainNumber,
    required String destination,
    required String currentCarriage,
  }) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response = await _networkManager.post('/high-speed-rail/guide',
          data: {
            'trainNumber': trainNumber,
            'destination': destination,
            'currentCarriage': currentCarriage,
          });
      return Map<String, dynamic>.from(response.data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> startTransfer({
    required String from,
    required String to,
    int remainingTime = 300,
  }) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response = await _networkManager.post('/transfer-time/start', data: {
        'from': from,
        'to': to,
        'remainingTime': remainingTime,
      });
      return Map<String, dynamic>.from(response.data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getTransferUpdate(String sessionId) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response =
          await _networkManager.get('/transfer-time/update/$sessionId');
      return Map<String, dynamic>.from(response.data);
    });
  }

  Future<ApiResponse<List<dynamic>>> getCommonRoutes(String userId) {
    return _handleApiCall<List<dynamic>>(() async {
      final response =
          await _networkManager.get('/common-routes/user/$userId');
      return response.data is List ? response.data : [];
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> addCommonRoute({
    required String userId,
    required String start,
    required String end,
  }) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response = await _networkManager.post('/common-routes/add', data: {
        'userId': userId,
        'start': start,
        'end': end,
      });
      return Map<String, dynamic>.from(response.data);
    });
  }

  Future<ApiResponse<String>> deleteCommonRoute(String routeId) {
    return _handleApiCall<String>(() async {
      await _networkManager.delete('/common-routes/$routeId');
      return '删除成功';
    });
  }

  Future<ApiResponse<List<dynamic>>> getTravelAlerts({String? type}) {
    return _handleApiCall<List<dynamic>>(() async {
      final path = type != null ? '/travel-alerts/$type' : '/travel-alerts';
      final response = await _networkManager.get(path);
      return response.data is List ? response.data : [];
    });
  }
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
  });
}
