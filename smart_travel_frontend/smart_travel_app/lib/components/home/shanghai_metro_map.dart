import 'package:flutter/material.dart';
import 'package:smart_travel_app/theme/app_theme.dart';

class ShanghaiMetroMap extends StatefulWidget {
  final Function(String station, bool isStart)? onStationSelected;
  final String? initialStartStation;
  final String? initialEndStation;

  const ShanghaiMetroMap({
    super.key,
    this.onStationSelected,
    this.initialStartStation,
    this.initialEndStation,
  });

  @override
  State<ShanghaiMetroMap> createState() => _ShanghaiMetroMapState();
}

class _ShanghaiMetroMapState extends State<ShanghaiMetroMap> {
  String? _selectedStartStation = '同济大学';
  String? _selectedEndStation;
  final TransformationController _thumbnailController =
      TransformationController();

  static const List<String> _commonStations = [
    '同济大学',
    '国权路',
    '外环路',
    '莲花路',
    '锦江乐园',
    '上海南站',
    '漕宝路',
    '上海体育馆',
    '徐家汇',
    '衡山路',
    '常熟路',
    '陕西南路',
    '黄陂南路',
    '人民广场',
    '新闸路',
    '上海火车站',
    '中山北路',
    '徐泾东',
    '虹桥火车站',
    '虹桥2号航站楼',
    '淞虹路',
    '北新泾',
    '威宁路',
    '娄山关路',
    '中山公园',
    '江苏路',
    '静安寺',
    '南京西路',
    '陆家嘴',
    '世纪大道',
    '龙阳路',
    '张江高科',
    '金科路',
    '广兰路',
    '浦东机场',
    '浦东大道',
    '东昌路',
    '商城路',
    '蓝村路',
    '浦电路',
    '肇嘉浜路',
    '交通大学',
    '伊犁路',
    '宋园路',
    '虹桥路',
    '虹口足球场',
    '东宝兴路',
    '宝山路',
    '中潭路',
    '镇坪路',
    '曹杨路',
    '金沙江路',
    '隆德路',
    '东安路',
    '大木桥路',
    '嘉善路',
    '东方体育中心',
    '凌兆新村',
    '芦恒路',
    '浦江镇',
    '江月路',
    '联航路',
    '沈杜公路',
    '望园路',
    '金海湖',
    '奉贤新城',
    '罗山路',
    '御桥路',
    '浦三路',
    '三林镇',
    '上南路',
    '杨思',
    '耀华路',
    '长清路',
    '高科西路',
    '锦绣路',
    '芳草路',
    '北蔡',
    '陈春路',
    '莲溪路',
    '芳华路',
    '培华路',
    '孙桥路',
    '张江路',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStartStation = widget.initialStartStation;
    _selectedEndStation = widget.initialEndStation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      const scale = 3.0;
      final translateX = -1200.0;
      final translateY = -400.0;
      final matrix = Matrix4.identity()
        ..translate(translateX, translateY)
        ..scale(scale);
      _thumbnailController.value = matrix;
    });
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
        barrierColor: colorScheme.scrim.withOpacity(0.8),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenMetroMap(
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
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _showStationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _StationPickerSheet(
          scrollController: scrollController,
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
      ),
    );
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
            Text(
              '上海地铁图',
              style: AppTheme.headline3.copyWith(
                color: colorScheme.onSurface,
              ),
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.trip_origin,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedStartStation!,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedStartStation = null;
                              });
                            },
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_selectedStartStation != null &&
                    _selectedEndStation != null)
                  const SizedBox(width: 8),
                if (_selectedEndStation != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.flag,
                            size: 16,
                            color: colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedEndStation!,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedEndStation = null;
                              });
                            },
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        GestureDetector(
          onTap: _openFullScreenMap,
          child: ClipRRect(
            borderRadius: AppTheme.borderRadiusM,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: AppTheme.borderRadiusM,
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Stack(
                children: [
                  InteractiveViewer(
                    transformationController: _thumbnailController,
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Image.asset(
                      'assets/images/shmetro-map.jpg',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colorScheme.surfaceVariant,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.subway,
                                  size: 48,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '上海地铁线路图',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.scrim.withOpacity(0.54),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 14,
                            color: colorScheme.onSurface,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '点击查看大图',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showStationPicker,
            icon: const Icon(Icons.list, size: 18),
            label: const Text('从站点列表选择'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FullScreenMetroMap extends StatefulWidget {
  final String? selectedStartStation;
  final String? selectedEndStation;
  final Function(String station, bool isStart) onStationSelected;

  const _FullScreenMetroMap({
    this.selectedStartStation,
    this.selectedEndStation,
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
      final matrix = Matrix4.identity();
      matrix.translate(0.0, 0.0);
      matrix.scale(1.0);
      _transformationController.value = matrix;
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _showStationPicker();
  }

  void _showStationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _StationPickerSheet(
          scrollController: scrollController,
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
            onTapDown: _handleTapDown,
            onDoubleTap: _showStationPicker,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 5.0,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              child: Center(
                child: Image.asset(
                  'assets/images/shmetro-map.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: colorScheme.surface,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.subway,
                              size: 64,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(height: 16),
                            Text(
                              '上海地铁线路图',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
                  icon:
                      Icon(Icons.close, color: colorScheme.onSurface, size: 28),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.scrim.withOpacity(0.54),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.zoom_out_map,
                          color: colorScheme.onSurface, size: 24),
                      onPressed: () {
                        _transformationController.value = Matrix4.identity()
                          ..scale(1.0);
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.scrim.withOpacity(0.54),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.list,
                          color: colorScheme.onSurface, size: 24),
                      onPressed: _showStationPicker,
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.scrim.withOpacity(0.54),
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
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colorScheme.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.trip_origin,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedStartStation!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedStartStation = null;
                                      });
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_selectedStartStation != null &&
                            _selectedEndStation != null)
                          const SizedBox(width: 8),
                        if (_selectedEndStation != null)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colorScheme.error.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.flag,
                                    size: 16,
                                    color: colorScheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedEndStation!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colorScheme.onErrorContainer,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedEndStation = null;
                                      });
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
}

class _StationPickerSheet extends StatelessWidget {
  final ScrollController scrollController;
  final String? selectedStartStation;
  final String? selectedEndStation;
  final Function(String station, bool isStart) onStationSelected;

  const _StationPickerSheet({
    required this.scrollController,
    this.selectedStartStation,
    this.selectedEndStation,
    required this.onStationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '选择站点',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: _ShanghaiMetroMapState._commonStations.length,
              itemBuilder: (context, index) {
                final station = _ShanghaiMetroMapState._commonStations[index];
                final isStart = selectedStartStation == station;
                final isEnd = selectedEndStation == station;

                return ListTile(
                  title: Text(
                    station,
                    style: TextStyle(
                      color: isStart
                          ? colorScheme.primary
                          : isEnd
                              ? colorScheme.error
                              : colorScheme.onSurface,
                      fontWeight: (isStart || isEnd) ? FontWeight.w600 : null,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isStart)
                        Icon(
                          Icons.trip_origin,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      if (isEnd)
                        Icon(
                          Icons.flag,
                          size: 16,
                          color: colorScheme.error,
                        ),
                    ],
                  ),
                  onTap: () {
                    if (selectedStartStation == null ||
                        selectedEndStation != null) {
                      onStationSelected(station, true);
                    } else {
                      onStationSelected(station, false);
                    }
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
