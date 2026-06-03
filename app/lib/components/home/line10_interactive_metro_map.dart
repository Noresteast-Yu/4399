import 'package:flutter/material.dart';
import 'package:smart_travel_app/theme/app_theme.dart';

class Line10MapStation {
  final String id;
  final String name;
  final Offset position;
  final String lineId;
  final List<String> transferLines;
  final bool keyStation;

  const Line10MapStation({
    required this.id,
    required this.name,
    required this.position,
    this.lineId = '10',
    this.transferLines = const [],
    this.keyStation = false,
  });
}

class MetroMapLine {
  final String id;
  final String name;
  final Color color;
  final List<List<Line10MapStation>> stationGroups;
  final List<MetroLineBadge> badges;

  const MetroMapLine({
    required this.id,
    required this.name,
    required this.color,
    required this.stationGroups,
    this.badges = const [],
  });
}

class MetroLineBadge {
  final String text;
  final Offset center;

  const MetroLineBadge(this.text, this.center);
}

class MetroMapReferenceLine {
  final String id;
  final String name;
  final Color color;
  final List<Offset> points;
  final List<MetroMapReferenceStop> stops;
  final double labelMinScale;

  const MetroMapReferenceLine({
    required this.id,
    required this.name,
    required this.color,
    required this.points,
    this.stops = const [],
    this.labelMinScale = 0.95,
  });
}

class MetroMapReferenceStop {
  final String name;
  final Offset position;

  const MetroMapReferenceStop(this.name, this.position);
}

class MetroMapDataset {
  final Size mapSize;
  final List<MetroMapLine> lines;
  final List<MetroMapReferenceLine> referenceLines;
  final String initialStationId;

  const MetroMapDataset({
    required this.mapSize,
    required this.lines,
    required this.referenceLines,
    required this.initialStationId,
  });

  List<Line10MapStation> get allStations {
    final seen = <String>{};
    final result = <Line10MapStation>[];
    for (final line in lines) {
      for (final group in line.stationGroups) {
        for (final station in group) {
          if (seen.add(station.id)) {
            result.add(station);
          }
        }
      }
    }
    return result;
  }

  Line10MapStation get initialStation {
    return allStations.firstWhere(
      (station) => station.id == initialStationId,
      orElse: () => allStations.first,
    );
  }
}

class _MapLabelPlacement {
  final Line10MapStation station;
  final Rect rect;
  final bool selected;

  const _MapLabelPlacement({
    required this.station,
    required this.rect,
    required this.selected,
  });
}

class Line10InteractiveMetroMap extends StatefulWidget {
  final String selectedStationId;
  final ValueChanged<Line10MapStation> onStationSelected;
  final VoidCallback? onMapInteraction;
  final MetroMapDataset? dataset;
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
    this.dataset,
    this.height = 390,
    this.immersive = false,
    this.showControls = true,
    this.showHint = true,
    this.controlsBottomOffset = 12,
    this.labelBottomInset = 0,
  });

  static List<Line10MapStation> get stations =>
      ShanghaiMetroMapData.line10MainStations;

  static List<Line10MapStation> get branchStations =>
      ShanghaiMetroMapData.line10BranchStations;

  static List<MetroMapLine> get metroLines =>
      ShanghaiMetroMapData.coreLine10.lines;

  static List<MetroMapReferenceLine> get referenceLines =>
      ShanghaiMetroMapData.coreLine10.referenceLines;

  static List<Line10MapStation> get allStations =>
      ShanghaiMetroMapData.coreLine10.allStations;

  static Size get mapSize => ShanghaiMetroMapData.coreLine10.mapSize;

  static MetroMapDataset get defaultDataset => ShanghaiMetroMapData.coreLine10;

  @override
  State<Line10InteractiveMetroMap> createState() =>
      _Line10InteractiveMetroMapState();
}

class ShanghaiMetroMapData {
  static const Color line10Color = Color(0xFFB894F4);
  static const Color line2Color = Color(0xFF7AC143);
  static const Color line17Color = Color(0xFFC490C0);
  static const Color line11Color = Color(0xFF7B3F2A);
  static const Color line12Color = Color(0xFF00843D);
  static const Color line13Color = Color(0xFFF49AC1);
  static const Color line14Color = Color(0xFFA6A01D);
  static const Color line18Color = Color(0xFF00A3AD);
  static const Color line6Color = Color(0xFFBE2D79);
  static const Color line34Color = Color(0xFF4B2E83);

  // Coordinates are based on the user's R-C.jpg reference image pixels.
  static const List<Line10MapStation> line10MainStations = [
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

  static const List<Line10MapStation> line10BranchStations = [
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

  static final MetroMapDataset coreLine10 = MetroMapDataset(
    mapSize: const Size(1800, 1050),
    initialStationId: 'mock-l10-wujiaochang',
    lines: metroLines,
    referenceLines: referenceLines,
  );

  static final List<MetroMapLine> metroLines = [
    MetroMapLine(
      id: '10',
      name: '10号线',
      color: line10Color,
      stationGroups: [
        line10MainStations,
        [
          ...line10BranchStations,
          line10MainStations[4],
        ],
      ],
      badges: [
        MetroLineBadge('10', Offset(84, 806)),
        MetroLineBadge('10', Offset(86, 968)),
        MetroLineBadge('10', Offset(1740, 202)),
      ],
    ),
  ];

  static const List<MetroMapReferenceLine> referenceLines = [
    MetroMapReferenceLine(
      id: '2',
      name: '2号线',
      color: line2Color,
      points: [Offset(40, 754), Offset(180, 754)],
      stops: [
        MetroMapReferenceStop('徐泾东', Offset(40, 754)),
        MetroMapReferenceStop('虹桥火车站', Offset(96, 754)),
        MetroMapReferenceStop('虹桥2号航站楼', Offset(153, 754)),
      ],
    ),
    MetroMapReferenceLine(
      id: '17',
      name: '17号线',
      color: line17Color,
      points: [Offset(40, 700), Offset(150, 700)],
      stops: [
        MetroMapReferenceStop('诸光路', Offset(40, 700)),
        MetroMapReferenceStop('虹桥火车站', Offset(96, 700)),
        MetroMapReferenceStop('虹桥2号航站楼', Offset(153, 700)),
      ],
    ),
    MetroMapReferenceLine(
      id: '3-4',
      name: '3/4号线',
      color: line34Color,
      points: [Offset(610, 760), Offset(670, 900)],
      stops: [
        MetroMapReferenceStop('延安西路', Offset(610, 760)),
        MetroMapReferenceStop('虹桥路', Offset(637, 830)),
        MetroMapReferenceStop('宜山路', Offset(670, 900)),
      ],
    ),
    MetroMapReferenceLine(
      id: '11',
      name: '11号线',
      color: line11Color,
      points: [Offset(753, 760), Offset(753, 900)],
      stops: [
        MetroMapReferenceStop('徐家汇', Offset(753, 760)),
        MetroMapReferenceStop('交通大学', Offset(753, 830)),
        MetroMapReferenceStop('江苏路', Offset(753, 900)),
      ],
    ),
    MetroMapReferenceLine(
      id: '1',
      name: '1号线',
      color: Color(0xFFE4002B),
      points: [Offset(928, 760), Offset(928, 900)],
      stops: [
        MetroMapReferenceStop('常熟路', Offset(928, 760)),
        MetroMapReferenceStop('陕西南路', Offset(928, 830)),
        MetroMapReferenceStop('黄陂南路', Offset(928, 900)),
      ],
    ),
    MetroMapReferenceLine(
      id: '12',
      name: '12号线',
      color: line12Color,
      points: [Offset(1046, 760), Offset(1046, 900)],
      stops: [
        MetroMapReferenceStop('南京西路', Offset(1046, 760)),
        MetroMapReferenceStop('陕西南路', Offset(1046, 830)),
        MetroMapReferenceStop('嘉善路', Offset(1046, 900)),
      ],
    ),
    MetroMapReferenceLine(
      id: '13',
      name: '13号线',
      color: line13Color,
      points: [Offset(1085, 760), Offset(1085, 900)],
      stops: [
        MetroMapReferenceStop('淮海中路', Offset(1085, 760)),
        MetroMapReferenceStop('新天地', Offset(1085, 830)),
        MetroMapReferenceStop('马当路', Offset(1085, 900)),
      ],
    ),
    MetroMapReferenceLine(
      id: '14',
      name: '14号线',
      color: line14Color,
      points: [Offset(1080, 665), Offset(1230, 665)],
      stops: [
        MetroMapReferenceStop('大世界', Offset(1080, 665)),
        MetroMapReferenceStop('豫园', Offset(1155, 665)),
        MetroMapReferenceStop('陆家嘴', Offset(1230, 665)),
      ],
    ),
    MetroMapReferenceLine(
      id: '18',
      name: '18号线',
      color: line18Color,
      points: [Offset(1218, 230), Offset(1218, 360)],
      stops: [
        MetroMapReferenceStop('抚顺路', Offset(1218, 230)),
        MetroMapReferenceStop('国权路', Offset(1218, 295)),
        MetroMapReferenceStop('复旦大学', Offset(1218, 360)),
      ],
    ),
    MetroMapReferenceLine(
      id: '6',
      name: '6号线',
      color: line6Color,
      points: [Offset(1665, 95), Offset(1665, 205)],
      stops: [
        MetroMapReferenceStop('外高桥保税区北', Offset(1665, 95)),
        MetroMapReferenceStop('港城路', Offset(1665, 148)),
        MetroMapReferenceStop('外高桥保税区南', Offset(1665, 205)),
      ],
    ),
  ];
}

class _Line10InteractiveMetroMapState extends State<Line10InteractiveMetroMap> {
  late final TransformationController _controller;
  double _scale = 0.42;
  Size? _lastViewport;
  MetroMapDataset? _cachedDataset;
  List<Line10MapStation> _cachedStations = const [];
  Matrix4? _interactionStartMatrix;
  bool _interactionMoved = false;

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
    final nextScale = _controller.value.getMaxScaleOnAxis();
    if (!mounted) return;
    if ((nextScale - _scale).abs() < 0.025) return;
    setState(() {
      _scale = nextScale;
    });
  }

  void _fitInitialView() {
    final renderSize = context.size;
    final mediaSize = MediaQuery.sizeOf(context);
    final width = renderSize != null && renderSize.width > 0
        ? renderSize.width
        : mediaSize.width;
    final height = renderSize != null && renderSize.height > 0
        ? renderSize.height
        : mediaSize.height;
    _fitInitialViewFor(Size(width, height));
  }

  void _fitInitialViewFor(Size viewport) {
    if (viewport.width <= 0 || viewport.height <= 0) return;
    final scale = widget.immersive
        ? (viewport.width < 380 ? 0.56 : 0.62)
        : (viewport.width < 380 ? 0.48 : 0.54);
    final station = _selectedStation;
    final dx = (viewport.width / 2) - (station.position.dx * scale);
    final targetY =
        widget.immersive ? viewport.height * 0.44 : viewport.height / 2;
    final dy = targetY - (station.position.dy * scale);
    _controller.value = Matrix4.identity()
      ..translate(dx, dy)
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

  MetroMapDataset get _dataset =>
      widget.dataset ?? Line10InteractiveMetroMap.defaultDataset;

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

  List<Line10MapStation> get _allStations {
    final dataset = _dataset;
    if (!identical(_cachedDataset, dataset)) {
      _cachedDataset = dataset;
      _cachedStations = dataset.allStations;
    }
    return _cachedStations;
  }

  Line10MapStation get _selectedStation {
    return _allStations.firstWhere(
      (station) => station.id == widget.selectedStationId,
      orElse: () => _dataset.initialStation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final map = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final viewport = Size(width, widget.height);
        if (_lastViewport != viewport) {
          _lastViewport = viewport;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _fitInitialViewFor(viewport);
          });
        }

        return SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTapUp: _handleTapUp,
                  child: InteractiveViewer(
                    transformationController: _controller,
                    constrained: false,
                    panAxis: PanAxis.free,
                    onInteractionStart: (_) {
                      _interactionStartMatrix = _controller.value.clone();
                      _interactionMoved = false;
                    },
                    onInteractionUpdate: (_) {
                      final start = _interactionStartMatrix;
                      if (start == null) return;
                      final current = _controller.value;
                      final moved =
                          (current.getTranslation() - start.getTranslation())
                                  .length >
                              2;
                      final scaled = (current.getMaxScaleOnAxis() -
                                  start.getMaxScaleOnAxis())
                              .abs() >
                          0.01;
                      _interactionMoved = _interactionMoved || moved || scaled;
                    },
                    onInteractionEnd: (_) {
                      if (_interactionMoved) {
                        widget.onMapInteraction?.call();
                      }
                    },
                    minScale: 0.16,
                    maxScale: 1.65,
                    boundaryMargin: const EdgeInsets.symmetric(
                      horizontal: 700,
                      vertical: 520,
                    ),
                    child: CustomPaint(
                      size: _dataset.mapSize,
                      painter: _InteractiveMetroMapPainter(
                        dataset: _dataset,
                        stations: _allStations,
                        selectedStationId: widget.selectedStationId,
                        scale: _scale,
                        colorScheme: colorScheme,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children:
                            _buildStationLabelOverlay(colorScheme, viewport),
                      );
                    },
                  ),
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
                  bottom: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Text(
                        _scale < 0.72 ? '放大查看更多站名' : '点击站点查看到站',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (widget.immersive) {
      return map;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusL),
      child: map,
    );
  }

  void _zoomBy(double factor) {
    widget.onMapInteraction?.call();
    final next = _controller.value.clone()..scale(factor);
    _controller.value = next;
  }

  List<Widget> _buildStationLabelOverlay(
    ColorScheme colorScheme,
    Size viewport,
  ) {
    final placements = _layoutStationLabels(viewport);
    return [
      for (final placement in placements)
        Positioned(
          left: placement.rect.left,
          top: placement.rect.top,
          width: placement.rect.width,
          height: placement.rect.height,
          child: _MapStationLabel(
            name: placement.station.name,
            selected: placement.selected,
            colorScheme: colorScheme,
          ),
        ),
    ];
  }

  List<_MapLabelPlacement> _layoutStationLabels(Size viewport) {
    final matrix = _controller.value;
    final selectedId = widget.selectedStationId;
    final reserved = <Rect>[];
    final placements = <_MapLabelPlacement>[];

    for (final station in _allStations) {
      final center = MatrixUtils.transformPoint(matrix, station.position);
      if (!_isNearViewport(center, viewport, margin: 80)) continue;
      reserved.add(Rect.fromCircle(
        center: center,
        radius: _screenMarkerRadius(station) + 3,
      ));
    }

    final candidates = _allStations
        .where((station) => _shouldShowStationLabel(station, selectedId))
        .toList()
      ..sort((a, b) => _labelPriority(a, selectedId)
          .compareTo(_labelPriority(b, selectedId)));

    for (final station in candidates) {
      final center = MatrixUtils.transformPoint(matrix, station.position);
      if (!_isNearViewport(center, viewport, margin: 140)) continue;

      final selected = station.id == selectedId;
      final labelSize = _measureLabel(station.name, selected);
      final rect = _placeScreenLabel(
        center: center,
        size: labelSize,
        markerRadius: _screenMarkerRadius(station),
        reserved: reserved,
        viewport: viewport,
        force: selected || station.keyStation,
      );
      if (rect == null) continue;

      reserved.add(rect.inflate(selected ? 10 : 7));
      placements.add(_MapLabelPlacement(
        station: station,
        rect: rect,
        selected: selected,
      ));
    }

    return placements;
  }

  bool _shouldShowStationLabel(Line10MapStation station, String selectedId) {
    if (station.id == selectedId) return true;
    if (station.keyStation) return true;
    if (station.transferLines.isNotEmpty && _scale >= 0.62) return true;
    return _scale >= 0.94;
  }

  int _labelPriority(Line10MapStation station, String selectedId) {
    if (station.id == selectedId) return 0;
    if (station.keyStation) return 1;
    if (station.transferLines.isNotEmpty) return 2;
    return 3;
  }

  bool _isNearViewport(Offset point, Size viewport, {required double margin}) {
    return point.dx >= -margin &&
        point.dx <= viewport.width + margin &&
        point.dy >= -margin &&
        point.dy <= viewport.height + margin;
  }

  double _screenMarkerRadius(Line10MapStation station) {
    if (station.id == widget.selectedStationId) return 17;
    if (station.transferLines.isNotEmpty) return 12;
    return 8;
  }

  Size _measureLabel(String text, bool selected) {
    final style = TextStyle(
      fontSize: selected ? 24 : 15,
      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
      height: 1.05,
    );
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: selected ? 148 : 132);
    final horizontalPadding = selected ? 44.0 : 14.0;
    final verticalPadding = selected ? 12.0 : 6.0;
    return Size(
      painter.width + horizontalPadding,
      painter.height + verticalPadding,
    );
  }

  Rect? _placeScreenLabel({
    required Offset center,
    required Size size,
    required double markerRadius,
    required List<Rect> reserved,
    required Size viewport,
    required bool force,
  }) {
    final gap = markerRadius + 7;
    final farGap = markerRadius + 34;
    final candidates = [
      Rect.fromLTWH(center.dx + gap, center.dy - size.height / 2, size.width,
          size.height),
      Rect.fromLTWH(center.dx - size.width - gap, center.dy - size.height / 2,
          size.width, size.height),
      Rect.fromLTWH(center.dx + farGap, center.dy - size.height / 2, size.width,
          size.height),
      Rect.fromLTWH(center.dx - size.width - farGap,
          center.dy - size.height / 2, size.width, size.height),
      Rect.fromLTWH(center.dx + gap, center.dy + gap, size.width, size.height),
      Rect.fromLTWH(center.dx - size.width - gap, center.dy + gap, size.width,
          size.height),
      Rect.fromLTWH(center.dx + gap, center.dy - size.height - gap, size.width,
          size.height),
      Rect.fromLTWH(center.dx - size.width - gap, center.dy - size.height - gap,
          size.width, size.height),
      Rect.fromLTWH(center.dx - size.width / 2, center.dy - size.height - gap,
          size.width, size.height),
      Rect.fromLTWH(
          center.dx - size.width / 2, center.dy + gap, size.width, size.height),
      Rect.fromLTWH(center.dx - size.width / 2,
          center.dy - size.height - farGap, size.width, size.height),
      Rect.fromLTWH(center.dx - size.width / 2, center.dy + farGap, size.width,
          size.height),
    ];

    for (final rect in candidates) {
      if (!_labelInViewport(rect, viewport)) continue;
      if (_labelFits(rect, reserved)) return rect;
    }

    if (!force) return null;
    return candidates.firstWhere(
      (rect) => _labelInViewport(rect, viewport),
      orElse: () => candidates.first,
    );
  }

  bool _labelFits(Rect rect, List<Rect> reserved) {
    final padded = rect.inflate(5);
    for (final item in reserved) {
      if (item.overlaps(padded)) return false;
    }
    return true;
  }

  bool _labelInViewport(Rect rect, Size viewport) {
    return rect.left >= 8 &&
        rect.right <= viewport.width - 8 &&
        rect.top >= 8 &&
        rect.bottom <= viewport.height - widget.labelBottomInset - 8;
  }
}

class _MapStationLabel extends StatelessWidget {
  final String name;
  final bool selected;
  final ColorScheme colorScheme;

  const _MapStationLabel({
    required this.name,
    required this.selected,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: selected ? colorScheme.primary : colorScheme.onSurface,
        fontSize: selected ? 24 : 15,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
        height: 1.05,
        shadows: [
          Shadow(
            color: colorScheme.surface.withOpacity(0.95),
            blurRadius: 5,
          ),
          Shadow(
            color: colorScheme.surface.withOpacity(0.95),
            blurRadius: 5,
          ),
        ],
      ),
    );

    if (!selected) {
      return Align(alignment: Alignment.centerLeft, child: text);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.94),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: text,
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
      color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
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

class _InteractiveMetroMapPainter extends CustomPainter {
  final MetroMapDataset dataset;
  final List<Line10MapStation> stations;
  final String selectedStationId;
  final double scale;
  final ColorScheme colorScheme;

  _InteractiveMetroMapPainter({
    required this.dataset,
    required this.stations,
    required this.selectedStationId,
    required this.scale,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawRiver(canvas);
    _drawReferenceLines(canvas);
    for (final line in dataset.lines) {
      _drawMetroLine(canvas, line);
    }
    for (final station in stations) {
      _drawStationMarker(canvas, station);
    }
  }

  void _drawRiver(Canvas canvas) {
    final unit = _screenUnit;
    final paint = Paint()
      ..color = const Color(0xFFBFE7F5).withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30 * unit
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

  void _drawReferenceLines(Canvas canvas) {
    for (final line in dataset.referenceLines) {
      _drawReferenceLine(canvas, line);
      for (final stop in line.stops) {
        _drawMiniStation(canvas, stop.position);
      }
    }
  }

  void _drawReferenceLine(Canvas canvas, MetroMapReferenceLine line) {
    final unit = _screenUnit;
    final paint = Paint()
      ..color = line.color.withOpacity(0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 * unit
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(line.points.first.dx, line.points.first.dy);
    for (final point in line.points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);

    if (scale >= line.labelMinScale) {
      final tp = TextPainter(
        text: TextSpan(
          text: line.name,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 15 * unit,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, line.points.first + Offset(-4 * unit, -24 * unit));
    }
  }

  void _drawMiniStation(Canvas canvas, Offset position) {
    final unit = _screenUnit;
    final radius = 6.5 * unit;
    canvas.drawCircle(position, radius, Paint()..color = Colors.white);
    canvas.drawCircle(
      position,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * unit
        ..color = Colors.black87,
    );
  }

  void _drawMetroLine(Canvas canvas, MetroMapLine line) {
    for (final group in line.stationGroups) {
      _drawLinePath(
        canvas,
        group.map((station) => station.position).toList(),
        line.color,
      );
    }
    for (final badge in line.badges) {
      _drawBadge(canvas, badge.text, badge.center, line.color);
    }
  }

  void _drawLinePath(Canvas canvas, List<Offset> points, Color color) {
    final unit = _screenUnit;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13 * unit
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawBadge(Canvas canvas, String text, Offset center, Color color) {
    final unit = _screenUnit;
    final rect = Rect.fromCenter(
      center: center,
      width: 42 * unit,
      height: 32 * unit,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(4 * unit));
    canvas.drawRRect(rrect, Paint()..color = color);
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 20 * unit,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawStationMarker(Canvas canvas, Line10MapStation station) {
    final selected = station.id == selectedStationId;
    final isTransfer = station.transferLines.isNotEmpty;
    final unit = _screenUnit;

    final outerRadius = (selected ? 16.0 : (isTransfer ? 11.0 : 7.5)) * unit;
    final innerRadius = (selected ? 6.5 : 4.0) * unit;
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
        ..strokeWidth = (selected ? 3.4 : 2.2) * unit
        ..color = selected ? colorScheme.primary : Colors.black87,
    );
    if (!selected) {
      canvas.drawCircle(
          station.position, innerRadius, Paint()..color = Colors.white);
    }
  }

  double get _screenUnit => 1 / scale.clamp(0.75, 4.0);

  @override
  bool shouldRepaint(covariant _InteractiveMetroMapPainter oldDelegate) {
    return oldDelegate.dataset != dataset ||
        oldDelegate.stations != stations ||
        oldDelegate.selectedStationId != selectedStationId ||
        oldDelegate.scale != scale ||
        oldDelegate.colorScheme != colorScheme;
  }
}
