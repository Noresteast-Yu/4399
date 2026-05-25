# Smart Travel App — 地铁跑酷换乘助手

上海地铁智能换乘助手 Flutter 应用，支持完整地铁线路图展示和 AI 智能路线规划。

## 功能特性

| 功能 | 说明 |
|------|------|
| 上海地铁线路图 | 18 条线路，支持缩放/平移/全屏/站点搜索 |
| AI 智能规划 | 对接 OpenAI 兼容 API，自动规划最优路线 |
| 离线规划 | 无网络时本地计算路径 |
| 路线规划 | 多路线方案对比、换乘指引 |
| 地铁设施 | 无障碍设施、自动扶梯位置查询 |
| 换乘时间 | 换乘步行时间估算 |

## 环境配置

### 1. Flutter SDK

本项目基于 **Flutter 3.x**，Dart SDK 版本要求 `>=3.0.0 <4.0.0`。

**安装步骤：**

1. 下载 Flutter SDK：[Flutter 官网](https://docs.flutter.dev/get-started/install)
2. 解压到目标目录（如 `C:\src\flutter`，**不要**放在 `C:\Program Files\` 等需要管理员权限的目录）
3. 配置环境变量：将 `C:\src\flutter\bin` 添加到系统 `PATH` 中
4. 验证安装：

```powershell
flutter doctor
```

> 执行 `flutter doctor` 会检查环境是否完整，根据输出提示逐一修复。首次运行可能需要较长时间。

5. Android 开发环境补充配置（如 `flutter doctor` 提示缺失）：

```powershell
flutter doctor --android-licenses
```

一路输入 `y` 同意所有协议。

### 2. Java JDK

Android 开发需要 **JDK 17**。

1. 下载 [JDK 17](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html) 或使用 [OpenJDK](https://jdk.java.net/17/)
2. 安装后配置 `JAVA_HOME` 环境变量，指向 JDK 安装目录
3. 将 `%JAVA_HOME%\bin` 添加到 `PATH`
4. 验证：

```powershell
java -version
```

### 3. Android Studio

**安装：**

1. 下载 [Android Studio](https://developer.android.com/studio)（推荐最新稳定版）
2. 安装时确保勾选 **Android SDK**、**Android SDK Platform-Tools**、**Android Emulator**
3. 首次启动时，按照 Setup Wizard 完成 SDK 安装。推荐安装 API 34 或更高版本

**安装 Flutter / Dart 插件：**

1. 打开 Android Studio → **File → Settings → Plugins**（macOS: **Android Studio → Preferences → Plugins**）
2. 搜索 `Flutter` 并安装，Dart 插件会自动附带安装
3. 重启 Android Studio

### 4. 环境变量汇总

| 变量名 | 值（示例） |
|--------|-----------|
| `FLUTTER_HOME` | `C:\src\flutter` |
| `JAVA_HOME` | `C:\Program Files\Java\jdk-17` |
| `ANDROID_HOME` | `C:\Users\你的用户名\AppData\Local\Android\Sdk` |
| `PATH` 追加 | `%FLUTTER_HOME%\bin`、`%JAVA_HOME%\bin` |

## Android Studio 调试教程

### 步骤 1：打开项目

1. 启动 **Android Studio**
2. 点击 **Open**，选择项目目录 `smart-travel-app/app`
3. 等待 IDE 完成索引和依赖解析

### 步骤 2：同步依赖

在 Android Studio 底部的 **Terminal** 中执行：

```bash
flutter pub get
```

或者在 IDE 中打开 `pubspec.yaml`，点击右上角的 **Pub get** 按钮。

### 步骤 3：创建 Android 模拟器（如果没有）

1. 点击右上角工具栏的 **Device Manager** 图标（手机图标）
2. 点击 **Create device**，选择设备型号（推荐 Pixel 系列）
3. 选择系统镜像（推荐 API 34 或 35，带 Google APIs 的版本）
4. 完成创建后，点击 **▶️** 启动模拟器

> 如果没有可用的系统镜像，需要先在 SDK Manager 中下载。

### 步骤 4：选择设备

在顶部工具栏的设备下拉菜单中选择：
- **已启动的模拟器** — 如 `Pixel 7 API 34`
- **真机** — 用 USB 连接手机，开启「开发者选项」和「USB 调试」

### 步骤 5：运行 / 调试

| 操作 | 方式 |
|------|------|
| **运行** | 点击绿色 ▶️ 按钮，或按 `Shift + F10` |
| **调试** | 点击绿色 🐛 按钮，或按 `Shift + F9` |
| **热重载** | 修改代码后按 `Ctrl + \` 或点击 ⚡ 图标 |
| **热重启** | 按 `Ctrl + F5` 或点击 🔄 图标 |
| **停止** | 点击红色 ⏹ 按钮，或按 `Ctrl + F2` |

### 步骤 6：断点调试

1. 在代码行号左侧单击添加 **断点**（红色圆点）
2. 以 **Debug** 模式运行应用（Shift + F9）
3. 程序执行到断点时会自动暂停
4. 在底部 **Debug** 面板中：

| 操作 | 快捷键 |
|------|--------|
| 单步跳过 (Step Over) | `F8` |
| 单步进入 (Step Into) | `F7` |
| 单步跳出 (Step Out) | `Shift + F8` |
| 继续执行 (Resume) | `F9` |
| 查看变量值 | 在 Variables 面板中查看 |

### 步骤 7：查看日志

点击底部工具栏的 **Logcat** 标签页，可以看到 Android 系统和应用的运行日志。在搜索框中输入 `flutter` 可以过滤 Flutter 相关日志。

### 步骤 8：Flutter DevTools

在应用运行期间，点击底部 **Flutter Inspector** 或 **Flutter Performance** 标签可以打开 DevTools，查看 Widget 树、性能分析等。

也可以在终端中运行：

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

## 命令行运行（其他平台）

```bash
# 安装依赖
flutter pub get

# Android
flutter run

# iOS（需 macOS + Xcode）
flutter run -d ios

# Web
flutter run -d chrome

# Windows
flutter run -d windows
```

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter 3.x + Dart |
| 状态管理 | Provider / Bloc |
| 路由 | GoRouter |
| 网络 | Dio |
| 本地存储 | SharedPreferences |
| AI | OpenAI 兼容 API（通义千问/DeepSeek 等） |
| 动画 | Lottie |
| 国际化 | intl |

## 项目结构

```
app/
├── lib/
│   ├── components/     # UI 组件
│   │   ├── common/     # 通用组件
│   │   └── home/       # 首页组件
│   ├── data/           # 数据模型
│   ├── pages/          # 页面
│   ├── providers/      # 状态管理
│   ├── routes/         # 路由配置
│   ├── services/       # 服务层
│   ├── theme/          # 主题
│   ├── utils/          # 工具类
│   ├── app.dart        # 应用入口
│   └── main.dart       # 启动入口
├── android/            # Android 原生工程
├── ios/                # iOS 原生工程
├── assets/             # 静态资源
│   ├── images/
│   ├── icons/
│   └── fonts/
├── pubspec.yaml        # 依赖配置
└── analysis_options.yaml
```