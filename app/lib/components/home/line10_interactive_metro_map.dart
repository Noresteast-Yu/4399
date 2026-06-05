import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smart_travel_app/theme/app_theme.dart';

class Line10MapStation {
  final String id;
  final String name;
  final Offset position;
  final List<String> transferLines;
  final bool keyStation;

  const Line10MapStation({
    required this.id,
    required this.name,
    required this.position,
    this.transferLines = const [],
    this.keyStation = false,
  });
}

class _TransferStop {
  final String name;
  final Offset position;

  const _TransferStop(this.name, this.position);
}

class Line10InteractiveMetroMap extends StatefulWidget {
  final String selectedStationId;
  final ValueChanged<Line10MapStation> onStationSelected;
  final VoidCallback? onMapInteraction;
  final double height;
  final bool immersive;
  final bool showControls;
  final bool showHint;
  final double controlsBottomOffset;
  final double labelBottomInset;

  const Line10InteractiveMetroMap({
    super.key,
    required this.selectedStationId,
    required this.onStationSelected,
    this.onMapInteraction,
    this.height = 390,
    this.immersive = false,
    this.showControls = true,
    this.showHint = true,
    this.controlsBottomOffset = 12,
    this.labelBottomInset = 48,
  });

  // Coordinates are based on the user's R-C.jpg reference image pixels.
  static const List<Line10MapStation> stations = [
    Line10MapStation(
      id: 'mock-l10-hongqiao-railway',
      name: '虹桥火车站',
      position: Offset(96, 754),
      transferLines: ['2', '17'],
      keyStation: true,
    ),
    Line10MapStation(
      id: 'mock-l10-hongqiao-t2',
      name: '虹桥2号航站楼',
      position: Offset(153, 754),
      transferLines: ['2'],
    ),
    Line10MapStation(
      id: 'mock-l10-hongqiao-t1',
      name: '虹桥1号航站楼',
      position: Offset(170, 823),
    ),
    Line10MapStation(
      id: 'mock-l10-shanghai-zoo',
      name: '上海动物园',
      position: Offset(235, 884),
    ),
    Line10MapStation(
      id: 'mock-l10-longxi-road',
      name: '龙溪路',
      position: Offset(315, 915),
      keyStation: true,
    ),
    Line10MapStation(
      id: 'mock-l10-shuicheng-road',
      name: '水城路',
      position: Offset(400, 915),
    ),
    Line10MapStation(
      id: 'mock-l10-yili-road',
      name: '伊犁路',
      position: Offset(485, 915),
    ),
    Line10MapStation(
      id: 'mock-l10-songyuan-road',
      name: '宋园路',
      position: Offset(570, 915),
    ),
    Line10MapStation(
      id: 'mock-l10-hongqiao-road',
      name: '虹桥路',
      position: Offset(637, 830),
      transferLines: ['3', '4'],
      keyStation: true,
    ),
    Line10MapStation(
      id: 'mock-l10-jiaotong-university',
      name: '交通大学',
      position: Offset(753, 830),
      transferLines: ['11'],
      keyStation: true,
    ),
    Line10MapStation(
      id: 'mock-l10-shanghai-library',
      name: '上海图书馆',
      position: Offset(845, 830),
    ),
    Line10MapStation(
      id: 'mock-l10-south-shaanxi-road',
      name: '陕西南路',
      position: Offset(928, 830),
      transferLines: ['1', '12'],
      keyStation: true,
    ),
    Line10MapStation(
      id: 'mock-l10-xintiandi',
      name: '一大会址·新天地',
      position: Offset(1046, 830),
      transferLines: ['13'],
    ),
    Line10MapStation(
      id: 'mock-l10-laoximen',
      name: '老西门',
      position: Offset(1155, 830),
      transferLines: ['8'],
    ),
    Line10MapStation(
      id: 'mock-l10-yuyuan',
      name: '豫园',
      position: Offset(1155, 760),
      transferLines: ['14'],
    ),
    Line10MapStation(
      id: 'mock-l10-east-nanjing-road',
      name: '南京东路',
      position: Offset(1155, 665),
      transferLines: ['2'],
      keyStation: true,
    ),
    Line10MapStation(
      id: 'mock-l10-tiantong-road',
      name: '天潼路',
      position: Offset(1155, 575),
      transferLines: ['12'],
    ),
    Line10MapStation(
      id: 'mock-l10-north-sichuan-road',
      name: '四川北路',
      position: Offset(1155, 530),
    ),
    Line10MapStation(
      id: 'mock-l10-hailun-road',
      name: '海伦路',
      position: Offset(1155, 493),
      transferLines: ['4'],
    ),
    Line10MapStation(
      id: 'mock-l10-youdian-xincun',
      name: '邮电新村',
      position: Offset(1155, 425),
    ),
    Line10MapStation(
      id: 'mock-l10-siping-road',
      name: '四平路',
      position: Offset(1155, 360),
      transferLines: ['8'],
    ),
    Line10MapStation(
      id: 'mock-l10-tongji-university',
      name: '同济大学',
      position: Offset(1190, 323),
      keyStation: true,
    ),
    Line10MapStation(
      id: 'mock-l10-guoquan-road',
      name: '国权路',
      position: Offset(1218, 295),
      transferLines: ['18'],
    ),
    Line10MapStation(
      id: 'mock-l10-wujiaochang',
      name: '五角场',
      position: Offset(1248, 266),
      keyStation: true,
    ),
    Line10MapStation(
      id: 'mock-l10-jiangwan-stadium',
      name: '江湾体育场',
      position: Offset(1278, 236),
    ),
    Line10MapStation(
      id: 'mock-l10-sanmen-road',
      name: '三门路',
      position: Offset(1307, 207),
    ),
    Line10MapStation(
      id: 'mock-l10-yingao-east-road',
      name: '殷高东路',
      position: Offset(1336, 178),
    ),
    Line10MapStation(
      id: 'mock-l10-xinjiangwan-city',
      name: '新江湾城',
      position: Offset(1365, 148),
      keyStation: true,
    ),
    Line10MapStation(
      id: 'mock-l10-guofan-road',
      name: '国帆路',
      position: Offset(1425, 148),
    ),
    Line10MapStation(
      id: 'mock-l10-shuangjiang-road',
      name: '双江路',
      position: Offset(1485, 148),
    ),
    Line10MapStation(
      id: 'mock-l10-gaoqiao-west',
      name: '高桥西',
      position: Offset(1545, 148),
    ),
    Line10MapStation(
      id: 'mock-l10-gaoqiao',
      name: '高桥',
      position: Offset(1605, 148),
    ),
    Line10MapStation(
      id: 'mock-l10-gangcheng-road',
      name: '港城路',
      position: Offset(1665, 148),
      transferLines: ['6'],
      keyStation: true,
    ),
    Line10MapStation(
      id: 'mock-l10-jilong-road',
      name: '基隆路',
      position: Offset(1725, 148),
      keyStation: true,
    ),
  ];

  static const List<Line10MapStation> branchStations = [
    Line10MapStation(
      id: 'mock-l10-hangzhong-road',
      name: '航中路',
      position: Offset(90, 915),
      keyStation: true,
    ),
    Line10MapStation(
      id: 'mock-l10-ziteng-road',
      name: '紫藤路',
      position: Offset(175, 915),
    ),
    Line10MapStation(
      id: 'mock-l10-longbai-xincun',
      name: '龙柏新村',
      position: Offset(255, 915),
    ),
  ];

  static const Size mapSize = Size(1800, 1050);

  @override
  State<Line10InteractiveMetroMap> createState() =>
      _Line10InteractiveMetroMapState();
}

class _Line10InteractiveMetroMapState extends State<Line10InteractiveMetroMap> {
  late final TransformationController _controller;
  double _scale = 0.42;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _controller.addListener(_syncScale);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitInitialView());
  }

  @override
  void didUpdateWidget(covariant Line10InteractiveMetroMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedStationId != widget.selectedStationId) {
      setState(() {});
    }
  }

  void _syncScale() {
    final scale = _controller.value.getMaxScaleOnAxis();
    if ((scale - _scale).abs() > 0.02) {
      setState(() {
        _scale = scale;
      });
    }
  }

  void _fitInitialView() {
    final width = context.size?.width ?? 360;
    final scale = math.max(
      0.16,
      math.min(0.46, (width - 24) / Line10InteractiveMetroMap.mapSize.width),
    );
    _controller.value = Matrix4.identity()
      ..translate(12.0, 96.0)
      ..scale(scale);
    setState(() {
      _scale = scale;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_syncScale);
    _controller.dispose();
    super.dispose();
  }

  void _handleTapUp(TapUpDetails details) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final local = box.globalToLocal(details.globalPosition);
    final mapPoint = MatrixUtils.transformPoint(
      Matrix4.inverted(_controller.value),
      local,
    );

    Line10MapStation? hit;
    var minDistance = 30.0;
    for (final station in _allStations) {
      final distance = (station.position - mapPoint).distance;
      if (distance < minDistance) {
        minDistance = distance;
        hit = station;
      }
    }

    if (hit != null) {
      widget.onStationSelected(hit);
    }
  }

  List<Line10MapStation> get _allStations => [
        ...Line10InteractiveMetroMap.stations,
        ...Line10InteractiveMetroMap.branchStations,
      ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusL),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTapUp: (details) {
                  widget.onMapInteraction?.call();
                  _handleTapUp(details);
                },
                onPanStart: (_) => widget.onMapInteraction?.call(),
                child: InteractiveViewer(
                  transformationController: _controller,
                  constrained: false,
                  panAxis: PanAxis.free,
                  minScale: 0.16,
                  maxScale: 1.65,
                  boundaryMargin: const EdgeInsets.symmetric(
                    horizontal: 700,
                    vertical: 520,
                  ),
                  onInteractionStart: (_) => widget.onMapInteraction?.call(),
                  child: CustomPaint(
                    size: Line10InteractiveMetroMap.mapSize,
                    painter: _Line10MetroPainter(
                      selectedStationId: widget.selectedStationId,
                      scale: _scale,
                      colorScheme: colorScheme,
                    ),
                  ),
                ),
              ),
            ),
            if (!widget.immersive)
              Positioned(
                left: 12,
                top: 12,
                right: 12,
                child: _MapSearchBar(
                  selectedStationName: _allStations
                      .firstWhere(
                        (station) => station.id == widget.selectedStationId,
                        orElse: () => Line10InteractiveMetroMap.stations.first,
                      )
                      .name,
                ),
              ),
            if (widget.showControls)
              Positioned(
                right: 12,
                bottom: widget.controlsBottomOffset,
                child: Column(
                  children: [
                    _MapIconButton(
                      icon: Icons.add,
                      tooltip: '放大',
                      onPressed: () => _zoomBy(1.22),
                    ),
                    const SizedBox(height: 8),
                    _MapIconButton(
                      icon: Icons.remove,
                      tooltip: '缩小',
                      onPressed: () => _zoomBy(0.82),
                    ),
                    const SizedBox(height: 8),
                    _MapIconButton(
                      icon: Icons.my_location,
                      tooltip: '复位',
                      onPressed: _fitInitialView,
                    ),
                  ],
                ),
              ),
            if (widget.showHint)
              Positioned(
                left: 12,
                bottom: widget.labelBottomInset,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      _scale < 0.72 ? '放大查看更多站名' : '点击站点查看到站',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _zoomBy(double factor) {
    final next = _controller.value.clone()..scale(factor);
    _controller.value = next;
  }
}

class _MapSearchBar extends StatelessWidget {
  final String selectedStationName;

  const _MapSearchBar({required this.selectedStationName});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.search, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '搜索站点 / 当前：$selectedStationName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _MapIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }
}

class _Line10MetroPainter extends CustomPainter {
  final String selectedStationId;
  final double scale;
  final ColorScheme colorScheme;

  _Line10MetroPainter({
    required this.selectedStationId,
    required this.scale,
    required this.colorScheme,
  });

  static const Color line10Color = Color(0xFFB894F4);
  static const Color line2Color = Color(0xFF7AC143);
  static const Color line17Color = Color(0xFFC490C0);
  static const Color line11Color = Color(0xFF7B3F2A);
  static const Color line12Color = Color(0xFF00843D);
  static const Color line13Color = Color(0xFFF49AC1);
  static const Color line14Color = Color(0xFFA6A01D);
  static const Color line18Color = Color(0xFF00A3AD);

  @override
  void paint(Canvas canvas, Size size) {
    _drawRiver(canvas);
    _drawTransferHints(canvas);
    _drawLinePath(canvas, Line10InteractiveMetroMap.stations, line10Color);
    _drawLinePath(
        canvas,
        [
          ...Line10InteractiveMetroMap.branchStations,
          Line10InteractiveMetroMap.stations[4],
        ],
        line10Color);
    _drawLineLabels(canvas);
    for (final station in [
      ...Line10InteractiveMetroMap.branchStations,
      ...Line10InteractiveMetroMap.stations,
    ]) {
      _drawStation(canvas, station);
    }
  }

  void _drawRiver(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFFBFE7F5).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 42
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final river = Path()
      ..moveTo(1060, 680)
      ..lineTo(1120, 560)
      ..lineTo(1110, 430)
      ..lineTo(1190, 330)
      ..lineTo(1270, 260)
      ..lineTo(1380, 165)
      ..lineTo(1510, 85);
    canvas.drawPath(river, paint);
  }

  void _drawTransferHints(Canvas canvas) {
    _drawShortLine(canvas, line2Color,
        const [Offset(40, 754), Offset(180, 754)], '2号线');
    _drawShortLine(canvas, line17Color,
        const [Offset(40, 700), Offset(150, 700)], '17号线');
    _drawShortLine(canvas, const Color(0xFF4B2E83),
        const [Offset(610, 760), Offset(670, 900)], '3/4号线');
    _drawShortLine(canvas, line11Color,
        const [Offset(753, 760), Offset(753, 900)], '11号线');
    _drawShortLine(canvas, const Color(0xFFE4002B),
        const [Offset(928, 760), Offset(928, 900)], '1号线');
    _drawShortLine(canvas, line12Color,
        const [Offset(1046, 760), Offset(1046, 900)], '12号线');
    _drawShortLine(canvas, line13Color,
        const [Offset(1085, 760), Offset(1085, 900)], '13号线');
    _drawShortLine(canvas, line14Color,
        const [Offset(1080, 665), Offset(1230, 665)], '14号线');
    _drawShortLine(canvas, line18Color,
        const [Offset(1218, 230), Offset(1218, 360)], '18号线');
    _drawShortLine(canvas, const Color(0xFFBE2D79),
        const [Offset(1665, 95), Offset(1665, 205)], '6号线');
    _drawTransferStations(canvas);
  }

  void _drawShortLine(
    Canvas canvas,
    Color color,
    List<Offset> points,
    String label,
  ) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);

    if (scale >= 0.66) {
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, points.first + const Offset(-4, -34));
    }
  }

  void _drawTransferStations(Canvas canvas) {
    const previews = [
      [
        _TransferStop('徐泾东', Offset(40, 754)),
        _TransferStop('虹桥火车站', Offset(96, 754)),
        _TransferStop('虹桥2号航站楼', Offset(153, 754)),
      ],
      [
        _TransferStop('诸光路', Offset(40, 700)),
        _TransferStop('虹桥火车站', Offset(96, 700)),
        _TransferStop('虹桥2号航站楼', Offset(153, 700)),
      ],
      [
        _TransferStop('延安西路', Offset(610, 760)),
        _TransferStop('虹桥路', Offset(637, 830)),
        _TransferStop('宜山路', Offset(670, 900)),
      ],
      [
        _TransferStop('徐家汇', Offset(753, 760)),
        _TransferStop('交通大学', Offset(753, 830)),
        _TransferStop('江苏路', Offset(753, 900)),
      ],
      [
        _TransferStop('常熟路', Offset(928, 760)),
        _TransferStop('陕西南路', Offset(928, 830)),
        _TransferStop('黄陂南路', Offset(928, 900)),
      ],
      [
        _TransferStop('南京西路', Offset(1046, 760)),
        _TransferStop('陕西南路', Offset(1046, 830)),
        _TransferStop('嘉善路', Offset(1046, 900)),
      ],
      [
        _TransferStop('淮海中路', Offset(1085, 760)),
        _TransferStop('新天地', Offset(1085, 830)),
        _TransferStop('马当路', Offset(1085, 900)),
      ],
      [
        _TransferStop('大世界', Offset(1080, 665)),
        _TransferStop('豫园', Offset(1155, 665)),
        _TransferStop('陆家嘴', Offset(1230, 665)),
      ],
      [
        _TransferStop('抚顺路', Offset(1218, 230)),
        _TransferStop('国权路', Offset(1218, 295)),
        _TransferStop('复旦大学', Offset(1218, 360)),
      ],
      [
        _TransferStop('外高桥保税区北', Offset(1665, 95)),
        _TransferStop('港城路', Offset(1665, 148)),
        _TransferStop('外高桥保税区南', Offset(1665, 205)),
      ],
    ];

    for (final stops in previews) {
      for (final stop in stops) {
        _drawMiniStation(canvas, stop.position);
        if (scale >= 0.54) {
          _drawSmallTransferLabel(canvas, stop.name, stop.position);
        }
      }
    }
  }

  void _drawMiniStation(Canvas canvas, Offset position) {
    canvas.drawCircle(position, 8.5, Paint()..color = Colors.white);
    canvas.drawCircle(
      position,
      8.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..color = Colors.black87,
    );
  }

  void _drawSmallTransferLabel(Canvas canvas, String label, Offset position) {
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.05,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 120);
    tp.paint(canvas, position + const Offset(10, 8));
  }

  void _drawLinePath(
    Canvas canvas,
    List<Line10MapStation> stations,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(stations.first.position.dx, stations.first.position.dy);
    for (final station in stations.skip(1)) {
      path.lineTo(station.position.dx, station.position.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawLineLabels(Canvas canvas) {
    _drawBadge(canvas, '10', const Offset(84, 806), line10Color);
    _drawBadge(canvas, '10', const Offset(86, 968), line10Color);
    _drawBadge(canvas, '10', const Offset(1740, 202), line10Color);
  }

  void _drawBadge(Canvas canvas, String text, Offset center, Color color) {
    final rect = Rect.fromCenter(center: center, width: 54, height: 42);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawRRect(rrect, Paint()..color = color);
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 27,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawStation(Canvas canvas, Line10MapStation station) {
    final selected = station.id == selectedStationId;
    final isTransfer = station.transferLines.isNotEmpty;

    final outerRadius = selected ? 19.0 : (isTransfer ? 14.0 : 10.0);
    final innerRadius = selected ? 9.0 : 5.5;
    canvas.drawCircle(
      station.position,
      outerRadius,
      Paint()..color = selected ? colorScheme.primary : Colors.white,
    );
    canvas.drawCircle(
      station.position,
      outerRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 5 : 3
        ..color = selected ? colorScheme.primary : Colors.black87,
    );
    if (!selected) {
      canvas.drawCircle(
          station.position, innerRadius, Paint()..color = Colors.white);
    }

    final showLabel = scale >= 0.78 || selected || station.keyStation;
    if (showLabel) {
      _drawStationLabel(canvas, station, selected);
    }
  }

  void _drawStationLabel(
    Canvas canvas,
    Line10MapStation station,
    bool selected,
  ) {
    final labelOffset = _labelOffsetFor(station);
    final textStyle = TextStyle(
      color: selected ? colorScheme.primary : Colors.black87,
      fontSize: selected ? 28 : 23,
      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      height: 1.05,
    );

    final tp = TextPainter(
      text: TextSpan(text: station.name, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 150);

    final anchor = station.position + labelOffset;
    final dx = labelOffset.dx < 0 ? anchor.dx - tp.width : anchor.dx;
    final dy = labelOffset.dy < 0 ? anchor.dy - tp.height : anchor.dy;

    if (selected) {
      final bg = RRect.fromRectAndRadius(
        Rect.fromLTWH(dx - 8, dy - 5, tp.width + 16, tp.height + 10),
        const Radius.circular(6),
      );
      canvas.drawRRect(
          bg, Paint()..color = colorScheme.surface.withValues(alpha: 0.92));
    }
    tp.paint(canvas, Offset(dx, dy));
  }

  Offset _labelOffsetFor(Line10MapStation station) {
    if (station.position.dx < 400) return const Offset(-8, -48);
    if (station.position.dx > 1450) return const Offset(18, -10);
    if (station.position.dy < 170) return const Offset(-34, 22);
    if (station.name.length >= 5) return const Offset(-48, 24);
    return const Offset(-24, 24);
  }

  @override
  bool shouldRepaint(covariant _Line10MetroPainter oldDelegate) {
    return oldDelegate.selectedStationId != selectedStationId ||
        oldDelegate.scale != scale ||
        oldDelegate.colorScheme != colorScheme;
  }
}
