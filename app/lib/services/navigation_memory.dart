class NavigationMemory {
  /// 规划页当前路由（含查询参数），用于底部导航栏恢复规划页状态
  static String? routePlanLocation;

  /// 用户当前所在站点 ID（如 'tongji_university'），服务页据此自动定位
  static String? currentStationId;

  /// 用户当前所在站点名称（如 '同济大学'）
  static String? currentStationName;

  /// 用户当前所在站内节点 ID（如 '1'=进站口, '20'=站台中心）
  static String? currentNodeId;

  /// 更新站内位置上下文（从站内导航页或路线规划页调用）
  static void updateStationContext({
    String? stationId,
    String? stationName,
    String? nodeId,
  }) {
    if (stationId != null) currentStationId = stationId;
    if (stationName != null) currentStationName = stationName;
    if (nodeId != null) currentNodeId = nodeId;
  }

  /// 站内导航当前步进索引，切 Tab 回来后恢复进度
  static int lastStepIndex = 0;

  /// 清除站内位置上下文
  static void clearStationContext() {
    currentStationId = null;
    currentStationName = null;
    currentNodeId = null;
    lastStepIndex = 0;
  }
}
