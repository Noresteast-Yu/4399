import 'dart:async';
import 'package:flutter/foundation.dart';

class ErrorHandler {
  static void setupErrorHandler(VoidCallback appRunner) {
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleError(details.exception, details.stack);
    };

    runZonedGuarded(
      appRunner,
      (error, stackTrace) {
        _handleError(error, stackTrace);
      },
    );
  }

  static void _handleError(Object error, StackTrace? stackTrace) {
    print('Error: $error');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }
}
