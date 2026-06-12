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

  String _friendlyDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
      return '服务暂时不可用，请稍后重试';
    }
    if (statusCode != null && statusCode >= 500) {
      return '服务器开小差了，请稍后重试';
    }
    if (statusCode == 404) {
      return '请求的内容不存在';
    }
    if (statusCode == 400) {
      return '请求参数不完整，请检查后重试';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return '网络请求超时，请稍后重试';
    }
    if (e.type == DioExceptionType.connectionError) {
      return '无法连接后端服务，请确认后端已启动';
    }
    return '网络请求失败，请稍后重试';
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

  Future<ApiResponse<List<dynamic>>> getStationExits(String stationId) {
    return _handleApiCall<List<dynamic>>(() async {
      final encodedStationId = Uri.encodeComponent(stationId);
      final response = await _networkManager
          .get('/subway-service/station/$encodedStationId/exits');
      final data = response.data;
      if (data is Map && data['success'] == true && data['exits'] is List) {
        return List<dynamic>.from(data['exits'] as List);
      }
      return _unwrapDataList(data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getNearestStation({
    required double latitude,
    required double longitude,
  }) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response = await _networkManager.get(
        '/location/nearest-station',
        queryParameters: {
          'lat': latitude,
          'lng': longitude,
        },
      );
      return _unwrapDataMap(response.data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> parseAssistantDestination(
    String text,
  ) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response = await _networkManager.post(
        '/assistant/parse-destination',
        data: {'text': text},
      );
      return _unwrapDataMap(response.data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> saveAssistantSession({
    String userId = 'default',
    String? rawText,
    required String parsedDestination,
    required String startStation,
    required String startEntrance,
    required String endStation,
    required String endExit,
  }) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response = await _networkManager.post(
        '/assistant/sessions',
        data: {
          'userId': userId,
          if (rawText != null && rawText.isNotEmpty) 'rawText': rawText,
          'parsedDestination': parsedDestination,
          'startStation': startStation,
          'startEntrance': startEntrance,
          'endStation': endStation,
          'endExit': endExit,
          'source': 'voice-assistant',
        },
      );
      return _unwrapDataMap(response.data);
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

  Future<ApiResponse<Map<String, dynamic>>> startTransferTimer({
    String fromStation = '',
    String toStation = '',
    String transferStation = '',
    int estimatedMinutes = 8,
    int walkingMinutes = 0,
    int waitingMinutes = 0,
  }) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response = await _networkManager.post(
        '/transfer-time/start',
        data: {
          'fromStation': fromStation,
          'toStation': toStation,
          'transferStation': transferStation,
          'estimatedMinutes': estimatedMinutes,
          'walkingMinutes': walkingMinutes,
          'waitingMinutes': waitingMinutes,
        },
      );
      return _unwrapDataMap(response.data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getTransferTimerUpdate(
    String sessionId,
  ) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final encodedSessionId = Uri.encodeComponent(sessionId);
      final response = await _networkManager.get(
        '/transfer-time/update/$encodedSessionId',
      );
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

  Future<ApiResponse<Map<String, dynamic>>> getDefaultConfig() {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final response = await _networkManager.get('/data/default-config');
      return _unwrapDataMap(response.data);
    });
  }

  Future<ApiResponse<List<dynamic>>> listStations({String? keyword}) {
    return _handleApiCall<List<dynamic>>(() async {
      final response = await _networkManager.get(
        '/data/stations',
        queryParameters: {
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        },
      );
      return _unwrapDataList(response.data);
    });
  }

  Future<ApiResponse<List<dynamic>>> listStationsByLine(String lineId) {
    return _handleApiCall<List<dynamic>>(() async {
      final encodedLineId = Uri.encodeComponent(lineId);
      final response =
          await _networkManager.get('/data/lines/$encodedLineId/stations');
      return _unwrapDataList(response.data);
    });
  }

  Future<ApiResponse<List<dynamic>>> searchTransferRules({
    String? keyword,
    String? originStationId,
    String? lineId,
  }) {
    return _handleApiCall<List<dynamic>>(() async {
      final response = await _networkManager.get(
        '/data/transfer-rules',
        queryParameters: {
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
          if (originStationId != null && originStationId.isNotEmpty)
            'originStationId': originStationId,
          if (lineId != null && lineId.isNotEmpty) 'lineId': lineId,
        },
      );
      return _unwrapDataList(response.data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getRoutePlanByRule(
      String ruleId) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final encodedRuleId = Uri.encodeComponent(ruleId);
      final response =
          await _networkManager.get('/data/route-plan/$encodedRuleId');
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

  Future<ApiResponse<Map<String, dynamic>>> deleteUserData(String userId) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final encodedUserId = Uri.encodeComponent(userId);
      final response = await _networkManager.delete('/users/$encodedUserId');
      return _unwrapDataMap(response.data);
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> anonymizeUserData(String userId) {
    return _handleApiCall<Map<String, dynamic>>(() async {
      final encodedUserId = Uri.encodeComponent(userId);
      final response =
          await _networkManager.post('/users/$encodedUserId/anonymize');
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
