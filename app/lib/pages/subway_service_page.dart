import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_travel_app/components/common/bottom_nav_bar.dart';
import 'package:smart_travel_app/services/api_service.dart';
import 'package:smart_travel_app/services/navigation_memory.dart';
import 'package:smart_travel_app/utils/network_manager.dart';

class SubwayServicePage extends StatefulWidget {
  const SubwayServicePage({super.key});

  @override
  State<SubwayServicePage> createState() => _SubwayServicePageState();
}

class _SubwayServicePageState extends State<SubwayServicePage> {
  static const Color _line10 = Color(0xFFB07AB2);
  static const Color _ink = Color(0xFF101828);
  static const Color _muted = Color(0xFF6B6470);
  static const Color _surface = Color(0xFFEAF1FF);
  static const Color _sheet = Color(0xFFFFFFFF);
  static const Color _chipBlue = Color(0xFFDDE8FF);

  final ApiService _apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();

  Map<String, dynamic>? _facilityInfo;
  List<Map<String, dynamic>> _allFacilities = [];
  List<_StationReview> _reviews = [];
  bool _isLoading = true;
  bool _isPathLoading = false;
  String? _error;
  String _stationId = 'shaanxi_south_road';
  int _draftRating = 5;

  @override
  void initState() {
    super.initState();
    _loadAllFacilities();
    _loadStationReviews();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadAllFacilities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _apiService.getAllStationFacilities();
    if (!mounted) return;

    if (response.success && response.data != null) {
      final facilities = response.data!['facilities'];
      if (facilities is List) {
        final list = facilities
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        // 优先使用 NavigationMemory 中的当前站点（从站内导航页同步），
        // 其次回退到列表中的第一个设施
        final rememberedId = NavigationMemory.currentStationId;
        final preferred = rememberedId != null
            ? _findFacility(rememberedId, list)
            : null;
        final current = preferred ??
            _findFacility(_stationId, list) ??
            (list.isEmpty ? null : list.first);

        final nextStationId = current?['stationId']?.toString() ?? _stationId;

        setState(() {
          _allFacilities = list;
          _facilityInfo = current;
          _stationId = nextStationId;
          _isLoading = false;
        });
        await _loadStationReviews(nextStationId);
        return;
      }
    }

    await _loadFromSingleApi();
  }

  Map<String, dynamic>? _findFacility(
    String stationId, [
    List<Map<String, dynamic>>? source,
  ]) {
    for (final facility in source ?? _allFacilities) {
      if (facility['stationId']?.toString() == stationId) {
        return facility;
      }
    }
    return null;
  }

  Future<void> _loadFromSingleApi() async {
    final response = await _apiService.getStationFacilities(_stationId);
    if (!mounted) return;

    if (response.success && response.data != null) {
      final facility = response.data!['facility'];
      if (facility is Map) {
        setState(() {
          _facilityInfo = Map<String, dynamic>.from(facility);
          _isLoading = false;
          _error = null;
        });
        await _loadStationReviews(_stationId);
        return;
      }
    }

    setState(() {
      _error = response.error ?? '站点设施信息不存在';
      _isLoading = false;
    });
  }

  void _selectStation(String stationId) {
    final local = _findFacility(stationId);
    setState(() {
      _stationId = stationId;
      _facilityInfo = local;
      _isLoading = local == null;
      _error = null;
    });
    _commentController.clear();
    _loadStationReviews(stationId);
    if (local == null) _loadFromSingleApi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFFF1F4FF),
        foregroundColor: _line10,
        automaticallyImplyLeading: false,
        title: Text(
          _stationName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF7E4387),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            _buildErrorState()
          else
            _buildContent(),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildContent() {
    if (_facilityInfo == null) {
      return const Center(child: Text('暂无设施数据'));
    }

    return RefreshIndicator(
      onRefresh: _loadAllFacilities,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 108),
        child: Column(
          children: [
            _buildStationHeaderCard(),
            const SizedBox(height: 24),
            _buildServiceGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildStationHeaderCard() {
    final lines = _lineIdsOf(_facilityInfo!);
    final isAutoDetected = NavigationMemory.currentStationId != null &&
        NavigationMemory.currentStationId == _stationId;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFECE3F1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.train_rounded, color: _line10, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _stationName,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAutoDetected
                      ? '已自动定位 · ${lines.map((l) => '$l号线').join('、')}'
                      : lines.isEmpty
                          ? '站点信息'
                          : lines.map((l) => '$l号线').join('、'),
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (isAutoDetected)
            const Icon(Icons.my_location_rounded, color: _line10, size: 24),
        ],
      ),
    );
  }

  Widget _buildServiceGrid() {
    final supportsTopo = _supportsTopology;
    final fromNodeId = NavigationMemory.currentNodeId ?? '20';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            '站内服务',
            style: TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _ServiceIconCard(
                icon: Icons.door_front_door_rounded,
                label: '出入口',
                subtitle: supportsTopo ? '查看出口与导航' : '暂无站内导航数据',
                enabled: supportsTopo,
                onTap: supportsTopo
                    ? () => _openTopologyPath(
                          label: '出入口',
                          fromNodeId: fromNodeId,
                          targetType: 'exit',
                          targetId: '5',
                        )
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _ServiceIconCard(
                icon: Icons.elevator_rounded,
                label: '电梯',
                subtitle: _has('hasElevator')
                    ? '无障碍电梯导航'
                    : supportsTopo
                        ? '暂无电梯数据'
                        : '暂无站内导航数据',
                enabled: supportsTopo && _has('hasElevator'),
                onTap: supportsTopo && _has('hasElevator')
                    ? () => _openTopologyPath(
                          label: '无障碍电梯',
                          fromNodeId: fromNodeId,
                          targetType: 'facility',
                          targetId: 'accessible_elevator_1',
                        )
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ServiceIconCard(
                icon: Icons.wc_rounded,
                label: '洗手间',
                subtitle: _has('hasAccessibleRestroom')
                    ? '洗手间位置导航'
                    : supportsTopo
                        ? '暂无洗手间数据'
                        : '暂无站内导航数据',
                enabled: supportsTopo && _has('hasAccessibleRestroom'),
                onTap: supportsTopo && _has('hasAccessibleRestroom')
                    ? () => _openTopologyPath(
                          label: '公共厕所',
                          fromNodeId: fromNodeId,
                          targetType: 'facility',
                          targetId: 'toilet_1',
                        )
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _ServiceIconCard(
                icon: Icons.support_agent_rounded,
                label: '服务中心',
                subtitle: _has('hasServiceCenter')
                    ? '服务中心导航'
                    : supportsTopo
                        ? '暂无服务中心数据'
                        : '暂无站内导航数据',
                enabled: supportsTopo && _has('hasServiceCenter'),
                onTap: supportsTopo && _has('hasServiceCenter')
                    ? () => _openTopologyPath(
                          label: '服务中心',
                          fromNodeId: fromNodeId,
                          targetType: 'facility',
                          targetId: 'service_center_1',
                        )
                    : null,
              ),
            ),
          ],
        ),
        if (!supportsTopo) ...[
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Icon(Icons.location_off_rounded, size: 48, color: _muted),
                const SizedBox(height: 12),
                const Text(
                  '当前站点暂不支持站内导航',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }


  static String _resolvePhotoUrl(String rawUrl) {
    final value = rawUrl.trim();
    if (value.isEmpty ||
        value.startsWith('http://') ||
        value.startsWith('https://')) {
      return value;
    }
    try {
      final baseUri = Uri.parse(NetworkManager().baseUrl);
      final path = value.startsWith('/') ? value : '/$value';
      return baseUri.replace(path: path, query: '').toString();
    } catch (_) {
      return value;
    }
  }

  Future<void> _openTopologyPath({
    required String label,
    required String fromNodeId,
    String? toNodeId,
    String? targetType,
    String? targetId,
  }) async {
    if (!_supportsTopology || _isPathLoading) return;

    setState(() => _isPathLoading = true);
    final response = await _apiService.getIndoorNavigationPath(
      stationId: _topologyStationId,
      fromNodeId: fromNodeId,
      toNodeId: toNodeId,
      targetType: targetType,
      targetId: targetId,
    );
    if (!mounted) return;
    setState(() => _isPathLoading = false);

    if (!response.success || response.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.error ?? '暂时无法生成站内路径')),
      );
      return;
    }

    _showTopologyPathSheet(label, response.data!);
  }

  void _showTopologyPathSheet(String label, Map<String, dynamic> path) {
    final steps = ((path['steps'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final totalSeconds = (path['totalSeconds'] as num?)?.toInt() ?? 0;
    final targetName =
        (path['targetName'] ?? path['toNodeName'] ?? label).toString();
    final minutes = (totalSeconds / 60).ceil().clamp(1, 999);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.42,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: _sheet,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6DDE8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Color(0xFFECE3F1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.navigation_rounded,
                            color: _line10,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                targetName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '预计 $minutes 分钟 · ${steps.length} 步',
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: steps.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _TopologyStepCard(
                          step: steps[index],
                          index: index,
                          isLast: index == steps.length - 1,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 54, color: _muted),
            const SizedBox(height: 14),
            const Text(
              '后端服务未连接',
              style: TextStyle(
                color: _ink,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '请确认后端地址后重试',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _loadAllFacilities,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  String _reviewStorageKey([String? stationId]) {
    return 'station_reviews_${stationId ?? _stationId}';
  }

  Future<void> _loadStationReviews([String? stationId]) async {
    final targetStationId = stationId ?? _stationId;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_reviewStorageKey(targetStationId));
    final decoded = raw == null ? null : jsonDecode(raw);
    final reviews = decoded is List
        ? decoded
            .whereType<Map>()
            .map((item) =>
                _StationReview.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : <_StationReview>[];

    if (!mounted || targetStationId != _stationId) return;
    setState(() {
      _reviews = reviews;
      _draftRating = 5;
    });
  }

  Future<void> _saveStationReviews() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _reviewStorageKey(),
      jsonEncode(_reviews.map((review) => review.toJson()).toList()),
    );
  }

  Future<void> _submitReview() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先写一点评论内容吧')),
      );
      return;
    }

    final review = _StationReview(
      rating: _draftRating,
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _reviews = [review, ..._reviews].take(20).toList();
      _draftRating = 5;
      _commentController.clear();
    });
    await _saveStationReviews();

    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('评论已发布')),
    );
  }

  double get _reviewAverage {
    if (_reviews.isEmpty) return _baseStationRating;
    final sum = _reviews.fold<int>(0, (total, review) => total + review.rating);
    return sum / _reviews.length;
  }

  double get _baseStationRating {
    var score = 4.1;
    if (_has('hasElevator')) score += 0.15;
    if (_has('hasAccessibleRestroom')) score += 0.15;
    if (_has('hasServiceCenter')) score += 0.1;
    if (_has('hasAED')) score += 0.1;
    if (_has('hasWideGate')) score += 0.1;
    return score.clamp(3.8, 4.8).toDouble();
  }

  Future<void> _openStationPicker() async {
    if (_allFacilities.isEmpty) return;

    String query = '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final stations = _allFacilities.where((facility) {
              final stationName = facility['stationName']?.toString() ?? '';
              final stationId = facility['stationId']?.toString() ?? '';
              final keyword = query.trim().toLowerCase();
              return keyword.isEmpty ||
                  stationName.contains(query.trim()) ||
                  stationId.toLowerCase().contains(keyword);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.76,
              minChildSize: 0.46,
              maxChildSize: 0.92,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: _sheet,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6DDE8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '切换站点',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            IconButton.filledTonal(
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: '搜索站名，例如 陕西南路 / 同济大学',
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            fillColor: const Color(0xFFF0F3FB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) =>
                              setModalState(() => query = value),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                          itemCount: stations.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final station = stations[index];
                            final stationId =
                                station['stationId']?.toString() ?? '';
                            final selected = stationId == _stationId;
                            final lines = _lineIdsOf(station);

                            return Material(
                              color: selected
                                  ? const Color(0xFFFAF2FB)
                                  : const Color(0xFFF8F8FB),
                              borderRadius: BorderRadius.circular(18),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: selected
                                      ? _line10
                                      : const Color(0xFFECE3F1),
                                  child: Icon(
                                    Icons.train_rounded,
                                    color: selected ? Colors.white : _line10,
                                  ),
                                ),
                                title: Text(
                                  station['stationName']?.toString() ?? '',
                                  style: const TextStyle(
                                    color: _ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                subtitle: Text(
                                  lines.map((line) => '$line号线').join('、'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: selected
                                    ? const Icon(Icons.check_circle_rounded,
                                        color: _line10)
                                    : const Icon(Icons.chevron_right_rounded),
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  _selectStation(stationId);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String get _stationName {
    final name = _facilityInfo?['stationName']?.toString().trim();
    return name == null || name.isEmpty ? '地铁设施' : name;
  }

  bool get _supportsTopology =>
      _stationId == _facilityStationId || _stationName.contains('同济大学');

  /// 设施数据中的 stationId（用于匹配已加载的设施列表）
  static const String _facilityStationId = 'tong_ji_university';

  /// 拓扑 API 使用的 stationId（与后端 station_topologies 目录名一致）
  static const String _topologyStationId = 'tongji_university';

  List<String> _lineIdsOf(Map<String, dynamic> facility) {
    final raw = facility['lineIds'];
    if (raw is List) {
      return raw
          .map((line) => line.toString())
          .where((line) => line.isNotEmpty)
          .toList();
    }
    return const [];
  }

  bool _has(String key) => _facilityInfo?[key] == true;

  String? _text(String key) {
    final value = _facilityInfo?[key]?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  String _restroomSubtitle() {
    final parts = <String>[];
    if (_has('hasRestroomInPaid')) parts.add('站内');
    if (_has('hasRestroomOutside')) parts.add('站外');
    if (_has('hasAccessibleRestroom')) parts.add('无障碍');
    return parts.isEmpty ? '暂无标注' : parts.join('与');
  }

  String _serviceSubtitle() {
    final parts = <String>[];
    if (_has('hasServiceCenter')) parts.add('票务处理与咨询');
    if (_has('hasAED')) parts.add('AED');
    return parts.isEmpty ? '暂无标注' : parts.join('、');
  }

  List<_ExitInfo> _exitHighlights() {
    final name = _stationName;
    if (name.contains('陕西南路')) {
      return const [
        _ExitInfo('1', '淮海中路，茂名南路'),
        _ExitInfo('2', 'iapm环贸广场（直达）'),
        _ExitInfo('6', '南昌路，陕西南路'),
      ];
    }
    if (name.contains('同济大学')) {
      return const [
        _ExitInfo('1', '同济联合广场'),
        _ExitInfo('2', '彰武路，赤峰路'),
        _ExitInfo('3', '站厅南侧通道'),
        _ExitInfo('4', '站厅南侧通道'),
        _ExitInfo('5', '四平路，同济大学正门'),
      ];
    }
    if (name.contains('虹桥')) {
      return const [
        _ExitInfo('A', '高铁到达层，虹桥枢纽'),
        _ExitInfo('B', '2号线、17号线换乘'),
        _ExitInfo('C', '出租车，公交枢纽'),
      ];
    }
    if (name.contains('五角场')) {
      return const [
        _ExitInfo('1', '邯郸路，国定路'),
        _ExitInfo('4', '万达广场'),
        _ExitInfo('5', '合生汇，大学路'),
      ];
    }
    return const [
      _ExitInfo('1', '站厅主出口'),
      _ExitInfo('2', '周边地标'),
      _ExitInfo('3', '公交换乘'),
    ];
  }
}

class _TopologyQuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TopologyQuickButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8D9EA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _SubwayServicePageState._line10, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: _SubwayServicePageState._ink,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopologyStepCard extends StatelessWidget {
  final Map<String, dynamic> step;
  final int index;
  final bool isLast;

  const _TopologyStepCard({
    required this.step,
    required this.index,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final title = step['title']?.toString().trim();
    final instruction = step['instruction']?.toString().trim();
    final seconds = (step['seconds'] as num?)?.toInt() ?? 0;
    final rawPhotoUrl = step['photoUrl']?.toString().trim() ?? '';
    final photoUrl =
        rawPhotoUrl.isEmpty ? '' : _SubwayServicePageState._resolvePhotoUrl(rawPhotoUrl);
    final timeText = seconds <= 0 ? '' : '约 ${(seconds / 60).ceil()} 分钟';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E5EC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFECE3F1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: _SubwayServicePageState._line10,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 48,
                  color: const Color(0xFFE1DCE8),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title == null || title.isEmpty ? '站内指引' : title,
                        style: const TextStyle(
                          color: _SubwayServicePageState._ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (timeText.isNotEmpty)
                      Text(
                        timeText,
                        style: const TextStyle(
                          color: _SubwayServicePageState._muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  instruction == null || instruction.isEmpty
                      ? '按站内导向前进'
                      : instruction,
                  style: const TextStyle(
                    color: _SubwayServicePageState._muted,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (photoUrl != null && photoUrl.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 16 / 7,
                      child: Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.add_photo_alternate_rounded,
                                  color: _SubwayServicePageState._line10,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '照片加载失败',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _SubwayServicePageState._muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExitRow extends StatelessWidget {
  final String number;
  final String text;
  final VoidCallback? onTap;

  const _ExitRow({
    required this.number,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _SubwayServicePageState._chipBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                number,
                style: const TextStyle(
                  color: _SubwayServicePageState._ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _SubwayServicePageState._ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              onTap == null
                  ? Icons.chevron_right_rounded
                  : Icons.navigation_rounded,
              color: _SubwayServicePageState._muted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? _SubwayServicePageState._line10 : Colors.grey;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor:
                  enabled ? const Color(0xFFECE3F1) : const Color(0xFFF0F0F2),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color:
                          enabled ? _SubwayServicePageState._ink : Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _SubwayServicePageState._muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              onTap != null && enabled
                  ? Icons.navigation_rounded
                  : enabled
                      ? Icons.check_circle_rounded
                      : Icons.cancel_outlined,
              color: onTap != null && enabled
                  ? _SubwayServicePageState._line10
                  : enabled
                      ? const Color(0xFF35A853)
                      : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _StaticStars extends StatelessWidget {
  final double rating;
  final double size;

  const _StaticStars({
    required this.rating,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final filled = rating >= starValue - 0.25;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          color: _SubwayServicePageState._line10,
          size: size,
        );
      }),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final _StationReview review;

  const _ReviewRow({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFECE3F1),
            child: Text(
              review.content.characters.first.toUpperCase(),
              style: const TextStyle(
                color: _SubwayServicePageState._line10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '本机用户',
                        style: TextStyle(
                          color: _SubwayServicePageState._ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      review.displayTime,
                      style: const TextStyle(
                        color: _SubwayServicePageState._muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _StaticStars(rating: review.rating.toDouble(), size: 15),
                const SizedBox(height: 6),
                Text(
                  review.content,
                  style: const TextStyle(
                    color: _SubwayServicePageState._ink,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
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

class _StationReview {
  final int rating;
  final String content;
  final DateTime createdAt;

  const _StationReview({
    required this.rating,
    required this.content,
    required this.createdAt,
  });

  factory _StationReview.fromJson(Map<String, dynamic> json) {
    return _StationReview(
      rating: (json['rating'] as num?)?.toInt().clamp(1, 5) ?? 5,
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get displayTime {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${createdAt.month}月${createdAt.day}日 ${two(createdAt.hour)}:${two(createdAt.minute)}';
  }
}

class _ExitInfo {
  final String number;
  final String text;

  const _ExitInfo(this.number, this.text);
}

class _ServiceIconCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  const _ServiceIconCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? _SubwayServicePageState._line10
        : Colors.grey;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xFFF0F0F2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                enabled ? const Color(0xFFE8D9EA) : const Color(0xFFE0E0E0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: enabled
                    ? const Color(0xFFECE3F1)
                    : const Color(0xFFE8E8EC),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: enabled
                    ? _SubwayServicePageState._ink
                    : Colors.grey,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: enabled
                    ? _SubwayServicePageState._muted
                    : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
