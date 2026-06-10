# 地铁跑酷换乘助手

上海地铁智能换乘助手 — Flutter 移动端应用，支持完整地铁线路图展示和 AI 智能路线规划。

## 项目结构

```
.
├── app/                    # Flutter 应用（主项目）
│   ├── lib/
│   │   ├── components/     # UI 组件（底部导航、地铁图、按钮等）
│   │   ├── data/           # 上海地铁数据模型（18条线路）
│   │   ├── pages/          # 页面（首页、AI规划、路线、服务、设置）
│   │   ├── providers/      # 状态管理
│   │   ├── routes/         # 路由配置
│   │   ├── services/       # 服务层（AI规划、API）
│   │   ├── theme/          # 主题系统
│   │   ├── utils/          # 工具类
│   │   ├── app.dart        # 应用入口
│   │   └── main.dart       # 启动入口
│   ├── android/            # Android 平台
│   ├── ios/                # iOS 平台
│   └── pubspec.yaml        # 依赖配置
├── backend/                # 后端参考代码
│   ├── go/                 # Go 后端源码（Gin + MySQL）
│   ├── object-storage/     # MinIO 对象存储初始化素材
│   ├── schema.sql          # 数据库表结构
│   └── seed.sql            # 数据库种子数据
├── tools/object-storage/   # 本地 MinIO 启动与同步脚本
└── .gitignore
```

## 功能

| 功能 | 说明 |
|------|------|
| 上海地铁线路图 | 18 条线路，支持缩放/平移/全屏/站点搜索 |
| AI 智能规划 | 对接 OpenAI 兼容 API，自动规划最优路线 |
| 离线规划 | 无网络时本地计算路径 |
| 路线规划 | 多路线方案对比、换乘指引 |
| 地铁设施 | 无障碍设施、自动扶梯位置查询 |
| 换乘时间 | 换乘步行时间估算 |

## 技术栈

| 类别 | 技术 |
|------|------|
| 前端框架 | Flutter 3.x + Dart |
| 状态管理 | Provider, ChangeNotifier |
| 路由 | GoRouter |
| 网络 | Dio |
| 本地存储 | SharedPreferences |
| AI | OpenAI 兼容 API（通义千问/DeepSeek/Moonshot 等） |
| 后端（参考） | Go + Gin + MySQL |
| 实景图片 | MinIO 对象存储 |

## 数据职责

- Flutter：界面、交互以及网络图片展示。
- Go：站内最短路径、方向指引和图片 URL 组装。
- JSON：同济大学站的节点、边、设施、耗时和对象键。
- MinIO：站内实景照片对象。
- MySQL：用户、评分、评论等动态业务数据。

本地启动对象存储：

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\object-storage\start-minio.ps1
```

## 快速开始

详情见 [app/README.md](app/README.md)。

```bash
cd app
flutter pub get
flutter run
```
