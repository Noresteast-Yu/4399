import 'package:flutter_test/flutter_test.dart';
import 'package:smart_travel_app/providers/app_provider.dart';

/// TDD 测试集: AppProvider
///
/// 简单 ChangeNotifier，验证状态初始值、setter 行为和 notifyListeners
void main() {
  late AppProvider provider;

  setUp(() {
    provider = AppProvider();
  });

  // =========================================================================
  // 默认值
  // =========================================================================
  group('默认值', () {
    test('isDarkMode 默认 false', () {
      expect(provider.isDarkMode, false);
    });

    test('fontSize 默认 16', () {
      expect(provider.fontSize, 16);
    });

    test('walkingSpeed 默认 4.0', () {
      expect(provider.walkingSpeed, 4.0);
    });

    test('luggageCount 默认 0', () {
      expect(provider.luggageCount, 0);
    });
  });

  // =========================================================================
  // toggleDarkMode
  // =========================================================================
  group('toggleDarkMode', () {
    test('切换一次变为 true', () {
      provider.toggleDarkMode();
      expect(provider.isDarkMode, true);
    });

    test('切换两次回到 false', () {
      provider.toggleDarkMode();
      provider.toggleDarkMode();
      expect(provider.isDarkMode, false);
    });

    test('切换奇数次为 true', () {
      for (int i = 0; i < 5; i++) {
        provider.toggleDarkMode();
      }
      expect(provider.isDarkMode, true);
    });

    test('切换偶数次回到 false', () {
      for (int i = 0; i < 10; i++) {
        provider.toggleDarkMode();
      }
      expect(provider.isDarkMode, false);
    });

    test('每次切换触发 notifyListeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.toggleDarkMode();
      provider.toggleDarkMode();
      provider.toggleDarkMode();

      expect(notifyCount, 3);
    });
  });

  // =========================================================================
  // setFontSize
  // =========================================================================
  group('setFontSize', () {
    test('设置正值', () {
      provider.setFontSize(20);
      expect(provider.fontSize, 20);
    });

    test('设置 0', () {
      provider.setFontSize(0);
      expect(provider.fontSize, 0);
    });

    test('设置负值（边界）', () {
      provider.setFontSize(-5);
      expect(provider.fontSize, -5);
    });

    test('设置大值', () {
      provider.setFontSize(72);
      expect(provider.fontSize, 72);
    });

    test('触发 notifyListeners', () {
      int count = 0;
      provider.addListener(() => count++);
      provider.setFontSize(18);
      expect(count, 1);
    });
  });

  // =========================================================================
  // setWalkingSpeed
  // =========================================================================
  group('setWalkingSpeed', () {
    test('设置正常速度', () {
      provider.setWalkingSpeed(5.0);
      expect(provider.walkingSpeed, 5.0);
    });

    test('设置 0', () {
      provider.setWalkingSpeed(0);
      expect(provider.walkingSpeed, 0);
    });

    test('设置小数', () {
      provider.setWalkingSpeed(3.7);
      expect(provider.walkingSpeed, 3.7);
    });

    test('触发 notifyListeners', () {
      int count = 0;
      provider.addListener(() => count++);
      provider.setWalkingSpeed(6.0);
      expect(count, 1);
    });
  });

  // =========================================================================
  // setLuggageCount
  // =========================================================================
  group('setLuggageCount', () {
    test('设置正整数', () {
      provider.setLuggageCount(3);
      expect(provider.luggageCount, 3);
    });

    test('设置 0', () {
      provider.setLuggageCount(0);
      expect(provider.luggageCount, 0);
    });

    test('设置负值', () {
      provider.setLuggageCount(-1);
      expect(provider.luggageCount, -1);
    });

    test('覆盖之前的值', () {
      provider.setLuggageCount(5);
      provider.setLuggageCount(2);
      expect(provider.luggageCount, 2);
    });

    test('触发 notifyListeners', () {
      int count = 0;
      provider.addListener(() => count++);
      provider.setLuggageCount(1);
      expect(count, 1);
    });
  });

  // =========================================================================
  // 综合
  // =========================================================================
  group('综合状态', () {
    test('所有 setters 独立工作互不干扰', () {
      provider.toggleDarkMode();       // true
      provider.setFontSize(24);        // 24
      provider.setWalkingSpeed(3.5);   // 3.5
      provider.setLuggageCount(2);     // 2

      expect(provider.isDarkMode, true);
      expect(provider.fontSize, 24);
      expect(provider.walkingSpeed, 3.5);
      expect(provider.luggageCount, 2);
    });
  });
}
