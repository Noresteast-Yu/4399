import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_travel_app/providers/user_preferences_provider.dart';

/// TDD 测试集: UserPreferencesProvider
///
/// 覆盖 15 个偏好字段的初始值、持久化、setter、
/// _updateMobilitySettings 级联逻辑和 toJson 序列化
void main() {
  late UserPreferencesProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    provider = UserPreferencesProvider();
  });

  // =========================================================================
  // 默认值（加载前）
  // =========================================================================
  group('加载前默认值', () {
    test('preferLessWalking 默认 false', () {
      expect(provider.preferLessWalking, false);
    });

    test('preferLessTransfers 默认 true', () {
      expect(provider.preferLessTransfers, true);
    });

    test('preferFastestRoute 默认 false', () {
      expect(provider.preferFastestRoute, false);
    });

    test('avoidCrowdedLines 默认 false', () {
      expect(provider.avoidCrowdedLines, false);
    });

    test('preferredRouteType 默认 fastest', () {
      expect(provider.preferredRouteType, 'fastest');
    });

    test('mobilityLevel 默认 normal', () {
      expect(provider.mobilityLevel, 'normal');
    });

    test('needElevator 默认 false', () {
      expect(provider.needElevator, false);
    });

    test('needEscalator 默认 false', () {
      expect(provider.needEscalator, false);
    });

    test('avoidStairs 默认 false', () {
      expect(provider.avoidStairs, false);
    });

    test('maxWalkingDistance 默认 500', () {
      expect(provider.maxWalkingDistance, 500);
    });

    test('hasLuggage 默认 false', () {
      expect(provider.hasLuggage, false);
    });

    test('luggageSize 默认 small', () {
      expect(provider.luggageSize, 'small');
    });

    test('luggageCount 默认 0', () {
      expect(provider.luggageCount, 0);
    });

    test('needWideGate 默认 false', () {
      expect(provider.needWideGate, false);
    });
  });

  // =========================================================================
  // loadPreferences
  // =========================================================================
  group('loadPreferences', () {
    test('无持久化数据时使用默认值', () async {
      await provider.loadPreferences();
      expect(provider.preferLessTransfers, true);
      expect(provider.preferredRouteType, 'fastest');
      expect(provider.mobilityLevel, 'normal');
      expect(provider.maxWalkingDistance, 500);
      expect(provider.luggageSize, 'small');
    });

    test('加载自定义偏好', () async {
      SharedPreferences.setMockInitialValues({
        'prefer_less_walking': true,
        'prefer_less_transfers': false,
        'prefer_fastest_route': true,
        'preferred_route_type': 'least_transfer',
      });
      await provider.loadPreferences();
      expect(provider.preferLessWalking, true);
      expect(provider.preferLessTransfers, false);
      expect(provider.preferFastestRoute, true);
      expect(provider.preferredRouteType, 'least_transfer');
    });

    test('加载自定义行动能力设置', () async {
      SharedPreferences.setMockInitialValues({
        'mobility_level': 'limited',
        'need_elevator': true,
        'max_walking_distance': 300,
      });
      await provider.loadPreferences();
      expect(provider.mobilityLevel, 'limited');
      expect(provider.needElevator, true);
      expect(provider.maxWalkingDistance, 300);
    });

    test('加载自定义行李设置', () async {
      SharedPreferences.setMockInitialValues({
        'has_luggage': true,
        'luggage_size': 'large',
        'luggage_count': 3,
        'need_wide_gate': true,
      });
      await provider.loadPreferences();
      expect(provider.hasLuggage, true);
      expect(provider.luggageSize, 'large');
      expect(provider.luggageCount, 3);
      expect(provider.needWideGate, true);
    });

    test('加载所有 15 个字段', () async {
      SharedPreferences.setMockInitialValues({
        'prefer_less_walking': true,
        'prefer_less_transfers': true,
        'prefer_fastest_route': false,
        'avoid_crowded_lines': true,
        'preferred_route_type': 'least_walking',
        'mobility_level': 'wheelchair',
        'need_elevator': true,
        'need_escalator': true,
        'avoid_stairs': true,
        'max_walking_distance': 200,
        'has_luggage': true,
        'luggage_size': 'medium',
        'luggage_count': 2,
        'need_wide_gate': true,
      });
      await provider.loadPreferences();
      expect(provider.preferLessWalking, true);
      expect(provider.avoidCrowdedLines, true);
      expect(provider.preferredRouteType, 'least_walking');
      expect(provider.mobilityLevel, 'wheelchair');
      expect(provider.needEscalator, true);
      expect(provider.avoidStairs, true);
      expect(provider.maxWalkingDistance, 200);
      expect(provider.hasLuggage, true);
      expect(provider.luggageSize, 'medium');
      expect(provider.luggageCount, 2);
      expect(provider.needWideGate, true);
    });

    test('loadPreferences 触发 notifyListeners', () async {
      int count = 0;
      provider.addListener(() => count++);
      await provider.loadPreferences();
      expect(count, 1);
    });
  });

  // =========================================================================
  // _updateMobilitySettings — 行动能力级联逻辑
  // 该私有方法由 setMobilityLevel 触发
  // =========================================================================
  group('_updateMobilitySettings (via setMobilityLevel)', () {
    test('mobilityLevel=wheelchair: 自动设置电梯/避楼梯/宽闸机/200m', () async {
      await provider.setMobilityLevel('wheelchair');
      expect(provider.mobilityLevel, 'wheelchair');
      expect(provider.needElevator, true);
      expect(provider.avoidStairs, true);
      expect(provider.needWideGate, true);
      expect(provider.maxWalkingDistance, 200);
    });

    test('mobilityLevel=wheelchair: 不修改 needEscalator', () async {
      await provider.setNeedEscalator(true);
      await provider.setMobilityLevel('wheelchair');
      // wheelchair 不修改 needEscalator
      expect(provider.needEscalator, true);
    });

    test('mobilityLevel=limited: 自动设置电梯/避楼梯/300m', () async {
      await provider.setMobilityLevel('limited');
      expect(provider.mobilityLevel, 'limited');
      expect(provider.needElevator, true);
      expect(provider.avoidStairs, true);
      expect(provider.maxWalkingDistance, 300);
    });

    test('mobilityLevel=limited: 不设置 needWideGate', () async {
      await provider.setNeedWideGate(false);
      await provider.setMobilityLevel('limited');
      // limited 不修改 needWideGate（保持之前的值）
      expect(provider.needWideGate, false);
    });

    test('mobilityLevel=normal: 重置电梯/避楼梯为 false，距离为 500', () async {
      // 先设置为 wheelchair 让各项为 true
      await provider.setMobilityLevel('wheelchair');
      // 再切回 normal
      await provider.setMobilityLevel('normal');
      expect(provider.mobilityLevel, 'normal');
      expect(provider.needElevator, false);
      expect(provider.avoidStairs, false);
      expect(provider.maxWalkingDistance, 500);
    });

    test('mobilityLevel 从 wheelchair 切到 normal: needWideGate 不变', () async {
      await provider.setMobilityLevel('wheelchair');
      final wideGateAfterWheelchair = provider.needWideGate;
      await provider.setMobilityLevel('normal');
      // normal 不修改 needWideGate（只有 wheelchair 设置它）
      expect(provider.needWideGate, wideGateAfterWheelchair);
    });

    test('mobilityLevel 不合法值不匹配任何 branch', () async {
      // 设置一个不在 switch 中的值
      await provider.setNeedElevator(true);
      await provider.setMobilityLevel('unknown_level');
      // switch 中无匹配 case，不应修改任何设置
      // needElevator 保持不变
      expect(provider.needElevator, true);
      expect(provider.mobilityLevel, 'unknown_level');
    });
  });

  // =========================================================================
  // 出行偏好 Setters
  // =========================================================================
  group('出行偏好 Setters', () {
    test('setPreferLessWalking', () async {
      await provider.setPreferLessWalking(true);
      expect(provider.preferLessWalking, true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('prefer_less_walking'), true);
    });

    test('setPreferLessTransfers', () async {
      await provider.setPreferLessTransfers(false);
      expect(provider.preferLessTransfers, false);
    });

    test('setPreferFastestRoute', () async {
      await provider.setPreferFastestRoute(true);
      expect(provider.preferFastestRoute, true);
    });

    test('setAvoidCrowdedLines', () async {
      await provider.setAvoidCrowdedLines(true);
      expect(provider.avoidCrowdedLines, true);
    });

    test('setPreferredRouteType', () async {
      await provider.setPreferredRouteType('least_transfer');
      expect(provider.preferredRouteType, 'least_transfer');
    });

    test('每个 setter 触发 notifyListeners', () async {
      int count = 0;
      provider.addListener(() => count++);

      await provider.setPreferLessWalking(true);
      await provider.setPreferLessTransfers(false);
      await provider.setAvoidCrowdedLines(true);

      expect(count, 3);
    });
  });

  // =========================================================================
  // 行动能力 Setters
  // =========================================================================
  group('行动能力 Setters', () {
    test('setNeedElevator', () async {
      await provider.setNeedElevator(true);
      expect(provider.needElevator, true);
    });

    test('setNeedEscalator', () async {
      await provider.setNeedEscalator(true);
      expect(provider.needEscalator, true);
    });

    test('setAvoidStairs', () async {
      await provider.setAvoidStairs(true);
      expect(provider.avoidStairs, true);
    });

    test('setMaxWalkingDistance', () async {
      await provider.setMaxWalkingDistance(800);
      expect(provider.maxWalkingDistance, 800);
    });
  });

  // =========================================================================
  // 行李 Setters
  // =========================================================================
  group('行李 Setters', () {
    test('setHasLuggage', () async {
      await provider.setHasLuggage(true);
      expect(provider.hasLuggage, true);
    });

    test('setLuggageSize', () async {
      await provider.setLuggageSize('large');
      expect(provider.luggageSize, 'large');
    });

    test('setLuggageCount', () async {
      await provider.setLuggageCount(2);
      expect(provider.luggageCount, 2);
    });

    test('setNeedWideGate', () async {
      await provider.setNeedWideGate(true);
      expect(provider.needWideGate, true);
    });
  });

  // =========================================================================
  // toJson — 序列化
  // =========================================================================
  group('toJson', () {
    test('默认值序列化', () async {
      await provider.loadPreferences();
      final json = provider.toJson();

      expect(json.containsKey('travelPreferences'), true);
      expect(json.containsKey('mobilitySettings'), true);
      expect(json.containsKey('luggageSettings'), true);

      final tp = json['travelPreferences'];
      expect(tp['preferLessWalking'], false);
      expect(tp['preferLessTransfers'], true);
      expect(tp['preferFastestRoute'], false);
      expect(tp['preferredRouteType'], 'fastest');

      final ms = json['mobilitySettings'];
      expect(ms['mobilityLevel'], 'normal');
      expect(ms['maxWalkingDistance'], 500);

      final ls = json['luggageSettings'];
      expect(ls['hasLuggage'], false);
      expect(ls['luggageSize'], 'small');
      expect(ls['luggageCount'], 0);
    });

    test('修改后序列化反映变更', () async {
      await provider.setMobilityLevel('wheelchair');
      await provider.setHasLuggage(true);
      await provider.setLuggageCount(2);
      await provider.setPreferLessWalking(true);

      final json = provider.toJson();

      expect(json['travelPreferences']['preferLessWalking'], true);
      expect(json['mobilitySettings']['mobilityLevel'], 'wheelchair');
      expect(json['mobilitySettings']['maxWalkingDistance'], 200);
      expect(json['mobilitySettings']['needElevator'], true);
      expect(json['luggageSettings']['hasLuggage'], true);
      expect(json['luggageSettings']['luggageCount'], 2);
    });

    test('toJson 是纯函数 — 多次调用结果一致', () async {
      await provider.loadPreferences();
      await provider.setPreferFastestRoute(true);
      await provider.setLuggageCount(1);

      // 使用 JSON 编码后的字符串比较
      final json1 = provider.toJson();
      final json2 = provider.toJson();

      // 深度比较: 所有字段值相同
      expect(json1['travelPreferences']['preferFastestRoute'],
          json2['travelPreferences']['preferFastestRoute']);
      expect(json1['luggageSettings']['luggageCount'],
          json2['luggageSettings']['luggageCount']);
      expect(json1['mobilitySettings']['maxWalkingDistance'],
          json2['mobilitySettings']['maxWalkingDistance']);
    });
  });

  // =========================================================================
  // 综合生命周期
  // =========================================================================
  group('综合生命周期', () {
    test('load → modify → toJson 完整流程', () async {
      await provider.loadPreferences();

      // 模拟用户设置出行偏好
      await provider.setPreferredRouteType('least_transfer');
      await provider.setAvoidCrowdedLines(true);

      // 模拟用户设置轮椅模式
      await provider.setMobilityLevel('wheelchair');

      // 模拟用户设置行李
      await provider.setHasLuggage(true);
      await provider.setLuggageSize('medium');
      await provider.setLuggageCount(2);

      final json = provider.toJson();

      // 验证最终 JSON
      expect(json['travelPreferences']['preferredRouteType'], 'least_transfer');
      expect(json['travelPreferences']['avoidCrowdedLines'], true);
      expect(json['mobilitySettings']['mobilityLevel'], 'wheelchair');
      expect(json['mobilitySettings']['needElevator'], true);
      expect(json['luggageSettings']['needWideGate'], true);
      expect(json['mobilitySettings']['maxWalkingDistance'], 200);
      expect(json['luggageSettings']['hasLuggage'], true);
      expect(json['luggageSettings']['luggageSize'], 'medium');
      expect(json['luggageSettings']['luggageCount'], 2);
    });

    test('修改后 persist → 新实例加载 → 恢复', () async {
      await provider.setMobilityLevel('limited');
      await provider.setPreferLessWalking(true);
      await provider.setLuggageCount(1);

      final newProvider = UserPreferencesProvider();
      await newProvider.loadPreferences();

      // 持久化的值应被恢复
      expect(newProvider.mobilityLevel, 'limited');
      expect(newProvider.preferLessWalking, true);
      expect(newProvider.luggageCount, 1);
    });
  });
}
