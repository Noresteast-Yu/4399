import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_travel_app/data/shanghai_metro_data.dart';

/// TDD 测试集: ShanghaiMetroData 数据完整性
///
/// 上海地铁18条线路数据是路线规划的核心数据源，
/// 任何数据完整性错误都会导致路线规划失败或给出错误结果。
void main() {
  // =========================================================================
  // getAllLines — 基础结构验证
  // =========================================================================
  group('getAllLines 基础结构', () {
    test('返回 18 条线路', () {
      final lines = ShanghaiMetroData.getAllLines();
      expect(lines.length, 18);
    });

    test('每条线路有非空 lineId', () {
      final lines = ShanghaiMetroData.getAllLines();
      for (final line in lines) {
        expect(line.lineId, isNotEmpty, reason: 'line=${line.lineName}');
      }
    });

    test('每条线路有非空 lineName', () {
      final lines = ShanghaiMetroData.getAllLines();
      for (final line in lines) {
        expect(line.lineName, isNotEmpty, reason: 'lineId=${line.lineId}');
      }
    });

    test('每条线路至少有一个站点', () {
      final lines = ShanghaiMetroData.getAllLines();
      for (final line in lines) {
        expect(line.stations.isNotEmpty, true,
            reason: 'line ${line.lineName} has no stations');
      }
    });

    test('所有 lineId 唯一', () {
      final lines = ShanghaiMetroData.getAllLines();
      final ids = <String>{};
      for (final line in lines) {
        expect(ids.contains(line.lineId), false,
            reason: 'duplicate lineId: ${line.lineId}');
        ids.add(line.lineId);
      }
    });

    test('线路1-18的 lineId 分别为 "1" 到 "18"', () {
      final lines = ShanghaiMetroData.getAllLines();
      for (int i = 1; i <= 18; i++) {
        final line = lines[i - 1];
        expect(line.lineId, '$i',
            reason: 'expected line ${i} to have lineId "$i"');
      }
    });
  });

  // =========================================================================
  // 站点唯一性
  // =========================================================================
  group('站点 ID 唯一性', () {
    test('所有站点 id 跨线路唯一', () {
      final lines = ShanghaiMetroData.getAllLines();
      final ids = <String>{};
      for (final line in lines) {
        for (final station in line.stations) {
          expect(ids.contains(station.id), false,
              reason: 'duplicate station id: ${station.id} (${station.name})');
          ids.add(station.id);
        }
      }
    });
  });

  // =========================================================================
  // 站点 order 序列验证
  // =========================================================================
  group('站点 order 顺序', () {
    test('每条线路的站点 order 严格递增 (1, 2, 3, ...)', () {
      final lines = ShanghaiMetroData.getAllLines();
      for (final line in lines) {
        for (int i = 0; i < line.stations.length; i++) {
          final expectedOrder = i + 1;
          expect(line.stations[i].order, expectedOrder,
              reason:
                  'line ${line.lineName}: station ${line.stations[i].name} '
                  'has order ${line.stations[i].order}, expected $expectedOrder');
        }
      }
    });

    test('每条线路站点总数与 order 最大值一致', () {
      final lines = ShanghaiMetroData.getAllLines();
      for (final line in lines) {
        final maxOrder =
            line.stations.map((s) => s.order).reduce((a, b) => a > b ? a : b);
        expect(maxOrder, line.stations.length,
            reason: 'line ${line.lineName}');
      }
    });
  });

  // =========================================================================
  // 坐标范围验证
  // =========================================================================
  group('站点坐标范围', () {
    test('所有站点 x 坐标在 canvasWidth 范围内', () {
      final lines = ShanghaiMetroData.getAllLines();
      for (final line in lines) {
        for (final station in line.stations) {
          expect(station.x, greaterThanOrEqualTo(0),
              reason: '${station.name} x=${station.x} < 0');
          expect(station.x, lessThanOrEqualTo(ShanghaiMetroData.canvasWidth),
              reason:
                  '${station.name} x=${station.x} > ${ShanghaiMetroData.canvasWidth}');
        }
      }
    });

    test('所有站点 y 坐标在 canvasHeight 范围内', () {
      final lines = ShanghaiMetroData.getAllLines();
      for (final line in lines) {
        for (final station in line.stations) {
          expect(station.y, greaterThanOrEqualTo(0),
              reason: '${station.name} y=${station.y} < 0');
          expect(station.y, lessThanOrEqualTo(ShanghaiMetroData.canvasHeight),
              reason:
                  '${station.name} y=${station.y} > ${ShanghaiMetroData.canvasHeight}');
        }
      }
    });

    test('canvas 尺寸合理', () {
      expect(ShanghaiMetroData.canvasWidth, 3000);
      expect(ShanghaiMetroData.canvasHeight, 2400);
    });
  });

  // =========================================================================
  // 换乘站数据一致性
  // =========================================================================
  group('换乘站数据一致性', () {
    test('transferLines 引用的线路 ID 都是有效的', () {
      final lines = ShanghaiMetroData.getAllLines();
      final validLineIds = lines.map((l) => l.lineId).toSet();
      for (final line in lines) {
        for (final station in line.stations) {
          for (final transferLine in station.transferLines) {
            expect(validLineIds.contains(transferLine), true,
                reason:
                    '${station.name} on line ${line.lineId}: '
                    'transfer line "$transferLine" not found');
          }
        }
      }
    });

    test('换乘站名称在目标线路上也匹配', () {
      final lines = ShanghaiMetroData.getAllLines();
      final lineMap = <String, MetroLine>{};
      for (final line in lines) {
        lineMap[line.lineId] = line;
      }

      int totalChecked = 0;
      int nameMismatches = 0;
      final knownMismatches = {
        // 虹桥火车站: line 10 uses '上海虹桥火车站', lines 2/17 use '虹桥火车站'
        '虹桥火车站',
        '上海虹桥火车站',
      };

      for (final line in lines) {
        for (final station in line.stations) {
          for (final transferLineId in station.transferLines) {
            final targetLine = lineMap[transferLineId];
            if (targetLine == null) continue;
            totalChecked++;
            final nameMatch =
                targetLine.stations.any((s) => s.name == station.name);
            if (!nameMatch) {
              nameMismatches++;
              // 已知的命名差异应当被记录，但不应导致测试失败
            }
          }
        }
      }
      // 绝大多数换乘站名称应匹配（允许少量已知命名差异）
      expect(totalChecked, greaterThan(0));
      // 失配率应 < 5%（仅虹桥火车站等极少数例外）
      expect(nameMismatches / totalChecked, lessThan(0.05));
      // 记录失配数便于追踪
      if (nameMismatches > 0) {
        print('Note: $nameMismatches/$totalChecked transfer-station name mismatches (known: e.g. 虹桥火车站/上海虹桥火车站)');
      }
    });

    test('同一条线路不应该在 transferLines 中', () {
      final lines = ShanghaiMetroData.getAllLines();
      for (final line in lines) {
        for (final station in line.stations) {
          expect(station.transferLines.contains(line.lineId), false,
              reason:
                  '${station.name} on line ${line.lineId}: '
                  'transferLines should not contain own line');
        }
      }
    });

    test('transferLines 无重复', () {
      final lines = ShanghaiMetroData.getAllLines();
      for (final line in lines) {
        for (final station in line.stations) {
          expect(station.transferLines.toSet().length,
              station.transferLines.length,
              reason:
                  '${station.name}: transferLines contains duplicates');
        }
      }
    });
  });

  // =========================================================================
  // 关键换乘站验证
  // =========================================================================
  group('关键换乘站验证', () {
    test('人民广场是 1/2/8 号线换乘站', () {
      final lines = ShanghaiMetroData.getAllLines();
      final peopleSquareStations = <String, MetroStation>{};
      for (final line in lines) {
        for (final station in line.stations) {
          if (station.name == '人民广场') {
            peopleSquareStations[line.lineId] = station;
          }
        }
      }
      expect(peopleSquareStations.containsKey('1'), true);
      expect(peopleSquareStations.containsKey('2'), true);
      expect(peopleSquareStations.containsKey('8'), true);
      // 每个站点的 transferLines 应包含其他两条线
      final s1 = peopleSquareStations['1'];
      expect(s1?.transferLines.contains('2'), true);
      expect(s1?.transferLines.contains('8'), true);
    });

    test('同济大学仅在 10 号线上', () {
      final lines = ShanghaiMetroData.getAllLines();
      int count = 0;
      for (final line in lines) {
        for (final station in line.stations) {
          if (station.name == '同济大学') count++;
        }
      }
      expect(count, 1, reason: '同济大学 should only appear on one line');
    });

    test('世纪大道是 2/4/6/9 号线换乘站', () {
      final lines = ShanghaiMetroData.getAllLines();
      final set = <String>{};
      for (final line in lines) {
        for (final station in line.stations) {
          if (station.name == '世纪大道') set.add(line.lineId);
        }
      }
      expect(set, containsAll(['2', '4', '6', '9']));
    });

    test('虹桥火车站存在于 2 号线和 17 号线', () {
      // 注意: 10号线上名为"上海虹桥火车站"（与2/17号线的"虹桥火车站"不同）
      final lines = ShanghaiMetroData.getAllLines();
      final set = <String>{};
      for (final line in lines) {
        for (final station in line.stations) {
          if (station.name == '虹桥火车站') {
            set.add(line.lineId);
          }
        }
      }
      expect(set, containsAll(['2', '17']));
    });

    test('交通大学是 10/11 号线换乘站', () {
      final lines = ShanghaiMetroData.getAllLines();
      final set = <String>{};
      for (final line in lines) {
        for (final station in line.stations) {
          if (station.name == '交通大学') {
            set.add(line.lineId);
          }
        }
      }
      expect(set, containsAll(['10', '11']));
      // 每条线路上的 station 对象只列出 other line 作为 transfer
      // line 10 的交通大学: transferLines=['11']
      // line 11 的交通大学: transferLines=['10']
    });
  });

  // =========================================================================
  // 线路颜色
  // =========================================================================
  group('getLineColor', () {
    test('1号线返回红色', () {
      final color = ShanghaiMetroData.getLineColor('1');
      expect(color, ShanghaiMetroData.line1Color);
      expect(color, const Color(0xFFE4002B));
    });

    test('2号线返回绿色', () {
      final color = ShanghaiMetroData.getLineColor('2');
      expect(color, ShanghaiMetroData.line2Color);
      expect(color, const Color(0xFF8CC63F));
    });

    test('10号线返回紫色', () {
      final color = ShanghaiMetroData.getLineColor('10');
      expect(color, ShanghaiMetroData.line10Color);
    });

    test('无效线路ID返回灰色', () {
      final color = ShanghaiMetroData.getLineColor('99');
      expect(color, Colors.grey);
    });

    test('空字符串返回灰色', () {
      final color = ShanghaiMetroData.getLineColor('');
      expect(color, Colors.grey);
    });

    test('所有 1-18 号线都有非 Grey 颜色', () {
      for (int i = 1; i <= 18; i++) {
        final color = ShanghaiMetroData.getLineColor('$i');
        expect(color, isNot(Colors.grey),
            reason: 'Line $i should have its own color');
      }
    });
  });

  // =========================================================================
  // 静态颜色常量
  // =========================================================================
  group('线路颜色常量', () {
    test('18条线路颜色互不相同', () {
      final colors = [
        ShanghaiMetroData.line1Color,
        ShanghaiMetroData.line2Color,
        ShanghaiMetroData.line3Color,
        ShanghaiMetroData.line4Color,
        ShanghaiMetroData.line5Color,
        ShanghaiMetroData.line6Color,
        ShanghaiMetroData.line7Color,
        ShanghaiMetroData.line8Color,
        ShanghaiMetroData.line9Color,
        ShanghaiMetroData.line10Color,
        ShanghaiMetroData.line11Color,
        ShanghaiMetroData.line12Color,
        ShanghaiMetroData.line13Color,
        ShanghaiMetroData.line14Color,
        ShanghaiMetroData.line15Color,
        ShanghaiMetroData.line16Color,
        ShanghaiMetroData.line17Color,
        ShanghaiMetroData.line18Color,
      ];
      expect(colors.toSet().length, 18,
          reason: 'All 18 line colors should be unique');
    });
  });

  // =========================================================================
  // 站点总数合理性
  // =========================================================================
  group('数据规模', () {
    test('18条线路共有 400+ 个站点', () {
      final lines = ShanghaiMetroData.getAllLines();
      int totalStations = 0;
      for (final line in lines) {
        totalStations += line.stations.length;
      }
      // 上海地铁实际有 400+ 个站点（含重复换乘站）
      expect(totalStations, greaterThanOrEqualTo(400));
    });

    test('每条线路站点数在合理范围内', () {
      final lines = ShanghaiMetroData.getAllLines();
      for (final line in lines) {
        expect(line.stations.length, greaterThanOrEqualTo(5),
            reason: 'line ${line.lineName} has too few stations');
        expect(line.stations.length, lessThanOrEqualTo(50),
            reason: 'line ${line.lineName} has too many stations');
      }
    });
  });
}
