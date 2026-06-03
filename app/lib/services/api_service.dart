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

  Future<ApiResponse<List<dynamic>>> getRoutePlans(
    String start,
    String end, {
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final response = await _networkManager.post('/route-plan/plan', data: {
        'start': start,
        'end': end,
        if (preferences != null) 'preferences': preferences,
      });
      if (response.data is Map && response.data['success'] == true) {
        final routes = response.data['routes'];
        return ApiResponse<List<dynamic>>(
          success: true,
          data: routes is List ? routes : [],
        );
      }
    } catch (_) {}

    return ApiResponse<List<dynamic>>(
      success: false,
      error: '后端服务不可用，请使用AI智能规划功能',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getStationInfo(String stationId) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response =
          await _networkManager.get('/subway-service/station/$stationId');
      return Map<String, dynamic>.from(response.data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getStationFacilities(
      String stationId) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response = await _networkManager
          .get('/subway-service/station/$stationId/facilities');
      return Map<String, dynamic>.from(response.data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getAllStationFacilities() {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response = await _networkManager.get('/subway-service/facilities');
      return Map<String, dynamic>.from(response.data);
    });
  }

  Future<ApiResponse<List<dynamic>>> getSubwayLines() {
    return _handleApiCall<List<dynamic>>(() async {
      final response = await _networkManager.get('/subway-service/lines');
      return response.data is List ? response.data : [];
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getMetroArrival({
    required String stopId,
    String? stopName,
    String lineId = 'mock-line-10',
    String lineName = '10号线',
    int direction = 0,
    String cityCode = 'mock-shanghai',
  }) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response = await _networkManager.get(
        '/metro/arrival',
        queryParameters: {
          'lineId': lineId,
          'lineName': lineName,
          'stopId': stopId,
          if (stopName != null && stopName.isNotEmpty) 'stopName': stopName,
          'direction': direction,
          'cityCode': cityCode,
        },
      );
      final data = response.data;
      if (data is Map && data['success'] == true && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data']);
      }
      return Map<String, dynamic>.from(data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getIndoorGuide({
    required String from,
    required String to,
  }) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response = await _networkManager.get(
        '/indoor-guide',
        queryParameters: {
          'from': from,
          'to': to,
        },
      );
      final data = response.data;
      if (data is Map && data['success'] == true && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data']);
      }
      return Map<String, dynamic>.from(data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getIndoorGuideProgress({
    required String from,
    required String to,
    required int stepIndex,
  }) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response = await _networkManager.get(
        '/indoor-guide/progress',
        queryParameters: {
          'from': from,
          'to': to,
          'stepIndex': stepIndex,
        },
      );
      final data = response.data;
      if (data is Map && data['success'] == true && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data']);
      }
      return Map<String, dynamic>.from(data);
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
      final response =
          await _networkManager.post('/high-speed-rail/guide', data: {
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
      final response =
          await _networkManager.post('/transfer-time/start', data: {
        'from': from,
        'to': to,
        'remainingTime': remainingTime,
      });
      return Map<String, dynamic>.from(response.data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getTransferUpdate(
      String sessionId) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response =
          await _networkManager.get('/transfer-time/update/$sessionId');
      return Map<String, dynamic>.from(response.data);
    });
  }

  Future<ApiResponse<List<dynamic>>> getCommonRoutes(String userId) {
    return _handleApiCall<List<dynamic>>(() async {
      final response = await _networkManager.get('/common-routes/user/$userId');
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

  Future<ApiResponse<Map<String, dynamic>>> submitFeedback({
    required String type,
    required String description,
    String? contact,
  }) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response = await _networkManager.post('/feedback/submit', data: {
        'type': type,
        'description': description,
        'contact': contact ?? '',
      });
      return Map<String, dynamic>.from(response.data);
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
