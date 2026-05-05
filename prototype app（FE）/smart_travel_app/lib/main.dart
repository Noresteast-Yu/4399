import 'package:flutter/material.dart';
import 'package:smart_travel_app/app.dart';
import 'package:smart_travel_app/utils/error_handler.dart';

void main() {
  ErrorHandler.setupErrorHandler(() {
    runApp(const SmartTravelApp());
  });
}
