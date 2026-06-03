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
    if (kDebugMode) {
      debugPrint('Error: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }
}
