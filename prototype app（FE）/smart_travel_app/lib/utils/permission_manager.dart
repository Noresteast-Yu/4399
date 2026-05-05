import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  static Future<bool> requestLocationPermission() async {
    var status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<bool> requestNotificationPermission() async {
    var status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<bool> checkPermission(Permission permission) async {
    var status = await permission.status;
    return status.isGranted;
  }

  static Future<void> launchAppSettings() async {
    await openAppSettings();
  }
}
