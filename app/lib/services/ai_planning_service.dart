import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_travel_app/data/shanghai_metro_data.dart';

class AIPlanResult {
  final String title;
  final int totalTimeMinutes;
  final int transfers;
  final String summary;
  final List<AIPlanStep> steps;
  final List<String> tips;

  AIPlanResult({
    required this.title,
    required this.totalTimeMinutes,
    required this.transfers,
    required this.summary,
    required this.steps,
    required this.tips,
  });

  factory AIPlanResult.fromJson(Map<String, dynamic> json) {
    return AIPlanResult(
      title: json['title'] ?? 'AI智能规划路线',
      totalTimeMinutes: json['totalTimeMinutes'] ?? 0,
      transfers: json['transfers'] ?? 0,
      summary: json['summary'] ?? '',
      steps: (json['steps'] as List<dynamic>?)
              ?.map((s) => AIPlanStep.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      tips: (json['tips'] as List<dynamic>?)
              ?.map((t) => t.toString())
              .toList() ??
          [],
    );
  }
}

class AIPlanStep {
  final String type;
  final String line;
  final String description;
  final int timeMinutes;
  final int? stops;

  AIPlanStep({
    required this.type,
    required this.line,
    required this.description,
    required this.timeMinutes,
    this.stops,
  });

  factory AIPlanStep.fromJson(Map<String, dynamic> json) {
    return AIPlanStep(
      type: json['type'] ?? 'ride',
      line: json['line'] ?? '',
      description: json['description'] ?? '',
      timeMinutes: json['timeMinutes'] ?? 0,
      stops: json['stops'],
    );
  }
}

class AIPlanningService {
  static const String _apiKeyKey = 'ai_api_key';
  static const String _apiEndpointKey = 'ai_api_endpoint';
  static const String _modelKey = 'ai_model';

  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }

  static Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, key);
  }

  static Future<String> getApiEndpoint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiEndpointKey) ??
        'https://dashscope.aliyuncs.com/compatible-mode/v1';
  }

  static Future<void> setApiEndpoint(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiEndpointKey, endpoint);
  }

  static Future<String> getModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_modelKey) ?? 'qwen-plus';
  }

  static Future<void> setModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelKey, model);
  }

  static Future<AIPlanResult> planRoute({
    required String startStation,
    required String endStation,
    Map<String, dynamic>? preferences,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return _buildOfflinePlan(startStation, endStation, preferences);
    }

    final endpoint = await getApiEndpoint();
    final model = await getModel();

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ));

      final allLines = ShanghaiMetroData.getAllLines();
      final allStations = <String, Map<String, dynamic>>{};
      for (final line in allLines) {
        for (final station in line.stations) {
          if (!allStations.containsKey(station.name)) {
            allStations[station.name] = {
              'name': station.name,
              'lines': [line.lineId],
              'isTransfer': station.transferLines.isNotEmpty,
              'transferLines': station.transferLines,
            };
          } else {
            final existing = allStations[station.name]!;
            if (!(existing['lines'] as List).contains(line.lineId)) {
              (existing['lines'] as List).add(line.lineId);
            }
          }
        }
      }

      final linesInfo = allLines.map((l) => {
            'lineId': l.lineId,
            'lineName': l.lineName,
            'stations': l.stations.map((s) => s.name).toList(),
          }).toList();

      final systemPrompt = '''你是一个上海地铁智能规划助手。你需要根据用户提供的起终点和偏好，规划最优的地铁路线。

上海地铁共18条线路，线路数据如下：
${jsonEncode(linesInfo)}

换乘站信息：
${jsonEncode(allStations.values.where((s) => s['isTransfer'] == true).toList())}

请根据用户需求，返回最优路线规划。回复必须是严格JSON格式：
{
  "title": "路线标题",
  "totalTimeMinutes": 数字(分钟),
  "transfers": 数字(换乘次数),
  "summary": "路线摘要说明",
  "steps": [
    {"type": "ride", "line": "几号线", "description": "从XX到XX", "timeMinutes": 数字, "stops": 数字},
    {"type": "transfer", "line": "", "description": "在XX站换乘几号线", "timeMinutes": 5}
  ],
  "tips": ["出行建议1", "出行建议2"]
}''';

      final userMessage = '起点: $startStation, 终点: $endStation'
          '${preferences != null ? ', 偏好: ${jsonEncode(preferences)}' : ''}';

      final response = await dio.post(
        '$endpoint/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': 0.3,
          'max_tokens': 2000,
        },
      );

      final content =
          response.data['choices']?[0]?['message']?['content'] as String?;
      if (content == null) {
        return _buildOfflinePlan(startStation, endStation, preferences);
      }

      final jsonStr = _extractJson(content);
      final result = jsonDecode(jsonStr) as Map<String, dynamic>;
      return AIPlanResult.fromJson(result);
    } catch (e) {
      return _buildOfflinePlan(startStation, endStation, preferences);
    }
  }

  static String _extractJson(String content) {
    final startIdx = content.indexOf('{');
    final endIdx = content.lastIndexOf('}');
    if (startIdx >= 0 && endIdx > startIdx) {
      return content.substring(startIdx, endIdx + 1);
    }
    return content;
  }

  static AIPlanResult _buildOfflinePlan(
    String startStation,
    String endStation,
    Map<String, dynamic>? preferences,
  ) {
    final allLines = ShanghaiMetroData.getAllLines();

    MetroStation? start;
    MetroStation? end;
    for (final line in allLines) {
      for (final s in line.stations) {
        if (s.name == startStation && start == null) start = s;
        if (s.name == endStation && end == null) end = s;
      }
    }

    if (start == null || end == null) {
      return AIPlanResult(
        title: '规划失败',
        totalTimeMinutes: 0,
        transfers: 0,
        summary: '未找到匹配的站点信息，请检查站点名称',
        steps: [],
        tips: ['请确认站点名称是否正确', '可以尝试在地铁线路图上选择站点'],
      );
    }

    bool foundDirect = false;
    List<AIPlanStep> steps = [];
    int totalTime = 0;
    int transfers = 0;
    String routeTitle = '';

    for (final line in allLines) {
      final sIdx = line.stations.indexWhere((s) => s.name == startStation);
      final eIdx = line.stations.indexWhere((s) => s.name == endStation);
      if (sIdx >= 0 && eIdx >= 0) {
        final distance = (eIdx - sIdx).abs();
        totalTime = distance * 2 + 1;
        steps = [
          AIPlanStep(
            type: 'ride',
            line: line.lineName,
            description: '$startStation → $endStation',
            timeMinutes: totalTime,
            stops: distance,
          ),
        ];
        routeTitle = '${line.lineName}直达';
        foundDirect = true;
        break;
      }
    }

    if (!foundDirect) {
      List<String> startLines = [];
      List<String> endLines = [];
      for (final line in allLines) {
        if (line.stations.any((s) => s.name == startStation)) {
          startLines.add(line.lineId);
        }
        if (line.stations.any((s) => s.name == endStation)) {
          endLines.add(line.lineId);
        }
      }

      for (final sl in startLines) {
        for (final el in endLines) {
          if (sl == el) continue;
          final sLine = allLines.firstWhere((l) => l.lineId == sl);
          final eLine = allLines.firstWhere((l) => l.lineId == el);

          for (final transferStation in sLine.stations) {
            if (transferStation.transferLines.contains(el)) {
              final sIdx =
                  sLine.stations.indexWhere((s) => s.name == startStation);
              final tIdx = sLine.stations
                  .indexWhere((s) => s.name == transferStation.name);
              final endTIdx = eLine.stations
                  .indexWhere((s) => s.name == transferStation.name);
              final eIdx =
                  eLine.stations.indexWhere((s) => s.name == endStation);

              if (sIdx >= 0 && tIdx >= 0 && endTIdx >= 0 && eIdx >= 0) {
                final leg1 = (tIdx - sIdx).abs();
                final leg2 = (eIdx - endTIdx).abs();
                totalTime = leg1 * 2 + leg2 * 2 + 5;
                transfers = 1;
                steps = [
                  AIPlanStep(
                    type: 'ride',
                    line: sLine.lineName,
                    description:
                        '$startStation → ${transferStation.name}',
                    timeMinutes: leg1 * 2,
                    stops: leg1,
                  ),
                  AIPlanStep(
                    type: 'transfer',
                    line: '',
                    description:
                        '在${transferStation.name}换乘${eLine.lineName}',
                    timeMinutes: 5,
                  ),
                  AIPlanStep(
                    type: 'ride',
                    line: eLine.lineName,
                    description:
                        '${transferStation.name} → $endStation',
                    timeMinutes: leg2 * 2,
                    stops: leg2,
                  ),
                ];
                routeTitle =
                    '${sLine.lineName} → ${eLine.lineName}（${transferStation.name}换乘）';
                foundDirect = true;
                break;
              }
            }
          }
          if (foundDirect) break;
        }
        if (foundDirect) break;
      }
    }

    if (!foundDirect) {
      return AIPlanResult(
        title: '规划失败',
        totalTimeMinutes: 0,
        transfers: 0,
        summary: '未能找到$startStation到$endStation的可行路线',
        steps: [],
        tips: ['请尝试选择更近的站点', '或使用搜索功能确认站点名称'],
      );
    }

    return AIPlanResult(
      title: routeTitle,
      totalTimeMinutes: totalTime,
      transfers: transfers,
      summary: '从$startStation前往$endStation，${transfers > 0 ? "需换乘$transfers次" : "无需换乘"}，预计耗时$totalTime分钟',
      steps: steps,
      tips: [
        '请留意地铁末班车时间',
        '高峰期建议提前出发',
        '可使用手机扫码进站',
      ],
    );
  }
}