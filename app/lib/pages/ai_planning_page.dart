import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_travel_app/components/common/bottom_nav_bar.dart';
import 'package:smart_travel_app/services/api_service.dart';
import 'package:smart_travel_app/services/navigation_memory.dart';
import 'package:smart_travel_app/utils/network_manager.dart';

class AIPlanningPage extends StatefulWidget {
  final String? initialStartStation;
  final String? initialEndStation;
  final String? initialStartEntranceId;
  final String? initialStartEntranceName;
  final String? initialEndExitId;
  final String? initialEndExitName;

  const AIPlanningPage({
    super.key,
    this.initialStartStation,
    this.initialEndStation,
    this.initialStartEntranceId,
    this.initialStartEntranceName,
    this.initialEndExitId,
    this.initialEndExitName,
  });

  @override
  State<AIPlanningPage> createState() => _AIPlanningPageState();
}

class _AIPlanningPageState extends State<AIPlanningPage> {
  static const Color _line10 = Color(0xFFB07AB2);
  static const Color _line2 = Color(0xFF73C92D);
  static const Color _ink = Color(0xFF0D1C2F);
  static const Color _muted = Color(0xFF667085);
  static const Color _surface = Color(0xFFEAF1FF);
  static const Color _green = Color(0xFF008C4A);

  final ApiService _apiService = ApiService();

  late final String _startStation;
  late final String _endStation;
  late final String _startEntranceId;
  late final String _endExitId;
  late final String _startEntranceName;
  late final String _endExitName;
  late final bool _hasRoute;
  late final String _entranceNodeId; // 用户进站口的拓扑节点 ID
  int _stepIndex = 0;
  _ProgressStatus? _stepStatus;
  _RouteSummary? _summary;
  List<_NavStep> _guideSteps = [];
  String? _guideLoadNotice;
  Timer? _statusRefreshTimer;
  int _statusRequestId = 0;

  @override
  void initState() {
    super.initState();
    _startStation = widget.initialStartStation?.trim() ?? '';
    _endStation = widget.initialEndStation?.trim() ?? '';
    _startEntranceId = widget.initialStartEntranceId?.trim() ?? '';
    _endExitId = widget.initialEndExitId?.trim() ?? '';
    _startEntranceName = widget.initialStartEntranceName?.trim() ?? '';
    _endExitName = widget.initialEndExitName?.trim() ?? '';
    _hasRoute = _startStation.isNotEmpty && _endStation.isNotEmpty;

    // 将当前 AI 规划页路由写入 NavigationMemory，确保底部导航栏切换
    // "规划"标签页时回到当前页面而非重新创建 route_plan_page
    final params = <String, String>{};
    void add(String k, String v) {
      if (v.isNotEmpty) params[k] = v;
    }

    add('start', _startStation);
    add('end', _endStation);
    add('startEntranceId', _startEntranceId);
    add('startEntranceName', _startEntranceName);
    add('endExitId', _endExitId);
    add('endExitName', _endExitName);
    if (params.isNotEmpty) {
      NavigationMemory.routePlanLocation =
          Uri(path: '/ai-planning', queryParameters: params).toString();
    }

    // 同步站内位置上下文，供服务页自动定位站点与节点
    final stationName = '$_startStation$_endStation';
    if (stationName.contains('同济大学')) {
      // 根据用户选择的进站口解析到拓扑节点（同济大学出口→节点映射）
      _entranceNodeId = _resolveEntranceToNodeId(
        _startEntranceId,
        _startEntranceName,
      );
      NavigationMemory.updateStationContext(
        stationId: 'tong_ji_university', // 匹配设施数据中的 stationId
        stationName: '同济大学',
        // 若服务页已通过"已到达"更新了位置则保留，否则用进站口节点
        nodeId: NavigationMemory.currentNodeId ?? _entranceNodeId,
      );
      // 恢复上次导航步进位置（切 Tab 回来后从同一进度继续）
      _stepIndex = NavigationMemory.lastStepIndex;
    } else {
      _entranceNodeId = '20';
    }

    if (_hasRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadIndoorGuide());
    }
  }

  @override
  void dispose() {
    _statusRefreshTimer?.cancel();
    super.dispose();
    // note: do NOT clear NavigationMemory station context here —
    // dispose() also fires on tab switch via context.go(), which
    // would race ahead of the service page initState and wipe the
    // station ID before the service page can read it.
    // clearStationContext() is called only in _returnToRoutePlan().
  }

  Future<void> _refreshStepStatus() async {
    if (!_hasRoute || _guideSteps.isEmpty) return;
    final requestedStepIndex = _stepIndex;
    final requestId = ++_statusRequestId;
    final response = await _apiService.getIndoorGuideProgress(
      from: _startStation,
      to: _endStation,
      stepIndex: requestedStepIndex,
      startEntranceId: _startEntranceId,
      startEntranceName: _startEntranceName,
      endExitId: _endExitId,
      endExitName: _endExitName,
    );
    if (!mounted ||
        requestedStepIndex != _stepIndex ||
        requestId != _statusRequestId) {
      return;
    }
    final rawStatus = response.data?['status'];
    setState(() {
      _stepStatus = response.success && rawStatus is Map
          ? _ProgressStatus.fromJson(Map<String, dynamic>.from(rawStatus))
          : null;
    });
  }

  Future<void> _loadIndoorGuide() async {
    try {
      final response = await _apiService
          .getIndoorGuide(
            from: _startStation,
            to: _endStation,
            startEntranceId: _startEntranceId,
            startEntranceName: _startEntranceName,
            endExitId: _endExitId,
            endExitName: _endExitName,
          )
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;

      if (!response.success) {
        _useOfflineGuide(response.error ?? '站内指引接口暂时不可用');
        return;
      }

      final rawSteps = response.data?['steps'];
      if (rawSteps is! List) {
        _useOfflineGuide('站内指引数据格式不完整');
        return;
      }

      final steps = rawSteps
          .whereType<Map>()
          .map((item) => _NavStep.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      if (steps.isEmpty) {
        _useOfflineGuide('站内指引暂无可展示步骤');
        return;
      }

      final rawSummary = response.data?['summary'];

      setState(() {
        _guideLoadNotice = null;
        if (rawSummary is Map) {
          _summary =
              _RouteSummary.fromJson(Map<String, dynamic>.from(rawSummary));
        }
        _guideSteps = steps;
        if (_stepIndex >= _guideSteps.length) {
          _stepIndex = _guideSteps.length - 1;
        }
      });
      _syncStepIndexOnly();
      await _refreshStepStatus();
      _startStatusRefreshTimer();
    } catch (_) {
      if (!mounted) return;
      _useOfflineGuide('站内指引加载超时，已切换为本地演示指引');
      _syncStepIndexOnly();
    }
  }

  void _useOfflineGuide(String notice) {
    setState(() {
      _guideLoadNotice = notice;
      _summary = _RouteSummary(
        title: '本地换乘指引',
        durationMinutes: 8,
        transferCount: 0,
        transferText: '按站内标识前往',
        doorHint: _startEntranceName.isNotEmpty ? _startEntranceName : '中部车门',
        lines: const ['演示路线'],
        nextAction: '确认起终点后按页面步骤前进',
      );
      _guideSteps = [
        _NavStep(
          stage: _StepStage.entry,
          lineName: '站内步行',
          lineColor: _green,
          title: '确认出发位置',
          detail: _startEntranceName.isNotEmpty
              ? '优先前往$_startEntranceName。'
              : '按站内标识前往目标线路或换乘通道。',
          imageTitle: '从$_startStation出发',
          imageSubtitle: '先观察站内导向牌和当前出口位置',
          minutes: 1,
          icon: Icons.login_rounded,
          doorHint: _startEntranceName.isNotEmpty ? _startEntranceName : '中部车门',
        ),
        _NavStep(
          stage: _StepStage.transfer,
          lineName: '换乘通道',
          lineColor: _line10,
          title: '前往换乘通道',
          detail: '注意闸机、扶梯和站台方向提示。',
          imageTitle: '沿主通道前进',
          imageSubtitle: '避开逆向客流，携带行李时优先选择无障碍通道',
          minutes: 3,
          icon: Icons.transfer_within_a_station_rounded,
          doorHint: '跟随站内换乘标识',
        ),
        _NavStep(
          stage: _StepStage.exit,
          lineName: '到达区域',
          lineColor: _green,
          title: '到达目标区域',
          detail: _endExitName.isNotEmpty ? '目标出口：$_endExitName。' : '请以现场标识为准。',
          imageTitle: '抵达$_endStation附近',
          imageSubtitle: '按照出口或站台标识完成最后一段步行',
          minutes: 4,
          icon: Icons.flag_rounded,
          targetStation: _endStation,
          doorHint: _endExitName.isNotEmpty ? _endExitName : '目标出口',
        ),
      ];
      _stepIndex = 0;
      _stepStatus = _fallbackStatusFor(_guideSteps.first, _guideSteps);
    });
    _syncStepIndexOnly();
  }

  void _startStatusRefreshTimer() {
    _statusRefreshTimer?.cancel();
    _statusRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshStepStatus(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasRoute) {
      return const Scaffold(
        backgroundColor: _surface,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: _WaitingRouteState(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(currentIndex: 1),
      );
    }

    if (_guideSteps.isEmpty) {
      return const Scaffold(
        backgroundColor: _surface,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: _LoadingGuideState(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(currentIndex: 1),
      );
    }

    final steps = _guideSteps;
    final step = steps[_stepIndex];
    final showSummary = _summary != null && _stepIndex == 0;
    final sceneHeight =
        (MediaQuery.sizeOf(context).height * 0.34).clamp(260.0, 360.0).toDouble();

    return Scaffold(
      backgroundColor: _surface,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                children: [
                  _GuideTopBar(onBack: _returnToRoutePlan),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          _ProgressPanel(
                            status:
                                _stepStatus ?? _fallbackStatusFor(step, steps),
                          ),
                          if (_guideLoadNotice != null) ...[
                            const SizedBox(height: 12),
                            _NoticePanel(message: _guideLoadNotice!),
                          ],
                          if (_hasAccessSelection) ...[
                            const SizedBox(height: 12),
                            _AccessTaskPanel(
                              startStation: _startStation,
                              startEntrance: _startEntranceName,
                              endStation: _endStation,
                              endExit: _endExitName,
                            ),
                          ],
                          if (showSummary) ...[
                            const SizedBox(height: 12),
                            _RouteSummaryPanel(summary: _summary!),
                          ],
                          const SizedBox(height: 12),
                          _InstructionPanel(step: step),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: sceneHeight,
                            child: _ScenePanel(step: step),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_supportsServiceNavigation)
                    _ServiceQuickBar(
                      onTap: (targetType, targetId, label) {
                        _navigateToFacility(targetType, targetId, label);
                      },
                    ),
                  const SizedBox(height: 12),
                  _StepControls(
                    canGoBack: _stepIndex > 0,
                    isLast: _stepIndex == steps.length - 1,
                    onBack: () {
                      setState(() {
                        _stepIndex--;
                        _stepStatus = null;
                      });
                      _syncStationNodeContext();
                      _refreshStepStatus();
                    },
                    onNext: () {
                      if (_stepIndex < steps.length - 1) {
                        setState(() {
                          _stepIndex++;
                          _stepStatus = null;
                        });
                        _syncStationNodeContext();
                        _refreshStepStatus();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  _ProgressStatus _fallbackStatusFor(_NavStep step, List<_NavStep> steps) {
    return _ProgressStatus(
      leadText: step.stage == _StepStage.ride
          ? '${step.remainingStops}站'
          : '${step.minutes}分钟',
      title: step.title,
      subtitle: step.detail,
      progress: ((_stepIndex + 1) / steps.length).clamp(0.05, 1),
      color: step.lineColor,
      icon: step.icon,
      isFallback: true,
    );
  }

  bool get _hasAccessSelection =>
      _startEntranceName.isNotEmpty || _endExitName.isNotEmpty;

  bool get _supportsServiceNavigation {
    final station = _currentStationId;
    return station != null && station.isNotEmpty;
  }

  String? get _currentStationId {
    final name = '$_startStation$_endStation';
    if (name.contains('同济大学')) return 'tongji_university';
    return null;
  }

  String _currentNodeId() {
    if (_guideSteps.isEmpty) {
      return _entranceNodeId;
    }
    final step = _guideSteps[_stepIndex];
    if (step.nodeId != null && step.nodeId!.isNotEmpty) return step.nodeId!;
    if (step.stage == _StepStage.entry) {
      return _entranceNodeId;
    }
    // 尝试从步骤标题中提取出口号（如"五号口地下"→5号口→节点'1'）
    final exitNode = _exitMentionToNodeId(step.title) ??
        _exitMentionToNodeId(step.detail);
    return exitNode ?? '20';
  }

  /// 从文本中提取出口号并映射到拓扑节点（如"5号口地下"→'1'）
  String? _exitMentionToNodeId(String text) {
    final match = RegExp(r'(\d+)\s*号口').firstMatch(text);
    if (match != null) {
      final exitNo = match.group(1)!;
      if (_tongjiExitNodeMap.containsKey(exitNo)) {
        return _tongjiExitNodeMap[exitNo]!;
      }
    }
    return null;
  }

  Future<void> _navigateToFacility(
    String targetType,
    String targetId,
    String label,
  ) async {
    final stationId = _currentStationId;
    if (stationId == null) return;
    // 始终从规划页当前所在进站口位置出发，查看路线不改变实际位置
    final fromNodeId = NavigationMemory.currentNodeId ?? '20';

    final response = await _apiService.getIndoorNavigationPath(
      stationId: stationId,
      fromNodeId: fromNodeId,
      targetType: targetType,
      targetId: targetId,
    );

    if (!mounted || !response.success || response.data == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error ?? '暂时无法生成站内路径')),
        );
      }
      return;
    }

    final toNodeData = response.data!['toNode'];
    final destNodeId = toNodeData is Map ? toNodeData['id']?.toString() : null;

    await _showServicePathSheet(label, response.data!);
    if (!mounted) return;

    final targetName =
        (response.data!['targetName'] ?? response.data!['toNodeName'] ?? label)
            .toString();
    final arrived = await _askArrivedAtFacility(targetName);
    if (arrived == true && destNodeId != null && destNodeId.isNotEmpty) {
      NavigationMemory.currentNodeId = destNodeId;
    }
  }

  Future<void> _showServicePathSheet(String label, Map<String, dynamic> path) {
    final steps = ((path['steps'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final totalSeconds = (path['totalSeconds'] as num?)?.toInt() ?? 0;
    final targetName =
        (path['targetName'] ?? path['toNodeName'] ?? label).toString();
    final minutes = (totalSeconds / 60).ceil().clamp(1, 999);

    return showModalBottomSheet<void>(
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
                color: Colors.white,
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
                        return _ServicePathStepCard(
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

  /// 同济大学出口号→拓扑节点 ID 映射
  static const Map<String, String> _tongjiExitNodeMap = {
    '1': '5',
    '2': '14',
    '3': '10',
    '4': '12',
    '5': '1',
  };

  /// 根据进站口 ID/名称解析到同济大学站内拓扑节点
  String _resolveEntranceToNodeId(String entranceId, String entranceName) {
    // 先从入口 ID 直接匹配
    if (_tongjiExitNodeMap.containsKey(entranceId)) {
      return _tongjiExitNodeMap[entranceId]!;
    }
    // 再从入口名称提取数字（如 "1号口" → "1", "1号口地下" → "1"）
    final match = RegExp(r'(\d+)').firstMatch(entranceName);
    if (match != null && _tongjiExitNodeMap.containsKey(match.group(1))) {
      return _tongjiExitNodeMap[match.group(1)!]!;
    }
    // 回退到站台中心
    return '20';
  }

  /// 仅同步步进索引（页面加载/重建时），不覆盖已确认的站内位置
  void _syncStepIndexOnly() {
    if (_currentStationId != null) {
      NavigationMemory.lastStepIndex = _stepIndex;
    }
  }

  /// 步进时同步索引和拓扑节点（用户主动前进/后退，位置确实变了）
  void _syncStationNodeContext() {
    if (_currentStationId == null) return;
    // 根据当前步骤确定用户所在拓扑节点：
    //   entry 步骤 → 进站口的拓扑节点
    //   其他步骤 → 站台中心（用户已进入站内）
    final nodeId = _currentNodeId();
    NavigationMemory.updateStationContext(nodeId: nodeId);
    NavigationMemory.lastStepIndex = _stepIndex;
  }

  Future<bool?> _askArrivedAtFacility(String targetName) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('已到达？'),
        content: Text('您是否已到达「$targetName」？\n到达后当前位置将同步至此。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('未到达'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('已到达'),
          ),
        ],
      ),
    );
  }

  void _returnToRoutePlan() {
    // 返回路线规划页前，将 NavigationMemory 路由重置为规划页，
    // 确保底部导航栏"规划"标签切换回规划页而非已销毁的 AI 规划页
    NavigationMemory.routePlanLocation = '/route-plan';
    NavigationMemory.clearStationContext();
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/route-plan');
  }
}

class _GuideTopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _GuideTopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: IconButton.filledTonal(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            tooltip: '返回路线方案',
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            '站内一点通',
            style: TextStyle(
              color: _AIPlanningPageState._ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _WaitingRouteState extends StatelessWidget {
  const _WaitingRouteState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _softPanel(),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFECE3F1),
                child: Icon(
                  Icons.route_rounded,
                  color: _AIPlanningPageState._line10,
                  size: 30,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '等待选择路线',
                      style: TextStyle(
                        color: _AIPlanningPageState._ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '请先在首页选择起点和终点，再开始站内指引。',
                      style: TextStyle(
                        color: _AIPlanningPageState._muted,
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
        const Spacer(),
      ],
    );
  }
}

class _AccessTaskPanel extends StatelessWidget {
  final String startStation;
  final String startEntrance;
  final String endStation;
  final String endExit;

  const _AccessTaskPanel({
    required this.startStation,
    required this.startEntrance,
    required this.endStation,
    required this.endExit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _softPanel(),
      child: Row(
        children: [
          _AccessNode(
            icon: Icons.login_rounded,
            title: startEntrance.isEmpty ? '待补进站口' : startEntrance,
            subtitle: startStation,
            color: _AIPlanningPageState._line10,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: _AIPlanningPageState._muted,
              size: 20,
            ),
          ),
          _AccessNode(
            icon: Icons.logout_rounded,
            title: endExit.isEmpty ? '待补出站口' : endExit,
            subtitle: endStation,
            color: _AIPlanningPageState._green,
          ),
        ],
      ),
    );
  }
}

class _NoticePanel extends StatelessWidget {
  final String message;

  const _NoticePanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE0A8)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_rounded,
            color: Color(0xFF9A5A00),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF7A4300),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessNode extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _AccessNode({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AIPlanningPageState._ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AIPlanningPageState._muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

class _LoadingGuideState extends StatelessWidget {
  const _LoadingGuideState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _softPanel(),
          child: const Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: _AIPlanningPageState._line10,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '正在生成站内指引',
                      style: TextStyle(
                        color: _AIPlanningPageState._ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '正在读取后端路线、换乘和到站信息。',
                      style: TextStyle(
                        color: _AIPlanningPageState._muted,
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
        const Spacer(),
      ],
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  final _ProgressStatus status;

  const _ProgressPanel({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _softPanel(),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: status.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Text(
                  status.leadText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: status.color,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(status.icon, color: status.color, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        status.title,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                        style: const TextStyle(
                          color: _AIPlanningPageState._ink,
                          fontSize: 15,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (status.isFallback) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE8CC),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          '兜底数据',
                          style: TextStyle(
                            color: Color(0xFF9A4D00),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: status.progress.clamp(0, 1),
                    minHeight: 9,
                    backgroundColor: const Color(0xFFE8E1EA),
                    color: status.color,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  status.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AIPlanningPageState._muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _RouteSummaryPanel extends StatelessWidget {
  final _RouteSummary summary;

  const _RouteSummaryPanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: _softPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  summary.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AIPlanningPageState._ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${summary.durationMinutes}分钟',
                style: const TextStyle(
                  color: _AIPlanningPageState._line10,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final line in summary.lines)
                _LineChip(
                  label: line,
                  color: _lineColorForName(line),
                ),
              _InfoChip(
                icon: Icons.transfer_within_a_station_rounded,
                label: summary.transferText,
              ),
              _InfoChip(
                icon: Icons.door_sliding_rounded,
                label: summary.doorHint,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.navigation_rounded,
                color: _AIPlanningPageState._muted,
                size: 17,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  summary.nextAction,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AIPlanningPageState._muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineChip extends StatelessWidget {
  final String label;
  final Color color;

  const _LineChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _AIPlanningPageState._line10, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: _AIPlanningPageState._ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionPanel extends StatelessWidget {
  final _NavStep step;

  const _InstructionPanel({required this.step});

  @override
  Widget build(BuildContext context) {
    final shortcutHint = _exitShortcutHint(step);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _softPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: step.lineColor.withOpacity(0.12),
                child: Icon(step.icon, color: step.lineColor, size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: const TextStyle(
                        color: _AIPlanningPageState._ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.detail,
                      style: const TextStyle(
                        color: _AIPlanningPageState._muted,
                        fontSize: 15,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (shortcutHint != null) ...[
            const SizedBox(height: 14),
            _ExitShortcutBanner(hint: shortcutHint),
          ],
        ],
      ),
    );
  }
}

class _ExitShortcutBanner extends StatelessWidget {
  final _ExitShortcutHint hint;

  const _ExitShortcutBanner({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBCE7D1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _AIPlanningPageState._green.withOpacity(0.13),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.alt_route_rounded,
              color: _AIPlanningPageState._green,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hint.title,
                  style: const TextStyle(
                    color: _AIPlanningPageState._green,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hint.detail,
                  style: const TextStyle(
                    color: Color(0xFF245A3B),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
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

class _ScenePanel extends StatelessWidget {
  final _NavStep step;

  const _ScenePanel({required this.step});

  @override
  Widget build(BuildContext context) {
    final shortcutHint = _exitShortcutHint(step);
    final photoUrl = _resolvePhotoUrl(step.photoUrl);
    final assetPhoto = _fallbackPhotoAsset(step);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photoUrl.isNotEmpty)
            Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _AssetScenePhoto(
                  assetPath: assetPhoto,
                  color: step.lineColor,
                );
              },
            )
          else
            _AssetScenePhoto(
              assetPath: assetPhoto,
              color: step.lineColor,
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.02),
                  Colors.black.withOpacity(0.42),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.86),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '实景照片',
                    style: TextStyle(
                      color: _AIPlanningPageState._muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  step.imageTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  step.imageSubtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 18,
            right: 18,
            child: _LineBadge(lineName: step.lineName, color: step.lineColor),
          ),
          if (shortcutHint != null)
            Positioned(
              left: 16,
              right: 74,
              top: 16,
              child: _SceneShortcutTag(hint: shortcutHint),
            ),
        ],
      ),
    );
  }
}

class _SceneShortcutTag extends StatelessWidget {
  final _ExitShortcutHint hint;

  const _SceneShortcutTag({required this.hint});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFC9EEDD)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _AIPlanningPageState._green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shortcut_rounded,
                  color: _AIPlanningPageState._green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '抄近道标记',
                      style: TextStyle(
                        color: _AIPlanningPageState._green,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint.marker,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _AIPlanningPageState._ink,
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepControls extends StatelessWidget {
  final bool canGoBack;
  final bool isLast;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _StepControls({
    required this.canGoBack,
    required this.isLast,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 106,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: canGoBack ? onBack : null,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('上一步'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _AIPlanningPageState._line10,
              side: const BorderSide(color: Color(0xFFD8C2DA)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 62,
            child: FilledButton.icon(
              onPressed: isLast ? null : onNext,
              icon: Icon(isLast
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded),
              label: Text(isLast ? '已到达' : '下一步'),
              style: FilledButton.styleFrom(
                backgroundColor: _AIPlanningPageState._line10,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE4DDE8),
                disabledForegroundColor: _AIPlanningPageState._muted,
                textStyle: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LineBadge extends StatelessWidget {
  final String lineName;
  final Color color;

  const _LineBadge({
    required this.lineName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        lineName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AssetScenePhoto extends StatelessWidget {
  final String assetPath;
  final Color color;

  const _AssetScenePhoto({
    required this.assetPath,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return CustomPaint(painter: _ScenePainter(color: color));
      },
    );
  }
}

class _ScenePainter extends CustomPainter {
  final Color color;

  const _ScenePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final wall = Paint()..color = const Color(0xFFDFE8F7);
    canvas.drawRect(Offset.zero & size, wall);

    final floor = Path()
      ..moveTo(0, size.height * 0.58)
      ..lineTo(size.width, size.height * 0.42)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(floor, Paint()..color = const Color(0xFFC6D2E4));

    final guideLine = Paint()
      ..color = color.withOpacity(0.75)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.18, size.height * 0.76),
      Offset(size.width * 0.78, size.height * 0.45),
      guideLine,
    );

    final sign = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          size.width * 0.12, size.height * 0.12, size.width * 0.56, 42),
      const Radius.circular(8),
    );
    canvas.drawRRect(sign, Paint()..color = const Color(0xFF20304A));

    final arrowPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width * 0.58, size.height * 0.12 + 21);
    canvas.drawLine(
        center.translate(-20, 0), center.translate(14, 0), arrowPaint);
    canvas.drawLine(
        center.translate(14, 0), center.translate(4, -9), arrowPaint);
    canvas.drawLine(
        center.translate(14, 0), center.translate(4, 9), arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

BoxDecoration _softPanel() {
  return BoxDecoration(
    color: Colors.white.withOpacity(0.94),
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

enum _StepStage {
  entry,
  platform,
  ride,
  transfer,
  transferWait,
  exit,
}

class _NavStep {
  final _StepStage stage;
  final String lineName;
  final Color lineColor;
  final String title;
  final String detail;
  final String imageTitle;
  final String imageSubtitle;
  final int minutes;
  final IconData icon;
  final String targetStation;
  final int remainingStops;
  final int totalStops;
  final String doorHint;
  final Map<String, dynamic> arrivalQuery;
  final String photoKey;
  final String photoUrl;
  final String? nodeId;

  const _NavStep({
    required this.stage,
    required this.lineName,
    required this.lineColor,
    required this.title,
    required this.detail,
    required this.imageTitle,
    required this.imageSubtitle,
    required this.minutes,
    required this.icon,
    this.targetStation = '',
    this.remainingStops = 0,
    this.totalStops = 0,
    this.arrivalQuery = const <String, dynamic>{},
    this.doorHint = '车门',
    this.photoKey = '',
    this.photoUrl = '',
    this.nodeId,
  });

  factory _NavStep.fromJson(Map<String, dynamic> json) {
    final rawArrivalQuery = json['arrivalQuery'];
    return _NavStep(
      stage: _stageFromJson(json['stage']),
      lineName: json['lineName']?.toString() ?? '10号线',
      lineColor: _colorFromJson(
        json['lineColor']?.toString(),
        _AIPlanningPageState._line10,
      ),
      title: json['title']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
      imageTitle: json['imageTitle']?.toString() ?? '',
      imageSubtitle: json['imageSubtitle']?.toString() ?? '',
      minutes: _intFromJson(json['minutes'], 1),
      icon: _iconFromJson(json['iconKey']?.toString()),
      targetStation: json['targetStation']?.toString() ?? '',
      remainingStops: _intFromJson(json['remainingStops'], 0),
      totalStops: _intFromJson(json['totalStops'], 0),
      arrivalQuery: rawArrivalQuery is Map
          ? Map<String, dynamic>.from(rawArrivalQuery)
          : const <String, dynamic>{},
      doorHint: json['doorHint']?.toString() ?? '车门',
      photoKey: json['photoKey']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString() ?? '',
      nodeId: json['nodeId']?.toString(),
    );
  }
}

class _RouteSummary {
  final String title;
  final int durationMinutes;
  final int transferCount;
  final String transferText;
  final String doorHint;
  final List<String> lines;
  final String nextAction;

  const _RouteSummary({
    required this.title,
    required this.durationMinutes,
    required this.transferCount,
    required this.transferText,
    required this.doorHint,
    required this.lines,
    required this.nextAction,
  });

  factory _RouteSummary.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'];
    return _RouteSummary(
      title: json['title']?.toString() ?? '',
      durationMinutes: _intFromJson(json['durationMinutes'], 0),
      transferCount: _intFromJson(json['transferCount'], 0),
      transferText: json['transferText']?.toString() ?? '无需换乘',
      doorHint: json['doorHint']?.toString() ?? '中部车门',
      lines: rawLines is List
          ? rawLines.map((item) => item.toString()).toList()
          : const <String>[],
      nextAction: json['nextAction']?.toString() ?? '',
    );
  }
}

class _ExitShortcutHint {
  final String title;
  final String marker;
  final String detail;

  const _ExitShortcutHint({
    required this.title,
    required this.marker,
    required this.detail,
  });
}

_ExitShortcutHint? _exitShortcutHint(_NavStep step) {
  final isExitStep = step.stage == _StepStage.exit ||
      step.title.contains('出站') ||
      step.lineName.contains('出站');
  if (!isExitStep) return null;

  final exitName = _extractExitName(step);
  final marker = '看到“$exitName”导向牌或绿色出站图标后，优先贴右侧通道走';
  return _ExitShortcutHint(
    title: '快速进入提示',
    marker: marker,
    detail: '$marker；不要绕到大厅中央，经过扶梯口后直接切入出口通道，通常能少走一段回头路。',
  );
}

String _extractExitName(_NavStep step) {
  final candidates = [step.title, step.imageTitle, step.detail, step.imageSubtitle];
  final exitPattern = RegExp(r'([A-Za-z]?\d+[A-Za-z]?号口)');
  for (final text in candidates) {
    final match = exitPattern.firstMatch(text);
    if (match != null) {
      return match.group(1)!;
    }
  }
  return '目标出口';
}

String _resolvePhotoUrl(String rawUrl) {
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

String _fallbackPhotoAsset(_NavStep step) {
  switch (step.stage) {
    case _StepStage.entry:
      return 'assets/images/tongji_station_entry.jpg';
    case _StepStage.exit:
      return 'assets/images/tongji_station_exit.jpg';
    case _StepStage.platform:
    case _StepStage.transfer:
    case _StepStage.transferWait:
    case _StepStage.ride:
      return 'assets/images/tongji_station_transfer.jpg';
  }
}

_StepStage _stageFromJson(dynamic value) {
  switch (value?.toString()) {
    case 'entry':
      return _StepStage.entry;
    case 'platform':
      return _StepStage.platform;
    case 'ride':
      return _StepStage.ride;
    case 'transfer':
      return _StepStage.transfer;
    case 'transferWait':
      return _StepStage.transferWait;
    case 'exit':
      return _StepStage.exit;
    default:
      return _StepStage.entry;
  }
}

Color _colorFromJson(String? value, Color fallback) {
  final cleaned = value?.replaceAll('#', '').trim();
  if (cleaned == null || cleaned.length != 6) return fallback;
  final parsed = int.tryParse(cleaned, radix: 16);
  if (parsed == null) return fallback;
  return Color(0xFF000000 | parsed);
}

Color _lineColorForName(String lineName) {
  if (lineName.contains('2')) return _AIPlanningPageState._line2;
  if (lineName.contains('17')) return const Color(0xFFB58A00);
  if (lineName.contains('出站')) return _AIPlanningPageState._green;
  return _AIPlanningPageState._line10;
}

IconData _iconFromJson(String? value) {
  switch (value) {
    case 'login':
      return Icons.login_rounded;
    case 'escalator':
      return Icons.escalator_rounded;
    case 'turnRight':
      return Icons.turn_right_rounded;
    case 'turnLeft':
      return Icons.turn_left_rounded;
    case 'straight':
      return Icons.straight_rounded;
    case 'door':
      return Icons.door_sliding_rounded;
    case 'train':
      return Icons.train_rounded;
    case 'timer':
      return Icons.timer_rounded;
    case 'transfer':
      return Icons.transfer_within_a_station_rounded;
    case 'signpost':
      return Icons.signpost_rounded;
    case 'output':
      return Icons.output_rounded;
    default:
      return Icons.navigation_rounded;
  }
}

int _intFromJson(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

class _ProgressStatus {
  final String leadText;
  final String title;
  final String subtitle;
  final double progress;
  final Color color;
  final IconData icon;
  final bool isFallback;

  const _ProgressStatus({
    required this.leadText,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.color,
    required this.icon,
    required this.isFallback,
  });

  factory _ProgressStatus.fromJson(Map<String, dynamic> json) {
    return _ProgressStatus(
      leadText: json['leadText']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      progress: _doubleFromJson(json['progress'], 0),
      color: _colorFromJson(
        json['color']?.toString(),
        _AIPlanningPageState._line10,
      ),
      icon: _iconFromJson(json['iconKey']?.toString()),
      isFallback: json['isFallback'] == true,
    );
  }
}

double _doubleFromJson(dynamic value, double fallback) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

// -- 中途服务导航组件 -------------------------------------------------

class _ServiceQuickBar extends StatelessWidget {
  final void Function(String targetType, String targetId, String label) onTap;

  const _ServiceQuickBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _QuickIcon(
            icon: Icons.door_front_door_rounded,
            label: '出入口',
            onTap: () => onTap('exit', '5', '出入口'),
          ),
          _QuickIcon(
            icon: Icons.elevator_rounded,
            label: '电梯',
            onTap: () =>
                onTap('facility', 'accessible_elevator_1', '无障碍电梯'),
          ),
          _QuickIcon(
            icon: Icons.wc_rounded,
            label: '洗手间',
            onTap: () => onTap('facility', 'toilet_1', '公共厕所'),
          ),
          _QuickIcon(
            icon: Icons.support_agent_rounded,
            label: '服务中心',
            onTap: () => onTap('facility', 'service_center_1', '服务中心'),
          ),
        ],
      ),
    );
  }
}

class _QuickIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFECE3F1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: _AIPlanningPageState._line10,
                  size: 21,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: _AIPlanningPageState._muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 将后端返回的相对路径（如 /static/...）补全为完整 HTTP URL
String _resolveStaticPhotoUrl(String rawUrl) {
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

class _ServicePathStepCard extends StatelessWidget {
  final Map<String, dynamic> step;
  final int index;
  final bool isLast;

  const _ServicePathStepCard({
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
    final photoUrl = _resolveStaticPhotoUrl(rawPhotoUrl);
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
                    color: _AIPlanningPageState._line10,
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
                          color: _AIPlanningPageState._ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (timeText.isNotEmpty)
                      Text(
                        timeText,
                        style: const TextStyle(
                          color: _AIPlanningPageState._muted,
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
                    color: _AIPlanningPageState._muted,
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.centerLeft,
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_rounded,
                                  color: _AIPlanningPageState._line10,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '照片加载失败',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _AIPlanningPageState._muted,
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
