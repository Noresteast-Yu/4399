import 'package:flutter/material.dart';
import 'package:smart_travel_app/data/shanghai_metro_data.dart';
import 'package:smart_travel_app/theme/app_theme.dart';

class ShanghaiFullMetroMap extends StatefulWidget {
  final Function(String station, bool isStart)? onStationSelected;
  final String? initialStartStation;
  final String? initialEndStation;

  const ShanghaiFullMetroMap({
    super.key,
    this.onStationSelected,
    this.initialStartStation,
    this.initialEndStation,
  });

  @override
  State<ShanghaiFullMetroMap> createState() => _ShanghaiFullMetroMapState();
}

class _ShanghaiFullMetroMapState extends State<ShanghaiFullMetroMap> {
  String? _selectedStartStation;
  String? _selectedEndStation;
  late final List<MetroLine> _metroLines;
  final TransformationController _thumbnailController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _selectedStartStation = widget.initialStartStation;
    _selectedEndStation = widget.initialEndStation;
    _metroLines = ShanghaiMetroData.getAllLines();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapToContainer();
    });
  }

  void _fitMapToContainer() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final containerWidth = renderBox.size.width;
    const contentWidth = ShanghaiMetroData.canvasWidth;
    const contentHeight = ShanghaiMetroData.canvasHeight;
    const visibleHeight = 650.0;

    final scaleX = (containerWidth - 40) / contentWidth;
    const scaleY = (visibleHeight - 40) / contentHeight;
    final initialScale = (scaleX < scaleY ? scaleX : scaleY) * 0.75;

    final scaledWidth = contentWidth * initialScale;
    final scaledHeight = contentHeight * initialScale;
    final translateX = (containerWidth - scaledWidth) / 2;
    final translateY = (visibleHeight - scaledHeight) / 2;

    final matrix = Matrix4.identity()
      ..translate(translateX, translateY)
      ..scale(initialScale);
    _thumbnailController.value = matrix;
  }

  @override
  void dispose() {
    _thumbnailController.dispose();
    super.dispose();
  }

  void _openFullScreenMap() {
    final colorScheme = Theme.of(context).colorScheme;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: colorScheme.scrim.withValues(alpha: 0.85),
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenMetroMap(
            selectedStartStation: _selectedStartStation,
            selectedEndStation: _selectedEndStation,
            metroLines: _metroLines,
            onStationSelected: (station, isStart) {
              setState(() {
                if (isStart) {
                  _selectedStartStation = station;
                } else {
                  _selectedEndStation = station;
                }
              });
              widget.onStationSelected?.call(station, isStart);
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _showStationSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _StationSearchSheet(
        metroLines: _metroLines,
        selectedStartStation: _selectedStartStation,
        selectedEndStation: _selectedEndStation,
        onStationSelected: (station, isStart) {
          setState(() {
            if (isStart) {
              _selectedStartStation = station;
            } else {
              _selectedEndStation = station;
            }
          });
          widget.onStationSelected?.call(station, isStart);
        },
      ),
    );
  }

  void _onMapTap(TapUpDetails details, BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    final matrix = _thumbnailController.value;
    final inverseMatrix = Matrix4.inverted(matrix);
    final transformed = MatrixUtils.transformPoint(inverseMatrix, localPosition);

    const hitRadius = 24.0;
    MetroStation? closestStation;
    double minDistance = hitRadius;

    final allStations = _getAllUniqueStations();
    for (final station in allStations) {
      final dx = transformed.dx - station.x;
      final dy = transformed.dy - station.y;
      final distance = dx * dx + dy * dy;
      if (distance < minDistance * minDistance) {
        minDistance = distance;
        closestStation = station;
      }
    }

    if (closestStation != null) {
      _selectStation(closestStation.name);
    }
  }

  void _selectStation(String stationName) {
    setState(() {
      if (_selectedStartStation == null || _selectedEndStation != null) {
        if (_selectedEndStation != null) {
          _selectedStartStation = stationName;
          _selectedEndStation = null;
        } else {
          _selectedStartStation = stationName;
        }
      } else {
        if (_selectedStartStation == stationName) {
          _selectedStartStation = null;
        } else {
          _selectedEndStation = stationName;
        }
      }
    });
    widget.onStationSelected?.call(stationName, _selectedEndStation == null);
  }

  List<MetroStation> _getAllUniqueStations() {
    final unique = <String, MetroStation>{};
    for (final line in _metroLines) {
      for (final station in line.stations) {
        if (!unique.containsKey(station.name)) {
          unique[station.name] = station;
        }
      }
    }
    return unique.values.toList();
  }

  List<MetroStation> _getTransferStations() {
    final unique = <String, MetroStation>{};
    for (final line in _metroLines) {
      for (final station in line.stations) {
        if (station.transferLines.isNotEmpty &&
            !unique.containsKey(station.name)) {
          unique[station.name] = station;
        }
      }
    }
    return unique.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  '上海地铁线路图',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_metroLines.length}条线路',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (_selectedStartStation != null ||
                    _selectedEndStation != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedStartStation = null;
                        _selectedEndStation = null;
                      });
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('清除'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    Icons.fullscreen,
                    color: colorScheme.primary,
                  ),
                  onPressed: _openFullScreenMap,
                  tooltip: '全屏查看',
                ),
              ],
            ),
          ],
        ),
        if (_selectedStartStation != null || _selectedEndStation != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                if (_selectedStartStation != null)
                  Expanded(
                    child: _SelectedStationChip(
                      label: _selectedStartStation!,
                      icon: Icons.trip_origin,
                      color: colorScheme.primary,
                      backgroundColor: colorScheme.primaryContainer,
                      onClear: () {
                        setState(() => _selectedStartStation = null);
                      },
                    ),
                  ),
                if (_selectedStartStation != null &&
                    _selectedEndStation != null)
                  const SizedBox(width: 8),
                if (_selectedEndStation != null)
                  Expanded(
                    child: _SelectedStationChip(
                      label: _selectedEndStation!,
                      icon: Icons.flag,
                      color: colorScheme.error,
                      backgroundColor: colorScheme.errorContainer,
                      onClear: () {
                        setState(() => _selectedEndStation = null);
                      },
                    ),
                  ),
              ],
            ),
          ),
        GestureDetector(
          onTapUp: (details) => _onMapTap(details, context),
          child: ClipRRect(
            borderRadius: AppTheme.borderRadiusM,
            child: Container(
              height: 650,
              decoration: BoxDecoration(
                borderRadius: AppTheme.borderRadiusM,
                border: Border.all(color: colorScheme.outlineVariant),
                color: colorScheme.surface,
              ),
              child: Stack(
                children: [
                  InteractiveViewer(
                    transformationController: _thumbnailController,
                    minScale: 0.08,
                    maxScale: 4.0,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    child: SizedBox(
                      width: ShanghaiMetroData.canvasWidth,
                      height: ShanghaiMetroData.canvasHeight,
                      child: CustomPaint(
                        size: const Size(ShanghaiMetroData.canvasWidth,
                            ShanghaiMetroData.canvasHeight),
                        painter: _MetroLinePainter(
                          lines: _metroLines,
                          startStation: _selectedStartStation,
                          endStation: _selectedEndStation,
                          transferStations: _getTransferStations(),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: _openFullScreenMap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fullscreen,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '全屏查看',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: _showStationSearchSheet,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('搜索站点'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildLegend(colorScheme),
      ],
    );
  }

  Widget _buildLegend(ColorScheme colorScheme) {
    final legendLines = _metroLines.take(9).toList();
    final legendLines2 = _metroLines.length > 9
        ? _metroLines.sublist(9, _metroLines.length)
        : <MetroLine>[];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '图例',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              ...legendLines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 3,
                        decoration: BoxDecoration(
                          color: line.lineColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        line.lineName,
                        style: TextStyle(
                          fontSize: 9,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (legendLines2.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: legendLines2.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 3,
                        decoration: BoxDecoration(
                          color: line.lineColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        line.lineName,
                        style: TextStyle(
                          fontSize: 9,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectedStationChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onClear;

  const _SelectedStationChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Icon(Icons.close, size: 16, color: color),
          ),
        ],
      ),
    );
  }
}

class _MetroLinePainter extends CustomPainter {
  final List<MetroLine> lines;
  final String? startStation;
  final String? endStation;
  final List<MetroStation> transferStations;

  _MetroLinePainter({
    required this.lines,
    this.startStation,
    this.endStation,
    required this.transferStations,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final highlightPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.5)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final line in lines) {
      final linePoints = line.stations.map((s) => Offset(s.x, s.y)).toList();
      if (linePoints.length < 2) continue;

      final startIdx = startStation != null
          ? line.stations.indexWhere((s) => s.name == startStation)
          : -1;
      final endIdx = endStation != null
          ? line.stations.indexWhere((s) => s.name == endStation)
          : -1;

      if (startIdx >= 0 && endIdx >= 0) {
        final fromIdx = startIdx < endIdx ? startIdx : endIdx;
        final toIdx = startIdx < endIdx ? endIdx : startIdx;
        final highlightPath = Path();
        highlightPath.moveTo(linePoints[fromIdx].dx, linePoints[fromIdx].dy);
        for (int i = fromIdx + 1; i <= toIdx; i++) {
          highlightPath.lineTo(linePoints[i].dx, linePoints[i].dy);
        }
        canvas.drawPath(highlightPath, highlightPaint);
      }

      final linePaint = Paint()
        ..color = line.lineColor
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(linePoints[0].dx, linePoints[0].dy);
      for (int i = 1; i < linePoints.length; i++) {
        path.lineTo(linePoints[i].dx, linePoints[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    final outerRingPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final innerPaint = Paint()
      ..color = Colors.grey.shade500
      ..style = PaintingStyle.fill;
    final startPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    final endPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    final transferPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;
    final transferBorderPaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final station in transferStations) {
      final isStart = station.name == startStation;
      final isEnd = station.name == endStation;
      const radius = 14.0;

      canvas.drawCircle(
          Offset(station.x, station.y), radius + 3, outerRingPaint);
      canvas.drawCircle(
          Offset(station.x, station.y), radius, transferPaint);
      canvas.drawCircle(
          Offset(station.x, station.y), radius, transferBorderPaint);

      if (isStart) {
        canvas.drawCircle(
            Offset(station.x, station.y), radius - 2, startPaint);
      } else if (isEnd) {
        canvas.drawCircle(
            Offset(station.x, station.y), radius - 2, endPaint);
      } else {
        canvas.drawCircle(
            Offset(station.x, station.y), 6, innerPaint);
      }
    }

    final allStations = <String, MetroStation>{};
    for (final line in lines) {
      for (final station in line.stations) {
        if (station.transferLines.isEmpty) {
          allStations[station.name] = station;
        }
      }
    }

    final normalPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;
    final smallOuterPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final station in allStations.values) {
      final isStart = station.name == startStation;
      final isEnd = station.name == endStation;

      canvas.drawCircle(
          Offset(station.x, station.y), 7, smallOuterPaint);
      if (isStart) {
        canvas.drawCircle(
            Offset(station.x, station.y), 5, startPaint);
      } else if (isEnd) {
        canvas.drawCircle(
            Offset(station.x, station.y), 5, endPaint);
      } else {
        canvas.drawCircle(
            Offset(station.x, station.y), 4, normalPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MetroLinePainter oldDelegate) {
    return oldDelegate.startStation != startStation ||
        oldDelegate.endStation != endStation;
  }
}

class _FullScreenMetroMap extends StatefulWidget {
  final String? selectedStartStation;
  final String? selectedEndStation;
  final List<MetroLine> metroLines;
  final Function(String station, bool isStart) onStationSelected;

  const _FullScreenMetroMap({
    this.selectedStartStation,
    this.selectedEndStation,
    required this.metroLines,
    required this.onStationSelected,
  });

  @override
  State<_FullScreenMetroMap> createState() => _FullScreenMetroMapState();
}

class _FullScreenMetroMapState extends State<_FullScreenMetroMap> {
  final TransformationController _transformationController =
      TransformationController();
  String? _selectedStartStation;
  String? _selectedEndStation;

  @override
  void initState() {
    super.initState();
    _selectedStartStation = widget.selectedStartStation;
    _selectedEndStation = widget.selectedEndStation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.of(context).size;
      const contentWidth = ShanghaiMetroData.canvasWidth;
      const contentHeight = ShanghaiMetroData.canvasHeight;

      final scaleX = screenSize.width / contentWidth;
      final scaleY = screenSize.height / contentHeight;
      final initialScale = (scaleX < scaleY ? scaleX : scaleY) * 0.78;

      final scaledWidth = contentWidth * initialScale;
      final scaledHeight = contentHeight * initialScale;
      final translateX = (screenSize.width - scaledWidth) / 2;
      final translateY = (screenSize.height - scaledHeight) / 2;

      final matrix = Matrix4.identity()
        ..translate(translateX, translateY)
        ..scale(initialScale);
      _transformationController.value = matrix;
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  List<MetroStation> _getTransferStations() {
    final unique = <String, MetroStation>{};
    for (final line in widget.metroLines) {
      for (final station in line.stations) {
        if (station.transferLines.isNotEmpty &&
            !unique.containsKey(station.name)) {
          unique[station.name] = station;
        }
      }
    }
    return unique.values.toList();
  }

  List<MetroStation> _getAllUniqueStations() {
    final unique = <String, MetroStation>{};
    for (final line in widget.metroLines) {
      for (final station in line.stations) {
        if (!unique.containsKey(station.name)) {
          unique[station.name] = station;
        }
      }
    }
    return unique.values.toList();
  }

  void _selectStation(String stationName) {
    setState(() {
      if (_selectedStartStation == null || _selectedEndStation != null) {
        if (_selectedEndStation != null) {
          _selectedStartStation = stationName;
          _selectedEndStation = null;
        } else {
          _selectedStartStation = stationName;
        }
      } else {
        if (_selectedStartStation == stationName) {
          _selectedStartStation = null;
        } else {
          _selectedEndStation = stationName;
        }
      }
    });
    widget.onStationSelected(stationName, _selectedEndStation == null);
  }

  void _onMapTap(TapUpDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    final matrix = _transformationController.value;
    final inverseMatrix = Matrix4.inverted(matrix);
    final transformed = MatrixUtils.transformPoint(inverseMatrix, localPosition);

    const hitRadius = 30.0;
    MetroStation? closestStation;
    double minDistance = hitRadius;

    final allStations = _getAllUniqueStations();
    for (final station in allStations) {
      final dx = transformed.dx - station.x;
      final dy = transformed.dy - station.y;
      final distance = dx * dx + dy * dy;
      if (distance < minDistance * minDistance) {
        minDistance = distance;
        closestStation = station;
      }
    }

    if (closestStation != null) {
      _selectStation(closestStation.name);
    }
  }

  void _showStationSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _StationSearchSheet(
        metroLines: widget.metroLines,
        selectedStartStation: _selectedStartStation,
        selectedEndStation: _selectedEndStation,
        onStationSelected: (station, isStart) {
          setState(() {
            if (isStart) {
              _selectedStartStation = station;
            } else {
              _selectedEndStation = station;
            }
          });
          widget.onStationSelected(station, isStart);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          GestureDetector(
            onTapUp: _onMapTap,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.2,
              maxScale: 6.0,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              child: Center(
                child: SizedBox(
                  width: ShanghaiMetroData.canvasWidth,
                  height: ShanghaiMetroData.canvasHeight,
                  child: CustomPaint(
                    size: const Size(ShanghaiMetroData.canvasWidth,
                        ShanghaiMetroData.canvasHeight),
                    painter: _FullScreenMetroPainter(
                      lines: widget.metroLines,
                      startStation: _selectedStartStation,
                      endStation: _selectedEndStation,
                      transferStations: _getTransferStations(),
                      scale: _transformationController.value.getMaxScaleOnAxis(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.close,
                      color: colorScheme.onSurface, size: 28),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.scrim.withValues(alpha: 0.6),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.zoom_out_map,
                          color: colorScheme.onSurface, size: 24),
                      onPressed: () {
                        final screenSize = MediaQuery.of(context).size;
                        const cw = ShanghaiMetroData.canvasWidth;
                        const ch = ShanghaiMetroData.canvasHeight;
                        final s =
                            (screenSize.width / cw < screenSize.height / ch
                                    ? screenSize.width / cw
                                    : screenSize.height / ch) *
                                0.78;
                        _transformationController.value = Matrix4.identity()
                          ..scale(s);
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.scrim.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.search,
                          color: Colors.white, size: 24),
                      onPressed: _showStationSearchSheet,
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.scrim.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh,
                          color: Colors.white, size: 24),
                      onPressed: () {
                        setState(() {
                          _selectedStartStation = null;
                          _selectedEndStation = null;
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.scrim.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                if (_selectedStartStation != null ||
                    _selectedEndStation != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        if (_selectedStartStation != null)
                          Expanded(
                            child: _SelectedStationChip(
                              label: _selectedStartStation!,
                              icon: Icons.trip_origin,
                              color: colorScheme.primary,
                              backgroundColor: colorScheme.primaryContainer,
                              onClear: () {
                                setState(() => _selectedStartStation = null);
                              },
                            ),
                          ),
                        if (_selectedStartStation != null &&
                            _selectedEndStation != null)
                          const SizedBox(width: 8),
                        if (_selectedEndStation != null)
                          Expanded(
                            child: _SelectedStationChip(
                              label: _selectedEndStation!,
                              icon: Icons.flag,
                              color: colorScheme.error,
                              backgroundColor: colorScheme.errorContainer,
                              onClear: () {
                                setState(() => _selectedEndStation = null);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _legendDot(Colors.green),
                      const SizedBox(width: 4),
                      const Text('起点', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 14),
                      _legendDot(Colors.red),
                      const SizedBox(width: 4),
                      const Text('终点', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 14),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.grey.shade600, width: 2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('换乘站', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _FullScreenMetroPainter extends CustomPainter {
  final List<MetroLine> lines;
  final String? startStation;
  final String? endStation;
  final List<MetroStation> transferStations;
  final double scale;

  _FullScreenMetroPainter({
    required this.lines,
    this.startStation,
    this.endStation,
    required this.transferStations,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final highlightPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.5)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final line in lines) {
      final linePoints = line.stations.map((s) => Offset(s.x, s.y)).toList();
      if (linePoints.length < 2) continue;

      final startIdx = startStation != null
          ? line.stations.indexWhere((s) => s.name == startStation)
          : -1;
      final endIdx = endStation != null
          ? line.stations.indexWhere((s) => s.name == endStation)
          : -1;

      if (startIdx >= 0 && endIdx >= 0) {
        final fromIdx = startIdx < endIdx ? startIdx : endIdx;
        final toIdx = startIdx < endIdx ? endIdx : startIdx;
        final highlightPath = Path();
        highlightPath.moveTo(linePoints[fromIdx].dx, linePoints[fromIdx].dy);
        for (int i = fromIdx + 1; i <= toIdx; i++) {
          highlightPath.lineTo(linePoints[i].dx, linePoints[i].dy);
        }
        canvas.drawPath(highlightPath, highlightPaint);
      }

      final linePaint = Paint()
        ..color = line.lineColor
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(linePoints[0].dx, linePoints[0].dy);
      for (int i = 1; i < linePoints.length; i++) {
        path.lineTo(linePoints[i].dx, linePoints[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    final outerRingPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final innerPaint = Paint()
      ..color = Colors.grey.shade500
      ..style = PaintingStyle.fill;
    final startPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    final endPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    final transferBgPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;
    final transferBorderPaint = Paint()
      ..color = Colors.grey.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (final station in transferStations) {
      final isStart = station.name == startStation;
      final isEnd = station.name == endStation;
      const radius = 16.0;

      canvas.drawCircle(
          Offset(station.x, station.y), radius + 4, outerRingPaint);
      canvas.drawCircle(
          Offset(station.x, station.y), radius, transferBgPaint);
      canvas.drawCircle(
          Offset(station.x, station.y), radius, transferBorderPaint);

      if (isStart) {
        canvas.drawCircle(
            Offset(station.x, station.y), radius - 3, startPaint);
      } else if (isEnd) {
        canvas.drawCircle(
            Offset(station.x, station.y), radius - 3, endPaint);
      } else {
        canvas.drawCircle(Offset(station.x, station.y), 7, innerPaint);
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: station.name,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(station.x - textPainter.width / 2, station.y + 22),
      );
    }

    final allNormal = <String, MetroStation>{};
    for (final line in lines) {
      for (final station in line.stations) {
        if (station.transferLines.isEmpty) {
          allNormal[station.name] = station;
        }
      }
    }

    final normalPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;
    final smallOuterPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final station in allNormal.values) {
      final isStart = station.name == startStation;
      final isEnd = station.name == endStation;

      canvas.drawCircle(
          Offset(station.x, station.y), 8, smallOuterPaint);
      if (isStart) {
        canvas.drawCircle(
            Offset(station.x, station.y), 6, startPaint);
      } else if (isEnd) {
        canvas.drawCircle(
            Offset(station.x, station.y), 6, endPaint);
      } else {
        canvas.drawCircle(
            Offset(station.x, station.y), 5, normalPaint);
      }

      if (isStart || isEnd) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: station.name,
            style: TextStyle(
              color: isStart ? Colors.green.shade800 : Colors.red.shade800,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(station.x - textPainter.width / 2, station.y + 16),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FullScreenMetroPainter oldDelegate) {
    return oldDelegate.startStation != startStation ||
        oldDelegate.endStation != endStation ||
        oldDelegate.scale != scale;
  }
}

class _StationSearchSheet extends StatefulWidget {
  final List<MetroLine> metroLines;
  final String? selectedStartStation;
  final String? selectedEndStation;
  final Function(String station, bool isStart) onStationSelected;

  const _StationSearchSheet({
    required this.metroLines,
    this.selectedStartStation,
    this.selectedEndStation,
    required this.onStationSelected,
  });

  @override
  State<_StationSearchSheet> createState() => _StationSearchSheetState();
}

class _StationSearchSheetState extends State<_StationSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  String? _filterLineId;

  List<MetroStation> _getFilteredStations() {
    final unique = <String, MetroStation>{};
    for (final line in widget.metroLines) {
      if (_filterLineId != null && line.lineId != _filterLineId) continue;
      for (final station in line.stations) {
        if (!unique.containsKey(station.name)) {
          if (_searchText.isEmpty ||
              station.name.contains(_searchText) ||
              station.name.toLowerCase().contains(_searchText.toLowerCase())) {
            unique[station.name] = station;
          }
        }
      }
    }
    final list = unique.values.toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredStations = _getFilteredStations();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '搜索站点',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: colorScheme.onSurfaceVariant),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchText = v),
                decoration: InputDecoration(
                  hintText: '输入站点名称搜索',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchText = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: '全部',
                    isSelected: _filterLineId == null,
                    color: Colors.grey,
                    onTap: () => setState(() => _filterLineId = null),
                  ),
                  ...widget.metroLines.map((line) => _FilterChip(
                        label: line.lineName,
                        isSelected: _filterLineId == line.lineId,
                        color: line.lineColor,
                        onTap: () => setState(
                            () => _filterLineId = line.lineId),
                      )),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filteredStations.isEmpty
                  ? Center(
                      child: Text(
                        '没有找到匹配的站点',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: filteredStations.length,
                      itemBuilder: (context, index) {
                        final station = filteredStations[index];
                        final isStart =
                            station.name == widget.selectedStartStation;
                        final isEnd =
                            station.name == widget.selectedEndStation;
                        final isTransfer =
                            station.transferLines.isNotEmpty;

                        return ListTile(
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isStart
                                  ? Colors.green
                                  : isEnd
                                      ? Colors.red
                                      : isTransfer
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade200,
                              shape: BoxShape.circle,
                              border: isTransfer
                                  ? Border.all(
                                      color: Colors.grey.shade600, width: 2)
                                  : null,
                            ),
                            child: isTransfer
                                ? const Icon(Icons.transfer_within_a_station,
                                    size: 16)
                                : null,
                          ),
                          title: Text(
                            station.name,
                            style: TextStyle(
                              color: isStart
                                  ? Colors.green
                                  : isEnd
                                      ? Colors.red
                                      : colorScheme.onSurface,
                              fontWeight:
                                  (isStart || isEnd)
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                          ),
                          subtitle: station.transferLines.isNotEmpty
                              ? Text(
                                  station.transferLines
                                      .map((l) => '$l号线')
                                      .join('、'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isStart)
                                const Icon(Icons.trip_origin,
                                    size: 16, color: Colors.green),
                              if (isEnd)
                                const Icon(Icons.flag,
                                    size: 16, color: Colors.red),
                              if (!isStart && !isEnd)
                                TextButton(
                                  onPressed: () {
                                    widget.onStationSelected(
                                        station.name, true);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('设为起点',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              if (!isStart && !isEnd)
                                TextButton(
                                  onPressed: () {
                                    widget.onStationSelected(
                                        station.name, false);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('设为终点',
                                      style: TextStyle(fontSize: 12)),
                                ),
                            ],
                          ),
                          onTap: () {
                            if (widget.selectedStartStation == null ||
                                widget.selectedEndStation != null) {
                              widget.onStationSelected(station.name, true);
                            } else {
                              widget.onStationSelected(station.name, false);
                            }
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? color : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}