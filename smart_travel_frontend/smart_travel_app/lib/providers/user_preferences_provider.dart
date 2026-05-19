import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  // 出行偏好
  bool _preferLessWalking = false;
  bool _preferLessTransfers = true;
  bool _preferFastestRoute = false;
  bool _avoidCrowdedLines = false;
  String _preferredRouteType = 'fastest'; // fastest, least_transfer, least_walking

  // 行动能力设置
  String _mobilityLevel = 'normal'; // normal, limited, wheelchair
  bool _needElevator = false;
  bool _needEscalator = false;
  bool _avoidStairs = false;
  int _maxWalkingDistance = 500; // 米

  // 行李设置
  bool _hasLuggage = false;
  String _luggageSize = 'small'; // small, medium, large
  int _luggageCount = 0;
  bool _needWideGate = false;

  // Getters
  bool get preferLessWalking => _preferLessWalking;
  bool get preferLessTransfers => _preferLessTransfers;
  bool get preferFastestRoute => _preferFastestRoute;
  bool get avoidCrowdedLines => _avoidCrowdedLines;
  String get preferredRouteType => _preferredRouteType;

  String get mobilityLevel => _mobilityLevel;
  bool get needElevator => _needElevator;
  bool get needEscalator => _needEscalator;
  bool get avoidStairs => _avoidStairs;
  int get maxWalkingDistance => _maxWalkingDistance;

  bool get hasLuggage => _hasLuggage;
  String get luggageSize => _luggageSize;
  int get luggageCount => _luggageCount;
  bool get needWideGate => _needWideGate;

  Future<SharedPreferences> get _prefsInstance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> loadPreferences() async {
    final prefs = await _prefsInstance;
    _preferLessWalking = prefs.getBool('prefer_less_walking') ?? false;
    _preferLessTransfers = prefs.getBool('prefer_less_transfers') ?? true;
    _preferFastestRoute = prefs.getBool('prefer_fastest_route') ?? false;
    _avoidCrowdedLines = prefs.getBool('avoid_crowded_lines') ?? false;
    _preferredRouteType = prefs.getString('preferred_route_type') ?? 'fastest';

    _mobilityLevel = prefs.getString('mobility_level') ?? 'normal';
    _needElevator = prefs.getBool('need_elevator') ?? false;
    _needEscalator = prefs.getBool('need_escalator') ?? false;
    _avoidStairs = prefs.getBool('avoid_stairs') ?? false;
    _maxWalkingDistance = prefs.getInt('max_walking_distance') ?? 500;

    _hasLuggage = prefs.getBool('has_luggage') ?? false;
    _luggageSize = prefs.getString('luggage_size') ?? 'small';
    _luggageCount = prefs.getInt('luggage_count') ?? 0;
    _needWideGate = prefs.getBool('need_wide_gate') ?? false;

    notifyListeners();
  }

  Future<void> setPreferLessWalking(bool value) async {
    _preferLessWalking = value;
    final prefs = await _prefsInstance;
    await prefs.setBool('prefer_less_walking', value);
    notifyListeners();
  }

  Future<void> setPreferLessTransfers(bool value) async {
    _preferLessTransfers = value;
    final prefs = await _prefsInstance;
    await prefs.setBool('prefer_less_transfers', value);
    notifyListeners();
  }

  Future<void> setPreferFastestRoute(bool value) async {
    _preferFastestRoute = value;
    final prefs = await _prefsInstance;
    await prefs.setBool('prefer_fastest_route', value);
    notifyListeners();
  }

  Future<void> setAvoidCrowdedLines(bool value) async {
    _avoidCrowdedLines = value;
    final prefs = await _prefsInstance;
    await prefs.setBool('avoid_crowded_lines', value);
    notifyListeners();
  }

  Future<void> setPreferredRouteType(String value) async {
    _preferredRouteType = value;
    final prefs = await _prefsInstance;
    await prefs.setString('preferred_route_type', value);
    notifyListeners();
  }

  Future<void> setMobilityLevel(String value) async {
    _mobilityLevel = value;
    final prefs = await _prefsInstance;
    await prefs.setString('mobility_level', value);
    _updateMobilitySettings();
    notifyListeners();
  }

  Future<void> setNeedElevator(bool value) async {
    _needElevator = value;
    final prefs = await _prefsInstance;
    await prefs.setBool('need_elevator', value);
    notifyListeners();
  }

  Future<void> setNeedEscalator(bool value) async {
    _needEscalator = value;
    final prefs = await _prefsInstance;
    await prefs.setBool('need_escalator', value);
    notifyListeners();
  }

  Future<void> setAvoidStairs(bool value) async {
    _avoidStairs = value;
    final prefs = await _prefsInstance;
    await prefs.setBool('avoid_stairs', value);
    notifyListeners();
  }

  Future<void> setMaxWalkingDistance(int value) async {
    _maxWalkingDistance = value;
    final prefs = await _prefsInstance;
    await prefs.setInt('max_walking_distance', value);
    notifyListeners();
  }

  Future<void> setHasLuggage(bool value) async {
    _hasLuggage = value;
    final prefs = await _prefsInstance;
    await prefs.setBool('has_luggage', value);
    notifyListeners();
  }

  Future<void> setLuggageSize(String value) async {
    _luggageSize = value;
    final prefs = await _prefsInstance;
    await prefs.setString('luggage_size', value);
    notifyListeners();
  }

  Future<void> setLuggageCount(int value) async {
    _luggageCount = value;
    final prefs = await _prefsInstance;
    await prefs.setInt('luggage_count', value);
    notifyListeners();
  }

  Future<void> setNeedWideGate(bool value) async {
    _needWideGate = value;
    final prefs = await _prefsInstance;
    await prefs.setBool('need_wide_gate', value);
    notifyListeners();
  }

  void _updateMobilitySettings() {
    switch (_mobilityLevel) {
      case 'wheelchair':
        _needElevator = true;
        _avoidStairs = true;
        _needWideGate = true;
        _maxWalkingDistance = 200;
        break;
      case 'limited':
        _needElevator = true;
        _avoidStairs = true;
        _maxWalkingDistance = 300;
        break;
      case 'normal':
        _needElevator = false;
        _avoidStairs = false;
        _maxWalkingDistance = 500;
        break;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'travelPreferences': {
        'preferLessWalking': _preferLessWalking,
        'preferLessTransfers': _preferLessTransfers,
        'preferFastestRoute': _preferFastestRoute,
        'avoidCrowdedLines': _avoidCrowdedLines,
        'preferredRouteType': _preferredRouteType,
      },
      'mobilitySettings': {
        'mobilityLevel': _mobilityLevel,
        'needElevator': _needElevator,
        'needEscalator': _needEscalator,
        'avoidStairs': _avoidStairs,
        'maxWalkingDistance': _maxWalkingDistance,
      },
      'luggageSettings': {
        'hasLuggage': _hasLuggage,
        'luggageSize': _luggageSize,
        'luggageCount': _luggageCount,
        'needWideGate': _needWideGate,
      },
    };
  }
}
