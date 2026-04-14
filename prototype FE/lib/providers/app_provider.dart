import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  // 主题模式
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  
  // 字体大小
  double _fontSize = 16;
  double get fontSize => _fontSize;
  
  // 步行速度
  double _walkingSpeed = 4.0; // km/h
  double get walkingSpeed => _walkingSpeed;
  
  // 行李数量
  int _luggageCount = 0;
  int get luggageCount => _luggageCount;
  
  // 切换主题模式
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
  
  // 设置字体大小
  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }
  
  // 设置步行速度
  void setWalkingSpeed(double speed) {
    _walkingSpeed = speed;
    notifyListeners();
  }
  
  // 设置行李数量
  void setLuggageCount(int count) {
    _luggageCount = count;
    notifyListeners();
  }
}
