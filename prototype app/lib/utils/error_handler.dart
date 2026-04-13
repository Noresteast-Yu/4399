import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ErrorHandler {
  static void setupErrorHandler() {
    // 捕获Flutter框架异常
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleError(details.exception, details.stack);
    };
    
    // 捕获Zone异常
    runZonedGuarded(
      () {
        // 应用运行的代码
      },
      (error, stackTrace) {
        _handleError(error, stackTrace);
      },
    );
  }
  
  static void _handleError(Object error, StackTrace stackTrace) {
    // 这里可以添加日志记录、上报到服务器等逻辑
    print('Error: $error');
    print('Stack trace: $stackTrace');
  }
}
