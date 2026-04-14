import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  // 请求定位权限
  static Future<bool> requestLocationPermission() async {
    var status = await Permission.location.request();
    return status.isGranted;
  }
  
  // 请求存储权限
  static Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.request();
    return status.isGranted;
  }
  
  // 请求通知权限
  static Future<bool> requestNotificationPermission() async {
    var status = await Permission.notification.request();
    return status.isGranted;
  }
  
  // 检查权限状态
  static Future<bool> checkPermission(Permission permission) async {
    var status = await permission.status;
    return status.isGranted;
  }
  
  // 打开应用设置
  static Future<void> openAppSettings() async {
    await Permission.location.openAppSettings();
  }
}
