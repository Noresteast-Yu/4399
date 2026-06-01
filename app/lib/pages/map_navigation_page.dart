import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';
import 'package:smart_travel_app/theme/app_theme.dart';
import 'package:smart_travel_app/services/api_service.dart';

class MapNavigationPage extends StatefulWidget {
  const MapNavigationPage({super.key});

  @override
  State<MapNavigationPage> createState() => _MapNavigationPageState();
}

class _MapNavigationPageState extends State<MapNavigationPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allStations = [];
  List<Map<String, dynamic>> _filteredStations = [];
  Map<String, dynamic>? _selectedStation;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStations();
    _searchController.addListener(_filterStations);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _apiService.getAllStationFacilities();
    if (response.success && response.data != null) {
      final facilities = response.data!['facilities'];
      if (facilities is List) {
        final list = facilities.cast<Map<String, dynamic>>();
        list.sort((a, b) {
          final nameA = a['stationName']?.toString() ?? '';
          final nameB = b['stationName']?.toString() ?? '';
          return nameA.compareTo(nameB);
        });
        if (mounted) {
          setState(() {
            _allStations = list;
            _filteredStations = list;
            _isLoading = false;
          });
        }
        return;
      }
    }
    if (mounted) {
      setState(() {
        _error = response.error ?? '加载失败';
        _isLoading = false;
      });
    }
  }

  void _filterStations() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredStations = _allStations;
      } else {
        _filteredStations = _allStations.where((s) {
          final name = (s['stationName']?.toString() ?? '').toLowerCase();
          final lineIds = s['lineIds'] as List<dynamic>? ?? [];
          final lineMatch = lineIds.any((l) => '${l}号线'.contains(query));
          return name.contains(query) || lineMatch;
        }).toList();
      }
    });
  }

  void _selectStation(Map<String, dynamic> station) {
    setState(() => _selectedStation = station);
  }

  void _navigateToStation(String stationName) {
    context.push('/ai-planning?start=${Uri.encodeComponent(stationName)}');
  }

  int _getFacilityScore(Map<String, dynamic> station) {
    int score = 0;
    if (station['hasElevator'] == true) score += 2;
    if (station['hasAccessibleRestroom'] == true) score += 1;
    if (station['hasMotherBabyRoom'] == true) score += 1;
    if (station['hasThirdBathroom'] == true) score += 1;
    if (station['hasWideGate'] == true) score += 1;
    if (station['hasAED'] == true) score += 1;
    if (station['hasBlindPath'] == true) score += 1;
    if (station['hasServiceCenter'] == true) score += 1;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: TopNavBar(
        title: _selectedStation != null
            ? _selectedStation!['stationName'] ?? '站点详情'
            : '站点探索',
        showBack: _selectedStation != null,
        onBack: _selectedStation != null
            ? () => setState(() => _selectedStation = null)
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text('加载失败: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStations,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _selectedStation != null
                  ? _buildStationDetail(colorScheme, textTheme)
                  : _buildStationList(colorScheme, textTheme),
    );
  }

  Widget _buildStationList(ColorScheme colorScheme, TextTheme textTheme) {
    final groupedByLine = <String, List<Map<String, dynamic>>>{};
    for (final station in _filteredStations) {
      final lineIds = station['lineIds'] as List<dynamic>? ?? [];
      final key = lineIds.isNotEmpty ? lineIds.map((l) => '${l}号线').join('/') : '其他';
      groupedByLine.putIfAbsent(key, () => []);
      groupedByLine[key]!.add(station);
    }

    final sortedKeys = groupedByLine.keys.toList()..sort();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索站点名称或线路...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: AppTheme.borderRadiusM,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.train, size: 18, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                '共 ${_filteredStations.length} 个站点',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
              final lineKey = sortedKeys[index];
              final stations = groupedByLine[lineKey]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      lineKey,
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...stations.map((station) {
                    final score = _getFacilityScore(station);
                    final maxScore = 8;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.borderRadiusM,
                      ),
                      child: ListTile(
                        title: Text(
                          station['stationName'] ?? '',
                          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Row(
                          children: [
                            Icon(Icons.accessible, size: 14, color: colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              '设施覆盖 $score/$maxScore',
                              style: textTheme.bodySmall?.copyWith(
                                color: score >= 6 ? Colors.green : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.info_outline, color: colorScheme.primary),
                              onPressed: () => _selectStation(station),
                              tooltip: '查看设施',
                            ),
                            IconButton(
                              icon: Icon(Icons.navigation, color: colorScheme.secondary),
                              onPressed: () => _navigateToStation(
                                  station['stationName']?.toString() ?? ''),
                              tooltip: '规划路线',
                            ),
                          ],
                        ),
                        onTap: () => _selectStation(station),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStationDetail(ColorScheme colorScheme, TextTheme textTheme) {
    final station = _selectedStation!;
    final stationName = station['stationName'] ?? '';
    final lineIds = (station['lineIds'] as List<dynamic>?) ?? [];
    final lineNames = lineIds.map((l) => '${l}号线').join('、');
    final score = _getFacilityScore(station);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusL),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.train, size: 32, color: colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    stationName.toString(),
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lineNames.isNotEmpty ? lineNames : '',
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: score / 8,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: score >= 6 ? Colors.green : score >= 4 ? Colors.orange : Colors.red,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '设施完善度 $score/8',
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _navigateToStation(stationName.toString()),
                      icon: const Icon(Icons.navigation),
                      label: const Text('从该站出发规划路线'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppTheme.borderRadiusM,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildFacilitySection(
            colorScheme, textTheme, '无障碍设施', Icons.accessibility_new,
            [
              _buildFacilityRow('无障碍电梯', station['hasElevator'] == true,
                  detail: station['elevatorLocation']?.toString()),
              _buildFacilityRow('自动扶梯', station['hasEscalator'] == true),
              _buildFacilityRow('轮椅坡道', station['hasWheelchairRamp'] == true),
              _buildFacilityRow('宽闸机通道', station['hasWideGate'] == true),
              _buildFacilityRow('盲道', station['hasBlindPath'] == true),
            ],
          ),
          const SizedBox(height: 12),
          _buildFacilitySection(
            colorScheme, textTheme, '卫生间设施', Icons.wc,
            [
              _buildFacilityRow('无障碍卫生间', station['hasAccessibleRestroom'] == true,
                  detail: station['restroomLocation']?.toString()),
              _buildFacilityRow('费区内卫生间', station['hasRestroomInPaid'] == true),
              _buildFacilityRow('费区外卫生间', station['hasRestroomOutside'] == true),
              _buildFacilityRow('母婴室', station['hasMotherBabyRoom'] == true),
              _buildFacilityRow('第三卫生间', station['hasThirdBathroom'] == true),
            ],
          ),
          const SizedBox(height: 12),
          _buildFacilitySection(
            colorScheme, textTheme, '其他设施', Icons.more_horiz,
            [
              _buildFacilityRow('AED急救设备', station['hasAED'] == true),
              _buildFacilityRow('服务中心', station['hasServiceCenter'] == true),
            ],
          ),
          if (station['facilityNote'] != null &&
              (station['facilityNote'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Card(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusM),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, size: 18, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          station['facilityNote'] ?? '',
                          style: textTheme.bodySmall?.copyWith(color: colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFacilitySection(
    ColorScheme colorScheme,
    TextTheme textTheme,
    String title,
    IconData icon,
    List<Widget> items,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusM),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityRow(String label, bool available, {String? detail}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle : Icons.cancel_outlined,
            size: 16,
            color: available ? Colors.green : colorScheme.onSurfaceVariant.withOpacity(0.4),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: available ? null : colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                ),
                if (detail != null && detail.isNotEmpty)
                  Text(
                    detail,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
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
