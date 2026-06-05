import 'package:flutter/material.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';
import 'package:smart_travel_app/components/common/bottom_nav_bar.dart';
import 'package:smart_travel_app/services/api_service.dart';

class SubwayServicePage extends StatefulWidget {
  const SubwayServicePage({super.key});

  @override
  State<SubwayServicePage> createState() => _SubwayServicePageState();
}

class _SubwayServicePageState extends State<SubwayServicePage> {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _facilityInfo;
  List<Map<String, dynamic>> _allFacilities = [];
  bool _isLoading = true;
  String? _error;
  String _stationId = 'tong_ji_university';
  bool _showStationSelector = false;

  @override
  void initState() {
    super.initState();
    _loadAllFacilities();
  }

  Future<void> _loadAllFacilities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _apiService.getAllStationFacilities();
    if (response.success && response.data != null) {
      final facilities = response.data!['facilities'];
      if (facilities is List) {
        final list = facilities.cast<Map<String, dynamic>>();
        setState(() {
          _allFacilities = list;
          _loadFacilityInfo();
        });
        return;
      }
    }
    setState(() {
      _error = response.error ?? '加载失败';
      _isLoading = false;
    });
  }

  void _loadFacilityInfo() {
    final match = _allFacilities.where(
      (f) => f['stationId'] == _stationId,
    );
    if (match.isNotEmpty) {
      setState(() {
        _facilityInfo = match.first;
        _isLoading = false;
      });
    } else {
      _loadFromSingleApi();
    }
  }

  Future<void> _loadFromSingleApi() async {
    final response = await _apiService.getStationFacilities(_stationId);
    if (response.success && response.data != null) {
      final facility = response.data!['facility'];
      if (facility is Map<String, dynamic>) {
        setState(() {
          _facilityInfo = facility;
          _isLoading = false;
        });
        return;
      }
    }
    setState(() {
      _error = response.error ?? '站点设施信息不存在';
      _isLoading = false;
    });
  }

  void _selectStation(String stationId) {
    setState(() {
      _stationId = stationId;
      _showStationSelector = false;
      _isLoading = true;
    });
    _loadFacilityInfo();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const TopNavBar(title: '地铁人性化服务'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off,
                          size: 48, color: colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text(
                        '后端服务未连接',
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '请前往 个人中心 → 设置 → 服务配置 设置后端地址',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAllFacilities,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _facilityInfo == null
                  ? const Center(child: Text('暂无设施数据'))
                  : _buildContent(colorScheme, textTheme),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildContent(ColorScheme colorScheme, TextTheme textTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStationHeader(colorScheme, textTheme),
          const SizedBox(height: 16),
          _buildAccessibilitySection(colorScheme, textTheme),
          const SizedBox(height: 16),
          _buildRestroomSection(colorScheme, textTheme),
          const SizedBox(height: 16),
          _buildElevatorSection(colorScheme, textTheme),
          const SizedBox(height: 16),
          _buildOtherFacilities(colorScheme, textTheme),
          const SizedBox(height: 16),
          _buildFacilityNote(colorScheme, textTheme),
          const SizedBox(height: 16),
          _buildStationSelector(colorScheme, textTheme),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStationHeader(ColorScheme colorScheme, TextTheme textTheme) {
    final lineIds = (_facilityInfo!['lineIds'] as List<dynamic>?) ?? [];
    final lineNames = lineIds.map((l) => '$l号线').join('、');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.train, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _facilityInfo!['stationName'] ?? '未知站点',
                    style: textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lineNames.isNotEmpty ? lineNames : '',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.swap_horiz, color: colorScheme.primary),
              onPressed: () {
                setState(() => _showStationSelector = !_showStationSelector);
              },
              tooltip: '切换站点',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessibilitySection(
      ColorScheme colorScheme, TextTheme textTheme) {
    final items = <_FacilityItem>[];

    final hasElevator = _facilityInfo!['hasElevator'] == true;
    final elevatorCount = _facilityInfo!['elevatorCount'] ?? 0;
    items.add(_FacilityItem(
      icon: Icons.elevator,
      label: hasElevator ? '无障碍电梯 ($elevatorCount部)' : '无障碍电梯',
      status: hasElevator,
      detail: _facilityInfo!['elevatorLocation']?.toString(),
    ));

    final hasWheelchairRamp = _facilityInfo!['hasWheelchairRamp'] == true;
    items.add(_FacilityItem(
      icon: Icons.accessible,
      label: '轮椅坡道',
      status: hasWheelchairRamp,
    ));

    final hasWideGate = _facilityInfo!['hasWideGate'] == true;
    items.add(_FacilityItem(
      icon: Icons.door_sliding,
      label: '宽闸机通道',
      status: hasWideGate,
    ));

    final hasBlindPath = _facilityInfo!['hasBlindPath'] == true;
    items.add(_FacilityItem(
      icon: Icons.route_outlined,
      label: '盲道',
      status: hasBlindPath,
    ));

    final hasEscalator = _facilityInfo!['hasEscalator'] == true;
    items.add(_FacilityItem(
      icon: Icons.escalator,
      label: '自动扶梯',
      status: hasEscalator,
    ));

    return _buildSectionCard(
      title: '无障碍设施',
      icon: Icons.accessibility_new,
      colorScheme: colorScheme,
      textTheme: textTheme,
      children: items
          .map((item) => _buildFacilityRow(colorScheme, textTheme, item))
          .toList(),
    );
  }

  Widget _buildRestroomSection(ColorScheme colorScheme, TextTheme textTheme) {
    final items = <_FacilityItem>[];

    final hasAccessibleRestroom =
        _facilityInfo!['hasAccessibleRestroom'] == true;
    items.add(_FacilityItem(
      icon: Icons.wc,
      label: '无障碍卫生间',
      status: hasAccessibleRestroom,
      detail: _facilityInfo!['restroomLocation']?.toString(),
    ));

    final hasRestroomInPaid = _facilityInfo!['hasRestroomInPaid'] == true;
    items.add(_FacilityItem(
      icon: Icons.meeting_room_outlined,
      label: '费区内卫生间',
      status: hasRestroomInPaid,
    ));

    final hasRestroomOutside = _facilityInfo!['hasRestroomOutside'] == true;
    items.add(_FacilityItem(
      icon: Icons.meeting_room,
      label: '费区外卫生间',
      status: hasRestroomOutside,
    ));

    final hasMotherBabyRoom = _facilityInfo!['hasMotherBabyRoom'] == true;
    items.add(_FacilityItem(
      icon: Icons.child_care,
      label: '母婴室',
      status: hasMotherBabyRoom,
    ));

    final hasThirdBathroom = _facilityInfo!['hasThirdBathroom'] == true;
    items.add(_FacilityItem(
      icon: Icons.family_restroom,
      label: '第三卫生间',
      status: hasThirdBathroom,
    ));

    return _buildSectionCard(
      title: '卫生间设施',
      icon: Icons.wc,
      colorScheme: colorScheme,
      textTheme: textTheme,
      children: items
          .map((item) => _buildFacilityRow(colorScheme, textTheme, item))
          .toList(),
    );
  }

  Widget _buildElevatorSection(ColorScheme colorScheme, TextTheme textTheme) {
    final location = _facilityInfo!['elevatorLocation']?.toString();
    if (location == null || location.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      title: '电梯位置指引',
      icon: Icons.location_on,
      colorScheme: colorScheme,
      textTheme: textTheme,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline,
                  size: 18, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  location,
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtherFacilities(ColorScheme colorScheme, TextTheme textTheme) {
    final items = <_FacilityItem>[];

    final hasAED = _facilityInfo!['hasAED'] == true;
    items.add(_FacilityItem(
      icon: Icons.medical_services,
      label: 'AED急救设备',
      status: hasAED,
    ));

    final hasServiceCenter = _facilityInfo!['hasServiceCenter'] == true;
    items.add(_FacilityItem(
      icon: Icons.support_agent,
      label: '服务中心',
      status: hasServiceCenter,
    ));

    return _buildSectionCard(
      title: '其他设施',
      icon: Icons.more_horiz,
      colorScheme: colorScheme,
      textTheme: textTheme,
      children: items
          .map((item) => _buildFacilityRow(colorScheme, textTheme, item))
          .toList(),
    );
  }

  Widget _buildFacilityNote(ColorScheme colorScheme, TextTheme textTheme) {
    final note = _facilityInfo!['facilityNote']?.toString();
    if (note == null || note.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      title: '备注说明',
      icon: Icons.note,
      colorScheme: colorScheme,
      textTheme: textTheme,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(note,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.primary)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStationSelector(ColorScheme colorScheme, TextTheme textTheme) {
    if (!_showStationSelector) return const SizedBox.shrink();

    final lineGroups = <String, List<Map<String, dynamic>>>{};
    for (final f in _allFacilities) {
      final lineIds = (f['lineIds'] as List<dynamic>?) ?? [];
      for (final line in lineIds) {
        lineGroups.putIfAbsent(line.toString(), () => []);
        if (!lineGroups[line]!.any((e) => e['stationId'] == f['stationId'])) {
          lineGroups[line]!.add(f);
        }
      }
    }

    final lineColors = {
      '2': const Color(0xFF8CC63F),
      '10': const Color(0xFFC7A8E0),
      '11': const Color(0xFF8B0000),
    };

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('选择站点',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _showStationSelector = false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...lineGroups.entries.map((entry) {
              final color = lineColors[entry.key] ?? colorScheme.primary;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${entry.key}号线',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.value.map((f) {
                      final isSelected = f['stationId'] == _stationId;
                      return ChoiceChip(
                        label: Text(
                          f['stationName'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: colorScheme.primary,
                        onSelected: (_) => _selectStation(f['stationId'] ?? ''),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityRow(
      ColorScheme colorScheme, TextTheme textTheme, _FacilityItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            item.icon,
            size: 20,
            color: item.status
                ? Colors.green
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: item.status
                        ? null
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
                if (item.detail != null && item.detail!.isNotEmpty)
                  Text(
                    item.detail!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            item.status ? Icons.check_circle : Icons.cancel_outlined,
            size: 20,
            color: item.status
                ? Colors.green
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

class _FacilityItem {
  final IconData icon;
  final String label;
  final bool status;
  final String? detail;

  _FacilityItem({
    required this.icon,
    required this.label,
    required this.status,
    this.detail,
  });
}
