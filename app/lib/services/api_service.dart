import 'package:dio/dio.dart';
import '../utils/network_manager.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  final NetworkManager _networkManager = NetworkManager();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  Map<String, dynamic> _mapFromResponseData(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  Map<String, dynamic> _unwrapDataMap(dynamic data) {
    if (data is Map && data['success'] == true && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data']);
    }
    return _mapFromResponseData(data);
  }

  List<dynamic> _unwrapDataList(dynamic data) {
    if (data is Map && data['success'] == true && data['data'] is List) {
      return List<dynamic>.from(data['data']);
    }
    if (data is List) {
      return List<dynamic>.from(data);
    }
    return <dynamic>[];
  }

  Future<ApiResponse<T>> _handleApiCall<T>(Future<T> Function() call) async {
    try {
      final result = await call();
      return ApiResponse<T>(success: true, data: result);
    } on DioException catch (e) {
      return ApiResponse<T>(
        success: false,
        error: _friendlyDioError(e),
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
    String? startEntranceId,
    String? startEntranceName,
    String? endExitId,
    String? endExitName,
  }) async {
    try {
      final response = await _networkManager.post('/route-plan/plan', data: {
        'start': start,
        'end': end,
        if (preferences != null) 'preferences': preferences,
        if (startEntranceId != null && startEntranceId.isNotEmpty)
          'startEntranceId': startEntranceId,
        if (startEntranceName != null && startEntranceName.isNotEmpty)
          'startEntranceName': startEntranceName,
        if (endExitId != null && endExitId.isNotEmpty) 'endExitId': endExitId,
        if (endExitName != null && endExitName.isNotEmpty)
          'endExitName': endExitName,
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
      error: '后端路线规划服务不可用，请检查后端连接',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getStationInfo(String stationId) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response =
          await _networkManager.get('/subway-service/station/$stationId');
      return Map<String, dynamic>.from(response.data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getBackendHealth() {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response = await _networkManager.health();
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
      return _unwrapDataList(response.data);
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
    String? startEntranceId,
    String? startEntranceName,
    String? endExitId,
    String? endExitName,
  }) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response = await _networkManager.get(
        '/indoor-guide',
        queryParameters: {
          'from': from,
          'to': to,
          if (startEntranceId != null && startEntranceId.isNotEmpty)
            'startEntranceId': startEntranceId,
          if (startEntranceName != null && startEntranceName.isNotEmpty)
            'startEntranceName': startEntranceName,
          if (endExitId != null && endExitId.isNotEmpty) 'endExitId': endExitId,
          if (endExitName != null && endExitName.isNotEmpty)
            'endExitName': endExitName,
        },
      );
      return _unwrapDataMap(response.data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getIndoorGuideProgress({
    required String from,
    required String to,
    required int stepIndex,
    String? startEntranceId,
    String? startEntranceName,
    String? endExitId,
    String? endExitName,
  }) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response = await _networkManager.get(
        '/indoor-guide/progress',
        queryParameters: {
          'from': from,
          'to': to,
          'stepIndex': stepIndex,
          if (startEntranceId != null && startEntranceId.isNotEmpty)
            'startEntranceId': startEntranceId,
          if (startEntranceName != null && startEntranceName.isNotEmpty)
            'startEntranceName': startEntranceName,
          if (endExitId != null && endExitId.isNotEmpty) 'endExitId': endExitId,
          if (endExitName != null && endExitName.isNotEmpty)
            'endExitName': endExitName,
        },
      );
      return _unwrapDataMap(response.data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getIndoorStationTopology({
    String stationId = 'tongji_university',
  }) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response = await _networkManager.get(
        '/indoor-navigation/topology',
        queryParameters: {'stationId': stationId},
      );
      return _unwrapDataMap(response.data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getIndoorNavigationPath({
    String stationId = 'tongji_university',
    required String fromNodeId,
    String? toNodeId,
    String? targetType,
    String? targetId,
  }) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response = await _networkManager.get(
        '/indoor-navigation/path',
        queryParameters: {
          'stationId': stationId,
          'fromNodeId': fromNodeId,
          if (toNodeId != null && toNodeId.isNotEmpty) 'toNodeId': toNodeId,
          if (targetType != null && targetType.isNotEmpty)
            'targetType': targetType,
          if (targetId != null && targetId.isNotEmpty) 'targetId': targetId,
        },
      );
      return _unwrapDataMap(response.data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getTrainInfo(String trainNumber) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response =
          await _networkManager.get('/high-speed-rail/train/$trainNumber');
      return _unwrapDataMap(response.data);
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
      return _unwrapDataMap(response.data);
    });
  }

  Future<ApiResponse<List<dynamic>>> getCommonRoutes(String userId) {
    return _handleApiCall<List<dynamic>>(() async {
      final response = await _networkManager.get('/common-routes/user/$userId');
      return _unwrapDataList(response.data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> addCommonRoute({
    required String userId,
    required String start,
    required String end,
    String? time,
    String? distance,
  }) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response = await _networkManager.post('/common-routes/add', data: {
        'userId': userId,
        'start': start,
        'end': end,
        if (time != null) 'time': time,
        if (distance != null) 'distance': distance,
      });
      return _unwrapDataMap(response.data);
    });
  }

  Future<ApiResponse<String>> deleteCommonRoute(String routeId) {
    return _handleApiCall<String>(() async {
      await _networkManager.delete('/common-routes/$routeId');
      return '删除成功';
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> validateData() {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response = await _networkManager.get('/data/validate');
      return _unwrapDataMap(response.data);
    });
  }

  Future<ApiResponse<List<dynamic>>> getStaticResources({String? type}) {
    return _handleApiCall<List<dynamic>>(() async {
      final path = type == null
          ? '/data/static-resources'
          : '/data/static-resources?type=${Uri.encodeComponent(type)}';
      final response = await _networkManager.get(path);
      return _unwrapDataList(response.data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getUserPreferences(String userId) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final encodedUserId = Uri.encodeComponent(userId);
      final response =
          await _networkManager.get('/users/$encodedUserId/preferences');
      return _unwrapDataMap(response.data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> saveUserPreferences({
    required String userId,
    String themeColor = 'system',
    String themeMode = 'system',
    String fontSize = 'medium',
  }) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final encodedUserId = Uri.encodeComponent(userId);
      final response = await _networkManager.put(
        '/users/$encodedUserId/preferences',
        data: {
          'themeColor': themeColor,
          'themeMode': themeMode,
          'fontSize': fontSize,
        },
      );
      return _unwrapDataMap(response.data);
    });
  }

  Future<ApiResponse<List<dynamic>>> getUserAbilities(String userId) {
    return _handleApiCall<List<dynamic>>(() async {
      final encodedUserId = Uri.encodeComponent(userId);
      final response =
          await _networkManager.get('/users/$encodedUserId/abilities');
      return _unwrapDataList(response.data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> saveUserAbility({
    required String userId,
    required String abilityType,
    required int level,
    String description = '',
  }) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final encodedUserId = Uri.encodeComponent(userId);
      final encodedAbilityType = Uri.encodeComponent(abilityType);
      final response = await _networkManager.put(
        '/users/$encodedUserId/abilities/$encodedAbilityType',
        data: {
          'level': level,
          'description': description,
        },
      );
      return _unwrapDataMap(response.data);
    });
  }

  Future<ApiResponse<List<dynamic>>> getUserLuggage(String userId) {
    return _handleApiCall<List<dynamic>>(() async {
      final encodedUserId = Uri.encodeComponent(userId);
      final response =
          await _networkManager.get('/users/$encodedUserId/luggage');
      return _unwrapDataList(response.data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> saveUserLuggage({
    required String userId,
    required String luggageType,
    String weight = '',
    String size = '',
  }) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final encodedUserId = Uri.encodeComponent(userId);
      final encodedLuggageType = Uri.encodeComponent(luggageType);
      final response = await _networkManager.put(
        '/users/$encodedUserId/luggage/$encodedLuggageType',
        data: {
          'weight': weight,
          'size': size,
        },
      );
      return _unwrapDataMap(response.data);
    });
  }

  Future<ApiResponse<List<dynamic>>> getTravelAlerts({String? type}) {
    return _handleApiCall<List<dynamic>>(() async {
      final path = type != null ? '/travel-alerts/$type' : '/travel-alerts';
      final response = await _networkManager.get(path);
      return _unwrapDataList(response.data);
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
      return _unwrapDataMap(response.data);
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
