import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_travel_app/components/common/bottom_nav_bar.dart';
import 'package:smart_travel_app/components/home/line10_interactive_metro_map.dart';
import 'package:smart_travel_app/data/shanghai_metro_data.dart';
import 'package:smart_travel_app/services/api_service.dart';
import 'package:smart_travel_app/services/navigation_memory.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color _line10 = Color(0xFFB07AB2);
  static const Color _ink = Color(0xFF0D1C2F);
  static const Color _muted = Color(0xFF667085);
  static const Color _surface = Color(0xFFF8F9FF);
  static const Color _surfaceBlue = Color(0xFFEFF4FF);
  static const Color _green = Color(0xFF008644);
  static const List<_KnownStationGeo> _knownStationGeos = [
    _KnownStationGeo('同济大学', 31.2821, 121.5063),
    _KnownStationGeo('四平路', 31.2749, 121.5082),
    _KnownStationGeo('五角场', 31.3039, 121.5145),
    _KnownStationGeo('国权路', 31.2895, 121.5104),
    _KnownStationGeo('上海火车站', 31.2495, 121.4555),
    _KnownStationGeo('人民广场', 31.2304, 121.4737),
    _KnownStationGeo('南京东路', 31.2392, 121.4846),
    _KnownStationGeo('虹桥火车站', 31.1943, 121.3189),
    _KnownStationGeo('浦东国际机场', 31.1500, 121.8050),
  ];

  final TextEditingController _startController =
      TextEditingController(text: '同济大学');
  final TextEditingController _endController = TextEditingController();
  final TextEditingController _assistantDestinationController =
      TextEditingController();
  final FocusNode _startFocusNode = FocusNode();
  final FocusNode _endFocusNode = FocusNode();
  final ApiService _apiService = ApiService();
  late final stt.SpeechToText _speechToText = stt.SpeechToText();

  List<Map<String, dynamic>> _travelAlerts = [];
  Map<String, dynamic>? _metroArrival;
  bool _isArrivalLoading = false;

  String _selectedMetroStopId = 'mock-l10-tongji-university';
  String _selectedMetroStopName = '同济大学';
  String _selectedMetroLineId = '10';
  String _selectedMetroLineName = '10号线';
  String? _startStationId = 'mock-l10-tongji-university';
  String? _endStationId;
  _AccessChoice? _startEntrance;
  _AccessChoice? _endExit;
  int _selectedMetroDirection = 0;
  double _arrivalDockHeight = 156;
  bool _isDockDragging = false;
  bool _allowStationTapAutoExpand = true;
  Timer? _arrivalTicker;
  DateTime? _arrivalFetchedAt;
  bool _assistantExpanded = true;
  bool _assistantListening = false;
  bool _assistantBusy = false;
  String _assistantStatus = '说出想去的终点，我会帮你找最近进站口。';
  Position? _lastKnownPosition;
  String? _assistantPreviewStart;
  String? _assistantPreviewEntrance;
  String? _assistantPreviewEnd;
  String? _assistantPreviewExit;

  late final List<_StationSuggestion> _stationSuggestions =
      _buildStationSuggestions();

  @override
  void initState() {
    super.initState();
    _startFocusNode.addListener(_handleRouteFieldFocusChanged);
    _endFocusNode.addListener(_handleRouteFieldFocusChanged);
    _arrivalTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _metroArrival == null) return;
      setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _arrivalTicker?.cancel();
    _startFocusNode
      ..removeListener(_handleRouteFieldFocusChanged)
      ..dispose();
    _endFocusNode
      ..removeListener(_handleRouteFieldFocusChanged)
      ..dispose();
    _startController.dispose();
    _endController.dispose();
    _assistantDestinationController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  void _handleRouteFieldFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isArrivalLoading = true;
      });

      final results = await Future.wait([
        _apiService.getTravelAlerts(),
        _apiService.getMetroArrival(
          stopId: _selectedMetroStopId,
          stopName: _selectedMetroStopName,
          lineId: _arrivalLineId,
          lineName: _selectedMetroLineName,
          direction: _selectedMetroDirection,
        ),
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('请求超时'),
      );

      final alertsResponse = results[0] as ApiResponse<List<dynamic>>;
      final arrivalResponse = results[1] as ApiResponse<Map<String, dynamic>>;

      if (!mounted) return;
      setState(() {
        _travelAlerts = alertsResponse.success && alertsResponse.data != null
            ? List<Map<String, dynamic>>.from(alertsResponse.data!)
            : [];
        final arrivalData =
            arrivalResponse.success && arrivalResponse.data != null
                ? Map<String, dynamic>.from(arrivalResponse.data!)
                : null;
        _metroArrival = arrivalData;
        _arrivalFetchedAt = arrivalData == null ? null : DateTime.now();
        _isArrivalLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isArrivalLoading = false;
        _travelAlerts = [];
        _arrivalFetchedAt = null;
      });
    }
  }

  Future<void> _loadMetroArrival() async {
    setState(() {
      _isArrivalLoading = true;
    });

    final response = await _apiService.getMetroArrival(
      stopId: _selectedMetroStopId,
      stopName: _selectedMetroStopName,
      lineId: _arrivalLineId,
      lineName: _selectedMetroLineName,
      direction: _selectedMetroDirection,
    );

    if (!mounted) return;
    setState(() {
      final arrivalData = response.success && response.data != null
          ? Map<String, dynamic>.from(response.data!)
          : null;
      _metroArrival = arrivalData;
      _arrivalFetchedAt = arrivalData == null ? null : DateTime.now();
      _isArrivalLoading = false;
    });
  }

  void _selectMetroStation(Line10MapStation station) {
    final size = MediaQuery.sizeOf(context);
    setState(() {
      _selectedMetroStopId = station.id;
      _selectedMetroStopName = station.name;
      _selectedMetroLineId = station.lineId;
      _selectedMetroLineName = _lineNameFor(station.lineId);
      if (_allowStationTapAutoExpand) {
        _arrivalDockHeight = _dockMaxHeight(size);
      }
    });
    _loadMetroArrival();
  }

  String get _arrivalLineId {
    final lineId = _selectedMetroLineId == '3-4' ? '3' : _selectedMetroLineId;
    return 'mock-line-$lineId';
  }

  static String _lineNameFor(String lineId) {
    if (lineId == '3-4') return '3/4号线';
    return '$lineId号线';
  }

  static Color _lineColorFor(String lineId) {
    return ShanghaiMetroData.getLineColor(lineId == '3-4' ? '3' : lineId);
  }

  static List<_StationSuggestion> _buildStationSuggestions() {
    final grouped = <String, _StationSuggestion>{};
    for (final line in ShanghaiMetroData.getAllLines()) {
      for (final station in line.stations) {
        final existing = grouped[station.name];
        if (existing == null) {
          grouped[station.name] = _StationSuggestion(
            id: station.id,
            name: station.name,
            lineNames: [line.lineName],
            lineColors: [line.lineColor],
          );
        } else if (!existing.lineNames.contains(line.lineName)) {
          existing.lineNames.add(line.lineName);
          existing.lineColors.add(line.lineColor);
        }
      }
    }
    final suggestions = grouped.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return suggestions;
  }

  List<_StationSuggestion> _matchedStations(String keyword) {
    final query = keyword.trim();
    if (query.isEmpty) return const [];

    final matches = _stationSuggestions.where((station) {
      return station.name.contains(query) ||
          station.lineNames.any((line) => line.contains(query));
    }).toList();

    matches.sort((a, b) {
      final aStarts = a.name.startsWith(query) ? 0 : 1;
      final bStarts = b.name.startsWith(query) ? 0 : 1;
      if (aStarts != bStarts) return aStarts.compareTo(bStarts);
      final aIndex = a.name.indexOf(query);
      final bIndex = b.name.indexOf(query);
      if (aIndex != bIndex) return aIndex.compareTo(bIndex);
      return a.name.length.compareTo(b.name.length);
    });
    return matches.take(6).toList();
  }

  Future<void> _selectSuggestedStation({
    required _StationSuggestion station,
    required bool forStart,
  }) async {
    FocusScope.of(context).unfocus();
    setState(() {
      if (forStart) {
        _startController.text = station.name;
        _startStationId = station.id;
        _startEntrance = null;
      } else {
        _endController.text = station.name;
        _endStationId = station.id;
        _endExit = null;
      }
    });
    await _chooseAccessPoint(forStart: forStart);
  }

  void _disableStationTapAutoExpand() {
    if (!_allowStationTapAutoExpand) return;
    setState(() {
      _allowStationTapAutoExpand = false;
    });
  }

  Future<void> _setSelectedAsStart() async {
    setState(() {
      _startController.text = _selectedMetroStopName;
      _startStationId = _selectedMetroStopId;
      _startEntrance = null;
    });
    await _chooseAccessPoint(forStart: true);
  }

  Future<void> _setSelectedAsEnd() async {
    setState(() {
      _endController.text = _selectedMetroStopName;
      _endStationId = _selectedMetroStopId;
      _endExit = null;
    });
    await _chooseAccessPoint(forStart: false);
  }

  void _goPlanning() {
    final start = _startController.text.trim();
    final end = _endController.text.trim();
    if (start.isEmpty || end.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择起点和终点')),
      );
      return;
    }
    if (_startEntrance == null || _endExit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请补全进站口和出站口')),
      );
      return;
    }
    final location = '/route-plan?start=${Uri.encodeComponent(start)}'
        '&end=${Uri.encodeComponent(end)}'
        '&startId=${Uri.encodeComponent(_startStationId ?? '')}'
        '&endId=${Uri.encodeComponent(_endStationId ?? '')}'
        '&startEntranceId=${Uri.encodeComponent(_startEntrance!.id)}'
        '&startEntranceName=${Uri.encodeComponent(_startEntrance!.label)}'
        '&endExitId=${Uri.encodeComponent(_endExit!.id)}'
        '&endExitName=${Uri.encodeComponent(_endExit!.label)}';
    NavigationMemory.routePlanLocation = location;
    context.go(location);
  }

  Future<void> _toggleAssistantListening() async {
    if (_assistantListening) {
      await _speechToText.stop();
      if (mounted) {
        setState(() {
          _assistantListening = false;
          _assistantStatus = '已停止收音，可以直接开始规划。';
        });
      }
      return;
    }

    final available = await _speechToText.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() => _assistantListening = false);
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _assistantListening = false;
          _assistantStatus = '语音识别暂时不可用，可以手动输入终点。';
        });
      },
    );

    if (!available) {
      if (!mounted) return;
      setState(() {
        _assistantStatus = '没有获得麦克风能力，可以手动输入终点。';
      });
      return;
    }

    setState(() {
      _assistantListening = true;
      _assistantStatus = '正在听你说终点，例如：我要去浦东国际机场。';
    });
    await _speechToText.listen(
      localeId: 'zh_CN',
      onResult: (result) {
        final words = result.recognizedWords.trim();
        if (words.isEmpty || !mounted) return;
        final destination = _extractDestination(words);
        setState(() {
          _assistantDestinationController.text = destination;
          _assistantStatus = result.finalResult
              ? '识别到：$destination'
              : '正在识别：$destination';
        });
        if (result.finalResult) {
          _resolveAssistantDestination(words);
        }
      },
    );
  }

  Future<void> _startAssistantPlan() async {
    final destination = await _resolveAssistantDestination(
      _assistantDestinationController.text.trim(),
    );
    final endStation = _bestStationMatch(destination);
    if (endStation == null) {
      setState(() {
        _assistantStatus = '没有找到“$destination”对应的地铁站，可以换个站名试试。';
      });
      return;
    }

    setState(() {
      _assistantBusy = true;
      _assistantStatus = '正在定位你附近的进站口...';
    });

    final startStation = await _nearestStationByLocation();
    if (!mounted) return;

    final startChoices = await _loadAccessChoices(
      startStation.name,
      stationId: startStation.id,
      forStart: true,
    );
    final endChoices = await _loadAccessChoices(
      endStation.name,
      stationId: endStation.id,
      forStart: false,
    );
    if (!mounted) return;

    final startEntrance = _preferredAccessChoice(
      startChoices,
      preferCampus: startStation.name.contains('同济大学'),
    );
    final endExit = _preferredAccessChoice(endChoices);

    setState(() {
      _startController.text = startStation.name;
      _startStationId = startStation.id;
      _startEntrance = startEntrance;
      _endController.text = endStation.name;
      _endStationId = endStation.id;
      _endExit = endExit;
      _assistantPreviewStart = startStation.name;
      _assistantPreviewEntrance = startEntrance.label;
      _assistantPreviewEnd = endStation.name;
      _assistantPreviewExit = endExit.label;
      _assistantBusy = false;
      _assistantStatus = _lastKnownPosition == null
          ? '已用演示定位推荐${startStation.name}，准备开始规划。'
          : '已定位并推荐${startStation.name}，准备开始规划。';
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _assistantExpanded = false);
    _goPlanning();
  }

  String _extractDestination(String text) {
    var value = text.trim();
    for (final token in ['我要去', '我想去', '带我去', '导航到', '去往', '前往', '到达']) {
      value = value.replaceAll(token, '');
    }
    value = value.replaceAll(RegExp(r'[，。,.!?！？\s]'), '');
    final matched = _bestStationMatch(value);
    return matched?.name ?? value;
  }

  Future<String> _resolveAssistantDestination(String text) async {
    final fallback = _extractDestination(text);
    if (fallback.isEmpty) return fallback;
    final response = await _apiService.parseAssistantDestination(text);
    final stationName = response.data?['stationName']?.toString() ?? '';
    final destination = response.success && stationName.isNotEmpty
        ? stationName
        : fallback;
    if (mounted && destination.isNotEmpty) {
      setState(() {
        _assistantDestinationController.text = destination;
        _assistantStatus = '识别到：$destination';
      });
    }
    return destination;
  }

  _StationSuggestion? _bestStationMatch(String keyword) {
    final query = keyword.trim();
    if (query.isEmpty) return null;
    final matches = _stationSuggestions.where((station) {
      return station.name == query ||
          station.name.contains(query) ||
          query.contains(station.name);
    }).toList()
      ..sort((a, b) {
        final exact = (b.name == query ? 1 : 0) - (a.name == query ? 1 : 0);
        if (exact != 0) return exact;
        return b.name.length.compareTo(a.name.length);
      });
    return matches.isEmpty ? null : matches.first;
  }

  Future<_StationSuggestion> _nearestStationByLocation() async {
    final fallback = _bestStationMatch('同济大学') ?? _stationSuggestions.first;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 2), onTimeout: () => false);
      if (!serviceEnabled) return fallback;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return fallback;
      }

      _lastKnownPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 4),
      );
      final remote = await _apiService.getNearestStation(
        latitude: _lastKnownPosition!.latitude,
        longitude: _lastKnownPosition!.longitude,
      );
      final stationName = remote.data?['stationName']?.toString() ?? '';
      if (remote.success && stationName.isNotEmpty) {
        return _bestStationMatch(stationName) ?? fallback;
      }
      return _nearestKnownStation(_lastKnownPosition!) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  _StationSuggestion? _nearestKnownStation(Position position) {
    _KnownStationGeo? nearest;
    var bestDistance = double.infinity;
    for (final station in _knownStationGeos) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        station.latitude,
        station.longitude,
      );
      if (distance < bestDistance) {
        bestDistance = distance;
        nearest = station;
      }
    }
    if (nearest == null) return null;
    return _bestStationMatch(nearest.name);
  }

  _AccessChoice _preferredAccessChoice(
    List<_AccessChoice> choices, {
    bool preferCampus = false,
  }) {
    if (choices.isEmpty) {
      return const _AccessChoice('1', '1号口', '推荐入口');
    }
    if (preferCampus) {
      for (final choice in choices) {
        if (choice.label.contains('5') ||
            choice.detail.contains('同济') ||
            choice.detail.contains('正门')) {
          return choice;
        }
      }
    }
    return choices.first;
  }

  Future<void> _chooseAccessPoint({required bool forStart}) async {
    final stationName =
        forStart ? _startController.text.trim() : _endController.text.trim();
    if (stationName.isEmpty) return;

    final stationId = forStart ? _startStationId : _endStationId;
    final choices = await _loadAccessChoices(
      stationName,
      stationId: stationId,
      forStart: forStart,
    );
    if (!mounted) return;

    final selected = await showModalBottomSheet<_AccessChoice>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.72;
        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4D9E5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                forStart ? '选择进站口' : '选择出站口',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                stationName,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: choices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final choice = choices[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.pop(sheetContext, choice),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F5FA),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE7D8EA)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _line10,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                choice.shortLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    choice.label,
                                    style: const TextStyle(
                                      color: _ink,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    choice.detail,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: _muted),
                          ],
                        ),
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

    if (selected == null || !mounted) return;
    setState(() {
      if (forStart) {
        _startEntrance = selected;
      } else {
        _endExit = selected;
      }
    });
  }

  Future<List<_AccessChoice>> _loadAccessChoices(
    String stationName, {
    required String? stationId,
    required bool forStart,
  }) async {
    final id = stationId?.trim() ?? '';
    if (id.isNotEmpty) {
      final response = await _apiService.getStationExits(id);
      final data = response.data;
      if (response.success && data != null) {
        final remoteChoices = data
            .whereType<Map>()
            .map((item) => _AccessChoice.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .where((choice) => choice.label.trim().isNotEmpty)
            .toList();
        if (remoteChoices.isNotEmpty) {
          return remoteChoices;
        }
      }
    }
    return _accessChoicesFor(stationName, forStart: forStart);
  }

  List<_AccessChoice> _accessChoicesFor(
    String stationName, {
    required bool forStart,
  }) {
    if (stationName.contains('同济大学')) {
      return const [
        _AccessChoice('1', '1号口', '同济联合广场'),
        _AccessChoice('2', '2号口', '彰武路，赤峰路'),
        _AccessChoice('3', '3号口', '站厅南侧通道'),
        _AccessChoice('4', '4号口', '站厅南侧通道'),
        _AccessChoice('5', '5号口', '四平路，同济大学正门'),
      ];
    }
    if (stationName.contains('虹桥')) {
      return const [
        _AccessChoice('A', 'A口', '高铁到达层，虹桥枢纽'),
        _AccessChoice('B', 'B口', '2号线、17号线换乘'),
        _AccessChoice('C', 'C口', '出租车，公交枢纽'),
      ];
    }
    if (stationName.contains('五角场')) {
      return const [
        _AccessChoice('1', '1号口', '邯郸路，国定路'),
        _AccessChoice('4', '4号口', '万达广场'),
        _AccessChoice('5', '5号口', '合生汇，大学路'),
      ];
    }
    final generatedChoices = _generatedAccessChoicesFor(stationName);
    if (generatedChoices.isNotEmpty) {
      return generatedChoices;
    }
    return forStart
        ? const [
            _AccessChoice('1', '1号口', '默认进站口'),
            _AccessChoice('2', '2号口', '备用进站口'),
          ]
        : const [
            _AccessChoice('1', '1号口', '默认出站口'),
            _AccessChoice('2', '2号口', '备用出站口'),
          ];
  }

  List<_AccessChoice> _generatedAccessChoicesFor(String stationName) {
    final name = stationName.trim();
    if (name.isEmpty) return const [];

    _StationSuggestion? suggestion;
    for (final item in _stationSuggestions) {
      if (item.name == name) {
        suggestion = item;
        break;
      }
    }
    if (suggestion == null) return const [];

    final primaryLine =
        suggestion.lineNames.isEmpty ? '地铁' : suggestion.lineNames.first;
    final transferText = suggestion.lineNames.length > 1
        ? '，可换乘${suggestion.lineNames.skip(1).join('、')}'
        : '';
    final details = <String>[
      '$name站厅主通道，靠近$primaryLine进出站客流$transferText',
      '$name周边道路方向，适合步行离站',
      '$name公交/网约车接驳方向',
      '$name商业及公共服务设施方向',
      '$name无障碍优先通行方向',
    ];
    final labels = const ['A口', 'B口', 'C口', 'D口', 'E口'];
    return List.generate(labels.length, (index) {
      return _AccessChoice(labels[index], labels[index], details[index]);
    });
  }

  double _dockMinHeight(Size size) => size.height < 720 ? 136 : 156;

  double _dockMaxHeight(Size size) =>
      (size.height * 0.42).clamp(270.0, 318.0).toDouble();

  double _resolvedDockHeight(Size size) {
    return _arrivalDockHeight
        .clamp(_dockMinHeight(size), _dockMaxHeight(size))
        .toDouble();
  }

  void _handleDockDragStart(DragStartDetails details) {
    setState(() {
      _isDockDragging = true;
    });
  }

  void _handleDockDragUpdate(DragUpdateDetails details, Size size) {
    final nextHeight = (_arrivalDockHeight - details.delta.dy)
        .clamp(_dockMinHeight(size), _dockMaxHeight(size))
        .toDouble();
    setState(() {
      _arrivalDockHeight = nextHeight;
    });
  }

  void _handleDockDragEnd(DragEndDetails details, Size size) {
    final minHeight = _dockMinHeight(size);
    final maxHeight = _dockMaxHeight(size);
    final velocity = details.primaryVelocity ?? 0;
    final midpoint = minHeight + (maxHeight - minHeight) * 0.42;
    final targetHeight = velocity < -260
        ? maxHeight
        : velocity > 260
            ? minHeight
            : _arrivalDockHeight >= midpoint
                ? maxHeight
                : minHeight;

    setState(() {
      _isDockDragging = false;
      _arrivalDockHeight = targetHeight;
      if (targetHeight == minHeight) {
        _allowStationTapAutoExpand = false;
      }
    });
  }

  double? _arrivalNumber(String key) {
    final value = _metroArrival?[key];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  double _arrivalElapsedSeconds() {
    final fetchedAt = _arrivalFetchedAt;
    if (fetchedAt == null) return 0;
    return DateTime.now().difference(fetchedAt).inSeconds.toDouble();
  }

  int? _remainingMinutesFor(String key) {
    final initialMinutes = _arrivalNumber(key);
    if (initialMinutes == null) return null;
    final remainingSeconds =
        (initialMinutes * 60 - _arrivalElapsedSeconds()).clamp(0.0, 3600.0);
    return (remainingSeconds / 60).ceil().clamp(0, 999).toInt();
  }

  double _arrivalIntervalSeconds() {
    final explicitInterval = _arrivalNumber('interval');
    if (explicitInterval != null && explicitInterval > 0) {
      return (explicitInterval * 60).clamp(90.0, 1200.0).toDouble();
    }

    final current = _arrivalNumber('currentArriveMinutes');
    final next = _arrivalNumber('nextArriveMinutes');
    if (current != null && next != null && next > current) {
      return ((next - current) * 60).clamp(90.0, 1200.0).toDouble();
    }

    return 8 * 60;
  }

  double? _arrivalProgress() {
    final current = _arrivalNumber('currentArriveMinutes');
    if (current == null) return null;

    final remainingSeconds =
        (current * 60 - _arrivalElapsedSeconds()).clamp(0.0, 3600.0);
    final intervalSeconds = _arrivalIntervalSeconds();
    return (1 - remainingSeconds / intervalSeconds)
        .clamp(0.04, 0.98)
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      extendBody: false,
      backgroundColor: _surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: _MapBackground()),
          Positioned.fill(
            child: Line10InteractiveMetroMap(
              selectedStationId: _selectedMetroStopId,
              onStationSelected: _selectMetroStation,
              onMapInteraction: _disableStationTapAutoExpand,
              height: size.height,
              immersive: true,
              showControls: true,
              showHint: false,
              controlsBottomOffset: _resolvedDockHeight(size) + 28,
              labelBottomInset: _resolvedDockHeight(size) + 48,
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: _MapReadabilityVeil()),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _buildTopOverlay(),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: AnimatedContainer(
              duration: _isDockDragging
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: _resolvedDockHeight(size),
              child: _buildArrivalDock(),
            ),
          ),
          _buildVoiceAssistantOverlay(size),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildVoiceAssistantOverlay(Size size) {
    if (!_assistantExpanded) {
      return Positioned(
        left: 10,
        top: size.height * 0.46,
        child: SafeArea(
          child: _AssistantCloudButton(
            onTap: () => setState(() => _assistantExpanded = true),
          ),
        ),
      );
    }

    final top = size.height < 720 ? 116.0 : 132.0;
    return Positioned(
      left: 18,
      right: 18,
      top: top,
      child: SafeArea(
        child: _GlassPanel(
          borderRadius: 26,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _surfaceBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.cloud_rounded,
                      color: _line10,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI 语音助手',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '说出终点，自动推荐进站口和出站口',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '收起',
                    onPressed: () => setState(() => _assistantExpanded = false),
                    icon: const Icon(Icons.close_rounded, color: _muted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE7D8EA)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: _assistantDestinationController.text.isEmpty
                          ? _muted
                          : _line10,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _assistantDestinationController,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _startAssistantPlan(),
                        decoration: const InputDecoration(
                          hintText: '说或输入终点，例如 浦东国际机场',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: _assistantListening ? '停止识别' : '语音输入',
                      onPressed:
                          _assistantBusy ? null : _toggleAssistantListening,
                      icon: Icon(
                        _assistantListening
                            ? Icons.graphic_eq_rounded
                            : Icons.mic_rounded,
                        color: _assistantListening ? _green : _line10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _assistantStatus,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_assistantPreviewStart != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF8F3),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFCFEBDD)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '推荐方案',
                        style: TextStyle(
                          color: _green,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_assistantPreviewStart ?? ''} ${_assistantPreviewEntrance ?? ''} → ${_assistantPreviewEnd ?? ''} ${_assistantPreviewExit ?? ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _assistantBusy
                          ? null
                          : () => setState(() => _assistantExpanded = false),
                      icon: const Icon(Icons.keyboard_hide_rounded, size: 18),
                      label: const Text('稍后再用'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _assistantBusy ? null : _startAssistantPlan,
                      icon: _assistantBusy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.near_me_rounded, size: 18),
                      label: Text(_assistantBusy ? '规划中' : '开始规划'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopOverlay() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GlassPanel(
          borderRadius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: const Row(
            children: [
              Icon(Icons.subway_rounded, color: _line10, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '地铁跑酷换乘助手',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _GlassPanel(
          borderRadius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              _compactRouteField(
                icon: Icons.trip_origin_rounded,
                iconColor: _green,
                controller: _startController,
                focusNode: _startFocusNode,
                hintText: '选择起点',
                forStart: true,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF98A2B3),
                  size: 19,
                ),
              ),
              _compactRouteField(
                icon: Icons.location_on_outlined,
                iconColor: Color(0xFFFF4D5A),
                controller: _endController,
                focusNode: _endFocusNode,
                hintText: '选择终点',
                forStart: false,
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 42,
                height: 42,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: _line10,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _goPlanning,
                  child: const Icon(Icons.near_me_rounded, size: 21),
                ),
              ),
            ],
          ),
        ),
        _buildStationSuggestionPanel(),
        const SizedBox(height: 8),
        _buildAccessSummaryBar(),
      ],
    );
  }

  Widget _buildStationSuggestionPanel() {
    final forStart = _startFocusNode.hasFocus;
    final forEnd = _endFocusNode.hasFocus;
    if (!forStart && !forEnd) return const SizedBox.shrink();

    final controller = forStart ? _startController : _endController;
    final matches = _matchedStations(controller.text);
    if (controller.text.trim().isEmpty || matches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _GlassPanel(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          children: [
            for (var i = 0; i < matches.length; i++) ...[
              _stationSuggestionTile(matches[i], forStart: forStart),
              if (i != matches.length - 1)
                const Divider(height: 1, color: Color(0xFFE8DDEA)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stationSuggestionTile(
    _StationSuggestion station, {
    required bool forStart,
  }) {
    final mainColor =
        station.lineColors.isEmpty ? _line10 : station.lineColors.first;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _selectSuggestedStation(
        station: station,
        forStart: forStart,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: mainColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.subway_rounded,
                color: mainColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    station.lineNames.join(' / '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.north_west_rounded,
              color: _muted,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessSummaryBar() {
    return _GlassPanel(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _accessSummaryChip(
              icon: Icons.login_rounded,
              label: _startEntrance?.label ?? '选择进站口',
              active: _startEntrance != null,
              onTap: _startController.text.trim().isEmpty
                  ? null
                  : () => _chooseAccessPoint(forStart: true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _accessSummaryChip(
              icon: Icons.logout_rounded,
              label: _endExit?.label ?? '选择出站口',
              active: _endExit != null,
              onTap: _endController.text.trim().isEmpty
                  ? null
                  : () => _chooseAccessPoint(forStart: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accessSummaryChip({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: active ? Colors.white.withOpacity(0.78) : Colors.white38,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? const Color(0xFFE7D8EA) : Colors.white54,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? _line10 : _muted, size: 16),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? _ink : _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactRouteField({
    required IconData icon,
    required Color iconColor,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required bool forStart,
  }) {
    return Expanded(
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 9),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: (_) {
                  setState(() {
                    if (forStart) {
                      _startStationId = null;
                      _startEntrance = null;
                    } else {
                      _endStationId = null;
                      _endExit = null;
                    }
                  });
                },
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    color: Color(0xFF98A2B3),
                    fontWeight: FontWeight.w700,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrivalDock() {
    final arrival = _metroArrival;
    final hasData = arrival != null;
    final currentMinutes =
        _remainingMinutesFor('currentArriveMinutes')?.toString() ??
            arrival?['currentArriveMinutes']?.toString() ??
            '?';
    final nextMinutes = _remainingMinutesFor('nextArriveMinutes')?.toString() ??
        arrival?['nextArriveMinutes']?.toString() ??
        '?';
    final location =
        _cleanDisplayText(arrival?['trainLocation']?.toString() ?? '未知位置');
    final nextStop = _cleanDisplayText(
        arrival?['trainNextStop']?.toString() ?? _selectedMetroStopName);
    final alertLabel = _displayAlertLabel();
    final size = MediaQuery.sizeOf(context);
    final expanded = _resolvedDockHeight(size) > _dockMaxHeight(size) - 28;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      onVerticalDragStart: _handleDockDragStart,
      onVerticalDragUpdate: (details) => _handleDockDragUpdate(details, size),
      onVerticalDragEnd: (details) => _handleDockDragEnd(details, size),
      child: _GlassPanel(
        borderRadius: 30,
        padding: const EdgeInsets.fromLTRB(18, 9, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4D9E5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 9),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _selectedMetroStopName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _pill(
                            _selectedMetroLineName,
                            _lineColorFor(_selectedMetroLineId),
                            Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasData ? alertLabel : '模拟接口未连接',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasData ? _green : const Color(0xFFBA1A1A),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: '刷新到站时间',
                  onPressed: _loadMetroArrival,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (expanded) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _isArrivalLoading
                        ? const SizedBox(
                            height: 74,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _countdownBlock(
                            currentMinutes: currentMinutes,
                            nextMinutes: nextMinutes,
                            hasData: hasData,
                          ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(width: 126, child: _directionSelector()),
                ],
              ),
              const SizedBox(height: 8),
              _trainTracker(
                location: location,
                nextStop: nextStop,
                progress: _arrivalProgress(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _miniAction(Icons.trip_origin_rounded, '起点', () {
                    _setSelectedAsStart();
                  }),
                  const SizedBox(width: 8),
                  _miniAction(Icons.flag_rounded, '终点', () {
                    _setSelectedAsEnd();
                  }),
                  const SizedBox(width: 8),
                  _miniAction(Icons.elevator_rounded, '设施', () {
                    context.push('/subway-service');
                  }),
                ],
              ),
            ] else
              _compactArrivalSummary(
                currentMinutes: currentMinutes,
                nextMinutes: nextMinutes,
                hasData: hasData,
              ),
          ],
        ),
      ),
    );
  }

  String _displayAlertLabel() {
    if (_travelAlerts.isEmpty) return '10号线运行正常';
    final rawTitle = (_travelAlerts.first['title'] ?? '实时提醒').toString();
    final repaired = _cleanDisplayText(rawTitle);
    if (_looksLikeMojibake(repaired) || repaired.trim().isEmpty) {
      return '10号线运行正常';
    }
    return repaired;
  }

  String _cleanDisplayText(String value) {
    if (!_looksLikeMojibake(value)) return value;
    try {
      final repaired = utf8.decode(latin1.encode(value));
      return repaired.trim().isEmpty ? value : repaired;
    } catch (_) {
      return value;
    }
  }

  bool _looksLikeMojibake(String value) {
    return value.contains('Ã') ||
        value.contains('Â') ||
        value.contains('å') ||
        value.contains('ç') ||
        value.contains('æ') ||
        value.contains('é');
  }

  Widget _compactArrivalSummary({
    required String currentMinutes,
    required String nextMinutes,
    required bool hasData,
  }) {
    final label = _isArrivalLoading
        ? '正在刷新到站时间'
        : hasData
            ? '最近一班 $currentMinutes 分钟后，下一班 $nextMinutes 分钟后'
            : '上拉查看到站详情';

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: _surfaceBlue.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD7E3FF)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.train_rounded, color: _line10, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _compactSetButton(
              '起点', Icons.trip_origin_rounded, _setSelectedAsStart),
          const SizedBox(width: 6),
          _compactSetButton('终点', Icons.flag_rounded, _setSelectedAsEnd),
          const SizedBox(width: 6),
          const Icon(
            Icons.keyboard_arrow_up_rounded,
            color: _line10,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _compactSetButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _line10, size: 14),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                color: _ink,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countdownBlock({
    required String currentMinutes,
    required String nextMinutes,
    required bool hasData,
  }) {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: _surfaceBlue.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD7E3FF)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            hasData ? currentMinutes : '--',
            style: const TextStyle(
              color: _line10,
              fontSize: 46,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 5, bottom: 4),
            child: Text(
              '分钟',
              style: TextStyle(
                color: _line10,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '下一班',
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                hasData ? '$nextMinutes 分钟' : '--',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _directionSelector() {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1F7),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          _directionChip('往基隆路', 0),
          const SizedBox(height: 5),
          _directionChip('反方向', 1),
        ],
      ),
    );
  }

  Widget _directionChip(String label, int value) {
    final selected = _selectedMetroDirection == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (selected) return;
          setState(() {
            _selectedMetroDirection = value;
          });
          _loadMetroArrival();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _line10 : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : _muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _trainTracker({
    required String location,
    required String nextStop,
    required double? progress,
  }) {
    return Row(
      children: [
        const Icon(Icons.train_rounded, color: _line10, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _arrivalProgressBar(progress),
              const SizedBox(height: 5),
              Text(
                '$location → $nextStop',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _arrivalProgressBar(double? progress) {
    if (progress == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          minHeight: 6,
          color: _line10,
          backgroundColor: const Color(0xFFD1C2CD),
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: progress),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final fillWidth = (width * value).clamp(18.0, width).toDouble();
            final trainLeft =
                (fillWidth - 10).clamp(0.0, width - 18).toDouble();

            return SizedBox(
              height: 18,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 7,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1C2CD),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 7,
                    child: Container(
                      width: fillWidth,
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFB07AB2),
                            Color(0xFFC48AC5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: _line10.withOpacity(0.28),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: trainLeft,
                    top: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _line10, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _line10.withOpacity(0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.train_rounded,
                        color: _line10,
                        size: 11,
                      ),
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

  Widget _miniAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: _MiniActionButton(
        icon: icon,
        label: label,
        color: _line10,
        onTap: onTap,
      ),
    );
  }

  Widget _pill(String label, Color color, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MiniActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MiniActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_MiniActionButton> createState() => _MiniActionButtonState();
}

class _MiniActionButtonState extends State<_MiniActionButton> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed) return;
    setState(() {
      _pressed = pressed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.94 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        height: 42,
        decoration: BoxDecoration(
          color: _pressed
              ? widget.color.withOpacity(0.16)
              : Colors.white.withOpacity(0.62),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _pressed
                ? widget.color.withOpacity(0.42)
                : Colors.white.withOpacity(0.7),
          ),
          boxShadow: [
            if (!_pressed)
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            splashColor: widget.color.withOpacity(0.16),
            highlightColor: widget.color.withOpacity(0.08),
            onTap: widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: _pressed ? 1.08 : 1,
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOutCubic,
                  child: Icon(widget.icon, color: widget.color, size: 18),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: _HomePageState._ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapBackground extends StatelessWidget {
  const _MapBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8F9FF),
            Color(0xFFEFF4FF),
            Color(0xFFFFFFFF),
          ],
        ),
      ),
      child: CustomPaint(painter: _GridPainter()),
    );
  }
}

class _MapReadabilityVeil extends StatelessWidget {
  const _MapReadabilityVeil();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.28),
            Colors.white.withOpacity(0.02),
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.42),
          ],
          stops: const [0, 0.28, 0.62, 1],
        ),
      ),
    );
  }
}

class _AssistantCloudButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AssistantCloudButton({required this.onTap});

  @override
  State<_AssistantCloudButton> createState() => _AssistantCloudButtonState();
}

class _AssistantCloudButtonState extends State<_AssistantCloudButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dy = lerpDouble(-3, 3, _controller.value) ?? 0;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.onTap,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.88),
              border: Border.all(color: const Color(0xFFE7D8EA)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B4A7F).withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.cloud_rounded,
              color: Color(0xFFB07AB2),
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCCDBF4).withOpacity(0.34)
      ..strokeWidth = 1;
    const step = 42.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const _GlassPanel({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(0.7)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B4A7F).withOpacity(0.08),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class _AccessChoice {
  final String id;
  final String label;
  final String detail;

  const _AccessChoice(this.id, this.label, this.detail);

  factory _AccessChoice.fromJson(Map<String, dynamic> json) {
    final rawId =
        (json['id'] ?? json['exitId'] ?? json['exit_id'] ?? '').toString();
    final rawLabel = (json['name'] ??
            json['label'] ??
            json['exitName'] ??
            json['exit_name'] ??
            rawId)
        .toString();
    final rawDetail = (json['detail'] ??
            json['guideTip'] ??
            json['guide_tip'] ??
            json['nearbyPlace'] ??
            json['nearby_place'] ??
            '')
        .toString();
    return _AccessChoice(
      rawId.isEmpty ? rawLabel : rawId,
      rawLabel,
      rawDetail.isEmpty ? '站内出口' : rawDetail,
    );
  }

  String get shortLabel => id;
}

class _KnownStationGeo {
  final String name;
  final double latitude;
  final double longitude;

  const _KnownStationGeo(this.name, this.latitude, this.longitude);
}

class _StationSuggestion {
  final String id;
  final String name;
  final List<String> lineNames;
  final List<Color> lineColors;

  const _StationSuggestion({
    required this.id,
    required this.name,
    required this.lineNames,
    required this.lineColors,
  });
}
