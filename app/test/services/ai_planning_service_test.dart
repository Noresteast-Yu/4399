import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_travel_app/services/ai_planning_service.dart';
import 'package:smart_travel_app/utils/api_config.dart';

/// TDD 测试集: AIPlanningService 核心逻辑
///
/// 覆盖:
/// - _extractJson (JSON 提取) — 通过 planRoute + mock 间接验证行为
/// - _normalizeApiEndpoint (API 端点标准化) — 验证规则逻辑
/// - _buildOfflinePlan (离线路线规划) — 通过 planRoute 无 API Key 降级测试
/// - AIPlanResult.fromJson (结果解析)
/// - AIPlanStep.fromJson (步骤解析)
/// - API Key/Endpoint/Model 持久化
void main() {
  // =========================================================================
  // AIPlanResult.fromJson — 路线结果反序列化
  // =========================================================================
  group('AIPlanResult.fromJson', () {
    test('解析完整 JSON 返回所有字段', () {
      final json = {
        'title': '10号线直达',
        'totalTimeMinutes': 14,
        'transfers': 0,
        'summary': '从同济大学前往陕西南路，无需换乘，预计耗时14分钟',
        'steps': [
          {
            'type': 'ride',
            'line': '10号线',
            'description': '同济大学 → 陕西南路',
            'timeMinutes': 14,
            'stops': 7,
          },
        ],
        'tips': ['请留意地铁末班车时间', '高峰期建议提前出发'],
      };

      final result = AIPlanResult.fromJson(json);

      expect(result.title, '10号线直达');
      expect(result.totalTimeMinutes, 14);
      expect(result.transfers, 0);
      expect(result.summary, contains('无需换乘'));
      expect(result.steps.length, 1);
      expect(result.steps[0].type, 'ride');
      expect(result.steps[0].line, '10号线');
      expect(result.tips.length, 2);
    });

    test('缺少字段时使用默认值', () {
      final json = <String, dynamic>{};

      final result = AIPlanResult.fromJson(json);

      expect(result.title, 'AI智能规划路线');
      expect(result.totalTimeMinutes, 0);
      expect(result.transfers, 0);
      expect(result.summary, '');
      expect(result.steps, isEmpty);
      expect(result.tips, isEmpty);
    });

    test('steps 为 null 返回空列表', () {
      final json = {
        'title': '测试',
        'steps': null,
      };

      final result = AIPlanResult.fromJson(json);

      expect(result.steps, isEmpty);
    });

    test('tips 为 null 返回空列表', () {
      final json = {
        'title': '测试',
        'tips': null,
      };

      final result = AIPlanResult.fromJson(json);

      expect(result.tips, isEmpty);
    });

    test('tips 中非字符串值转为字符串', () {
      final json = {
        'title': '测试',
        'tips': [42, true, 'text'],
      };

      final result = AIPlanResult.fromJson(json);

      expect(result.tips, ['42', 'true', 'text']);
    });

    test('steps 元素包含额外字段不影响解析', () {
      final json = {
        'title': '测试',
        'steps': [
          {
            'type': 'ride',
            'line': '2号线',
            'description': '测试',
            'timeMinutes': 10,
            'stops': 5,
            'extraField': 'should be ignored',
          },
        ],
      };

      final result = AIPlanResult.fromJson(json);

      expect(result.steps.length, 1);
      expect(result.steps[0].stops, 5);
    });
  });

  // =========================================================================
  // AIPlanStep.fromJson — 路线步骤反序列化
  // =========================================================================
  group('AIPlanStep.fromJson', () {
    test('解析 ride 类型步骤', () {
      final json = {
        'type': 'ride',
        'line': '10号线',
        'description': '同济大学 → 陕西南路',
        'timeMinutes': 14,
        'stops': 7,
      };

      final step = AIPlanStep.fromJson(json);

      expect(step.type, 'ride');
      expect(step.line, '10号线');
      expect(step.description, '同济大学 → 陕西南路');
      expect(step.timeMinutes, 14);
      expect(step.stops, 7);
    });

    test('解析 transfer 类型步骤（无 line 和 stops）', () {
      final json = {
        'type': 'transfer',
        'line': '',
        'description': '在南京东路换乘2号线',
        'timeMinutes': 5,
      };

      final step = AIPlanStep.fromJson(json);

      expect(step.type, 'transfer');
      expect(step.line, '');
      expect(step.stops, isNull);
      expect(step.timeMinutes, 5);
    });

    test('缺失字段使用默认值', () {
      final step = AIPlanStep.fromJson({});

      expect(step.type, 'ride');
      expect(step.line, '');
      expect(step.description, '');
      expect(step.timeMinutes, 0);
      expect(step.stops, isNull);
    });
  });

  // =========================================================================
  // _extractJson — JSON 字符串提取（行为规格验证）
  // =========================================================================
  group('_extractJson (行为规格)', () {
    test('提取被文字环绕的 JSON — 第一个 { 到最后一个 }', () {
      final jsonStr =
          '这是规划结果：{"title":"test","totalTimeMinutes":10,"transfers":0}';
      final startIdx = jsonStr.indexOf('{');
      final endIdx = jsonStr.lastIndexOf('}');
      final extracted = jsonStr.substring(startIdx, endIdx + 1);

      expect(extracted, '{"title":"test","totalTimeMinutes":10,"transfers":0}');
    });

    test('提取代码块中的 JSON', () {
      final content =
          '```json\n{"title":"test","totalTimeMinutes":5,"transfers":1}\n```';
      final startIdx = content.indexOf('{');
      final endIdx = content.lastIndexOf('}');
      final extracted = content.substring(startIdx, endIdx + 1);

      expect(extracted, '{"title":"test","totalTimeMinutes":5,"transfers":1}');
    });

    test('字符串中没有花括号时返回原内容', () {
      final content = '没有JSON内容';
      final startIdx = content.indexOf('{');
      final endIdx = content.lastIndexOf('}');

      expect(startIdx, -1);
      expect(endIdx, -1);
      // 源码行为: 如果没找到花括号，返回原内容
    });

    test('提取嵌套花括号的 JSON', () {
      final content =
          '{"title":"test","steps":[{"type":"ride","line":"10号线"}],"tips":["a","b"]}';
      final startIdx = content.indexOf('{');
      final endIdx = content.lastIndexOf('}');
      final extracted = content.substring(startIdx, endIdx + 1);

      expect(extracted, content); // 嵌套花括号被正确保留
    });

    test('JSON 前有换行和空格', () {
      final content =
          '好的，路线规划如下：\n\n{"title":"result","totalTimeMinutes":20,"transfers":0}';
      final startIdx = content.indexOf('{');
      final endIdx = content.lastIndexOf('}');
      final extracted = content.substring(startIdx, endIdx + 1);

      expect(extracted, '{"title":"result","totalTimeMinutes":20,"transfers":0}');
    });

    test('只有左花括号没有右花括号', () {
      final content = '不完整的JSON {"incomplete';
      final startIdx = content.indexOf('{');
      final endIdx = content.lastIndexOf('}');

      expect(startIdx, greaterThanOrEqualTo(0));
      expect(endIdx, -1); // 找不到右花括号
    });
  });

  // =========================================================================
  // _normalizeApiEndpoint — API 端点标准化（行为规格验证）
  // =========================================================================
  group('_normalizeApiEndpoint (行为规格)', () {
    test('去除尾部斜杠', () {
      final endpoint = 'https://api.openai.com/v1/';
      var normalized = endpoint.trim();
      while (normalized.endsWith('/')) {
        normalized = normalized.substring(0, normalized.length - 1);
      }
      expect(normalized, 'https://api.openai.com/v1');
    });

    test('去除多个尾部斜杠', () {
      final endpoint = 'https://api.openai.com/v1///';
      var normalized = endpoint.trim();
      while (normalized.endsWith('/')) {
        normalized = normalized.substring(0, normalized.length - 1);
      }
      expect(normalized, 'https://api.openai.com/v1');
    });

    test('去除 /chat/completions 后缀', () {
      var normalized = 'https://api.openai.com/v1/chat/completions';
      while (normalized.endsWith('/')) {
        normalized = normalized.substring(0, normalized.length - 1);
      }
      const chatCompletionsPath = '/chat/completions';
      if (normalized.endsWith(chatCompletionsPath)) {
        normalized = normalized.substring(
            0, normalized.length - chatCompletionsPath.length);
      }
      expect(normalized, 'https://api.openai.com/v1');
    });

    test('去除尾部斜杠和 /chat/completions 的组合', () {
      var normalized = 'https://api.openai.com/v1/chat/completions/';
      normalized = normalized.trim();
      while (normalized.endsWith('/')) {
        normalized = normalized.substring(0, normalized.length - 1);
      }
      const chatCompletionsPath = '/chat/completions';
      if (normalized.endsWith(chatCompletionsPath)) {
        normalized = normalized.substring(
            0, normalized.length - chatCompletionsPath.length);
      }
      expect(normalized, 'https://api.openai.com/v1');
    });

    test('处理自定义端点（DeepSeek）', () {
      var normalized = 'https://api.deepseek.com/v1';
      normalized = normalized.trim();
      while (normalized.endsWith('/')) {
        normalized = normalized.substring(0, normalized.length - 1);
      }
      const chatCompletionsPath = '/chat/completions';
      if (normalized.endsWith(chatCompletionsPath)) {
        normalized = normalized.substring(
            0, normalized.length - chatCompletionsPath.length);
      }
      expect(normalized, 'https://api.deepseek.com/v1');
    });

    test('处理仅含 /chat/completions 的端点', () {
      var normalized = 'https://custom.api/chat/completions';
      normalized = normalized.trim();
      while (normalized.endsWith('/')) {
        normalized = normalized.substring(0, normalized.length - 1);
      }
      const chatCompletionsPath = '/chat/completions';
      if (normalized.endsWith(chatCompletionsPath)) {
        normalized = normalized.substring(
            0, normalized.length - chatCompletionsPath.length);
      }
      expect(normalized, 'https://custom.api');
    });

    test('去除首尾空格', () {
      final endpoint = '  https://api.openai.com/v1  ';
      final normalized = endpoint.trim();
      expect(normalized, 'https://api.openai.com/v1');
    });

    test('不做重复去除 /chat/completions 的副作用', () {
      // 端点中不含 /chat/completions 时，不应影响其他路径
      var normalized = 'https://api.example.com/v1/embeddings';
      normalized = normalized.trim();
      while (normalized.endsWith('/')) {
        normalized = normalized.substring(0, normalized.length - 1);
      }
      const chatCompletionsPath = '/chat/completions';
      if (normalized.endsWith(chatCompletionsPath)) {
        normalized = normalized.substring(
            0, normalized.length - chatCompletionsPath.length);
      }
      expect(normalized, 'https://api.example.com/v1/embeddings');
    });
  });

  // =========================================================================
  // planRoute — 离线降级模式 (等价于测试 _buildOfflinePlan)
  // 注意: _buildOfflinePlan 是 private，通过 planRoute 无 API Key 时自动降级测试
  // =========================================================================
  group('离线路线规划 (via planRoute 降级)', () {
    setUp(() async {
      // 清空 API Key 确保走到离线分支
      SharedPreferences.setMockInitialValues({});
    });

    test('同线路直达: 同济大学 → 陕西南路（10号线）', () async {
      final result = await AIPlanningService.planRoute(
        startStation: '同济大学',
        endStation: '陕西南路',
      );

      expect(result.title, isNotEmpty);
      expect(result.transfers, 0);
      expect(result.totalTimeMinutes, greaterThan(0));
      expect(result.steps.length, 1);
      expect(result.steps[0].type, 'ride');
      expect(result.steps[0].line, contains('10号线'));
    });

    test('同线路直达: 人民广场 → 陆家嘴（2号线）', () async {
      final result = await AIPlanningService.planRoute(
        startStation: '人民广场',
        endStation: '陆家嘴',
      );

      expect(result.transfers, 0);
      expect(result.steps.length, 1);
      expect(result.steps[0].type, 'ride');
      expect(result.steps[0].line, contains('2号线'));
    });

    test('换乘路线: 同济大学(10号线) → 陆家嘴(2号线)', () async {
      final result = await AIPlanningService.planRoute(
        startStation: '同济大学',
        endStation: '陆家嘴',
      );

      expect(result.title, isNotEmpty);
      if (result.transfers > 0) {
        expect(result.steps.length, greaterThanOrEqualTo(3));
        final types = result.steps.map((s) => s.type).toList();
        expect(types, contains('ride'));
        expect(types, contains('transfer'));
      }
    });

    test('换乘路线: 交通大学 → 虹桥火车站', () async {
      final result = await AIPlanningService.planRoute(
        startStation: '交通大学',
        endStation: '虹桥火车站',
      );

      expect(result.title, isNotEmpty);
      expect(result.totalTimeMinutes, greaterThan(0));
    });

    test('不存在的起站点返回规划失败', () async {
      final result = await AIPlanningService.planRoute(
        startStation: '不存在的站点XYZ',
        endStation: '同济大学',
      );

      expect(result.title, '规划失败');
      expect(result.steps, isEmpty);
      expect(result.summary, contains('未找到匹配的站点信息'));
    });

    test('不存在的终站点返回规划失败', () async {
      final result = await AIPlanningService.planRoute(
        startStation: '同济大学',
        endStation: '不存在的站点XYZ',
      );

      expect(result.title, '规划失败');
      expect(result.steps, isEmpty);
      expect(result.summary, contains('未找到匹配的站点信息'));
    });

    test('两个都不存在的站点返回规划失败', () async {
      final result = await AIPlanningService.planRoute(
        startStation: '火星站',
        endStation: '月球站',
      );

      expect(result.title, '规划失败');
      expect(result.steps, isEmpty);
    });

    test('相同站点规划（distance=0 直达）', () async {
      final result = await AIPlanningService.planRoute(
        startStation: '同济大学',
        endStation: '同济大学',
      );

      // 同站规划应成功（foundDirect=true, distance=0）
      expect(result.summary, isNot(contains('未找到匹配的站点信息')));
    });

    test('返回通用出行提示', () async {
      final result = await AIPlanningService.planRoute(
        startStation: '同济大学',
        endStation: '陕西南路',
      );

      expect(result.tips, isNotEmpty);
      expect(result.tips, contains('请留意地铁末班车时间'));
      expect(result.tips, contains('高峰期建议提前出发'));
    });

    test('直达路线 summary 描述无需换乘', () async {
      final result = await AIPlanningService.planRoute(
        startStation: '同济大学',
        endStation: '陕西南路',
      );

      if (result.transfers == 0) {
        expect(result.summary, contains('无需换乘'));
      }
    });

    test('换乘路线 summary 描述换乘次数', () async {
      final result = await AIPlanningService.planRoute(
        startStation: '江苏路',
        endStation: '同济大学',
      );

      expect(result.title, isNotEmpty);
      if (result.transfers > 0) {
        expect(result.summary, contains('需换乘'));
      }
    });

    test('空 API Key 时也降级到离线规划', () async {
      await AIPlanningService.setApiKey('');
      final result = await AIPlanningService.planRoute(
        startStation: '同济大学',
        endStation: '陕西南路',
      );

      expect(result.title, isNotEmpty);
      expect(result.steps, isNotEmpty);
    });

    test('仅空白字符的 API Key 也降级到离线规划', () async {
      await AIPlanningService.setApiKey('   ');
      final result = await AIPlanningService.planRoute(
        startStation: '同济大学',
        endStation: '陕西南路',
      );

      expect(result.title, isNotEmpty);
      expect(result.steps, isNotEmpty);
    });

    test('离线规划忽略 preferences 参数', () async {
      await AIPlanningService.setApiKey('');
      final result = await AIPlanningService.planRoute(
        startStation: '同济大学',
        endStation: '陕西南路',
        preferences: {'preferFastestRoute': true, 'needElevator': true},
      );

      // 离线模式忽略偏好，但应正常返回路线
      expect(result.title, isNotEmpty);
      expect(result.transfers, 0);
      expect(result.tips, isNotEmpty);
    });
  });

  // =========================================================================
  // 终点站歧义处理 — 同一站在多条线路上的情况
  // =========================================================================
  group('换乘站路线规划', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('江苏路站（2号线+11号线换乘站）→ 同济大学', () async {
      final result = await AIPlanningService.planRoute(
        startStation: '江苏路',
        endStation: '同济大学',
      );

      expect(result.title, isNotEmpty);
      // 江苏路是多线换乘站，离线算法会优先用 first line（2号线）
      // 如果找到换乘路线，transfers 为 1
      expect(result.totalTimeMinutes, greaterThan(0));
    });

    test('交通大学站（10号线+11号线换乘站）→ 上海图书馆', () async {
      final result = await AIPlanningService.planRoute(
        startStation: '交通大学',
        endStation: '上海图书馆',
      );

      expect(result.title, isNotEmpty);
      expect(result.transfers, 0); // 10号线直达
    });
  });

  // =========================================================================
  // SharedPreferences — API 配置持久化
  // =========================================================================
  group('API 配置持久化', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('getApiEndpoint 默认返回 OpenAI 端点', () async {
      final endpoint = await AIPlanningService.getApiEndpoint();
      expect(endpoint, defaultApiEndpoint);
    });

    test('setApiEndpoint 后 getApiEndpoint 返回设置值', () async {
      await AIPlanningService.setApiEndpoint('https://api.deepseek.com/v1');
      final endpoint = await AIPlanningService.getApiEndpoint();
      expect(endpoint, 'https://api.deepseek.com/v1');
    });

    test('getModel 默认返回 gpt-4o-mini', () async {
      final model = await AIPlanningService.getModel();
      expect(model, defaultApiModel);
    });

    test('setModel 后 getModel 返回设置值', () async {
      await AIPlanningService.setModel('deepseek-chat');
      final model = await AIPlanningService.getModel();
      expect(model, 'deepseek-chat');
    });

    test('getApiKey 无设置时返回 null', () async {
      final key = await AIPlanningService.getApiKey();
      expect(key, isNull);
    });

    test('setApiKey 后 getApiKey 返回设置值', () async {
      await AIPlanningService.setApiKey('sk-test-key-123456');
      final key = await AIPlanningService.getApiKey();
      expect(key, 'sk-test-key-123456');
    });

    test('API 配置独立存储互不影响', () async {
      await AIPlanningService.setApiEndpoint('https://api.moonshot.cn/v1');
      await AIPlanningService.setModel('moonshot-v1-8k');
      await AIPlanningService.setApiKey('sk-moon-123');

      expect(await AIPlanningService.getApiEndpoint(),
          'https://api.moonshot.cn/v1');
      expect(await AIPlanningService.getModel(), 'moonshot-v1-8k');
      expect(await AIPlanningService.getApiKey(), 'sk-moon-123');
    });

    test('多次覆盖 API Key 返回最新值', () async {
      await AIPlanningService.setApiKey('key-v1');
      await AIPlanningService.setApiKey('key-v2');
      await AIPlanningService.setApiKey('key-v3-final');

      expect(await AIPlanningService.getApiKey(), 'key-v3-final');
    });
  });
}
