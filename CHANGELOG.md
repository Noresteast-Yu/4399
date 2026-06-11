# Changelog

## v1.0.4 — 服务板块自动定位 & 站内导航状态持久化 (2026-06-10)

### 新特性

#### 1. 服务板块自动定位站点
- **移除手动站点选择器**：`subway_service_page.dart` 不再需要用户手动选择站点，改为自动读取当前所在站点
- **服务页自动定位**：从路线规划/站内导航页同步站点上下文到服务页，服务页打开时自动显示当前站点
- **动态导航起点**：4 个服务图标（出入口、电梯、洗手间、服务中心）的路径规划起点从硬编码 `'20'` 改为用户当前所在站内节点
- **自动定位标识**：站点头部卡片显示"已自动定位"标记和定位图标

#### 2. 站内导航状态持久化
- **Tab 切换不丢导航进度**：从 AI 站内规划页切换到其他 Tab 再切回，停留在同一页面的同一步进
- **步进索引恢复**：切回后自动恢复到离开时的导航步骤

#### 3. 设施导航后端测试
- 新增 `station_topology_service_test.go` 中 7 项设施导航路径测试
  - `TestNavigateToFacilityToilet`：从站台中心到洗手间的路径
  - `TestNavigateToServiceCenter`：从站台中心到服务中心的路径
  - `TestNavigateToAccessibleElevator`：同节点电梯直达
  - `TestNavigateToExit5`：从站台中心到 5 号口的路径
  - `TestNavigateFromEntranceNode`：从进站口到设施的路径
  - `TestInvalidFacilityReturnsError`：无效设施的错误处理
  - `TestInvalidStationReturnsError`：无效站点的错误处理

#### 4. 前端单元测试
- 新增 `navigation_memory_test.dart` 中 11 项 NavigationMemory 单元测试
  - 站点上下文（stationId/stationName/nodeId）的设置与读取
  - `updateStationContext()` 的局部更新与保留语义
  - `clearStationContext()` 的完整清理
  - `lastStepIndex` 的默认值与读写
  - `routePlanLocation` 的读写
  - 完整生命周期测试（更新 → 读取 → 清理）

### 修复

- **修复设施 station ID 不匹配**：设施数据使用 `tong_ji_university`，拓扑数据使用 `tongji_university`，两者分离处理
- **修复 dispose() 竞态**：`clearStationContext()` 从 `dispose()` 移至 `_returnToRoutePlan()`，避免 Tab 切换时误清站点上下文
- **修复重复 `dispose()`**：AI 规划页中合并重复的 dispose 方法

### 修改文件

| 文件 | 变更 |
|------|------|
| `app/lib/services/navigation_memory.dart` | 新增 `currentStationId`/`currentStationName`/`currentNodeId`/`lastStepIndex` 字段及方法 |
| `app/lib/pages/ai_planning_page.dart` | Tab 切换状态保存/恢复、站点上下文同步、步进索引持久化 |
| `app/lib/pages/route_plan_page.dart` | 进入站内指引前同步站点上下文到 NavigationMemory |
| `app/lib/pages/subway_service_page.dart` | 移除站点选择器，自动定位，动态 fromNodeId，修复设施/拓扑双 ID |
| `app/test/services/navigation_memory_test.dart` | 新增 11 项单元测试 |
| `backend/go/services/station_topology_service_test.go` | 新增 7 项设施导航路径测试 |

---

## v1.0.3 — 服务板块 UI 优化 & 中途服务导航 (2026-06-10)

### 新特性

#### 1. 服务板块 UI 简化
- **移除冗余功能**：搜索框、跨区域规划按钮、折叠面板、评论区
- **核心服务网格**：4 个核心功能图标 2×2 网格布局（出入口、电梯、洗手间、服务中心）
- **设施状态显示**：根据站点设施数据动态显示启用/禁用状态

#### 2. 中途服务导航
- **站内导航快捷服务栏**：在 AI 规划页步骤控制上方显示 4 个服务快捷图标
- **不从零开始**：点击服务图标以当前步进节点为起点计算路径，不干扰原有导航进度
- **独立路径弹窗**：服务路径在底部弹窗中展示，关闭后原有导航继续

### 修复
- 移除重复的 `IsConnected()` 函数声明
- 修复 `Icons.map_off_rounded` 不存在的编译错误
