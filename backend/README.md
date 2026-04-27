# 出行引导系统 - 后端服务

## 项目简介

这是一个为出行引导系统提供后端服务的 Node.js 应用，主要功能包括：
- 路线规划（地铁、公交、步行）
- 地铁服务（站点信息、设施分布、客流拥挤度）
- 高铁引导（车次查询、精准下车引导）
- 换乘时间管理（实时倒计时、行程进度）
- 常用路线管理
- 出行提醒（实时预警、通知）

## 技术栈

- **Node.js** + **Express** - 后端框架
- **MongoDB** - 数据库（支持模拟数据模式）
- **JWT** - 认证
- **CORS** - 跨域支持

## 目录结构

```
backend/
├── app.js              # 主应用文件
├── package.json        # 项目配置文件
├── .env                # 环境变量配置
├── routes/             # 路由目录
│   ├── index.js        # 主路由文件
│   ├── routePlan.js    # 路线规划路由
│   ├── subwayService.js # 地铁服务路由
│   ├── highSpeedRail.js # 高铁引导路由
│   ├── transferTime.js  # 换乘时间路由
│   ├── commonRoutes.js  # 常用路线路由
│   └── travelAlerts.js  # 出行提醒路由
└── models/             # 数据库模型目录
    ├── Route.js        # 路线模型
    ├── SubwayStation.js # 地铁站点模型
    ├── Train.js        # 高铁车次模型
    └── TravelAlert.js  # 出行提醒模型
```

## 安装步骤

1. **克隆项目**
   ```bash
   git clone <repository-url>
   cd prototype FE/backend
   ```

2. **安装依赖**
   ```bash
   npm install
   ```

3. **配置环境变量**
   - 复制 `.env.example` 文件并重命名为 `.env`
   - 修改 `.env` 文件中的配置项

## 运行方法

### 开发模式
```bash
npm run dev
```

### 生产模式
```bash
npm start
```

### 使用 Node.js 完整路径（如果 PATH 未配置）
```bash
"C:\Program Files\nodejs\node.exe" app.js
```

## API 接口

### 路线规划
- `POST /api/route-plan/plan` - 生成路线规划
  - 请求参数：`start`（起点）、`end`（终点）、`mode`（出行方式）
  - 返回：多条路线方案

### 地铁服务
- `GET /api/subway-service/station/:stationId` - 获取地铁站点信息
- `GET /api/subway-service/lines` - 获取地铁线路信息

### 高铁引导
- `GET /api/high-speed-rail/train/:trainNumber` - 查询高铁车次信息
- `POST /api/high-speed-rail/guide` - 获取下车引导

### 换乘时间管理
- `POST /api/transfer-time/start` - 开始换乘计时
- `GET /api/transfer-time/update/:sessionId` - 获取实时更新

### 常用路线
- `GET /api/common-routes/user/:userId` - 获取用户常用路线
- `POST /api/common-routes/add` - 添加常用路线
- `DELETE /api/common-routes/:routeId` - 删除常用路线

### 出行提醒
- `GET /api/travel-alerts` - 获取所有出行提醒
- `GET /api/travel-alerts/:type` - 获取特定类型的出行提醒

### 健康检查
- `GET /health` - 服务健康状态

## 环境变量配置

在 `.env` 文件中配置以下变量：

```env
# 服务器配置
PORT=3000

# 数据库配置
MONGODB_URI=mongodb://localhost:27017/travel-guide

# JWT 配置
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=24h

# API 配置
API_BASE_URL=/api
```

## 服务模式

- **模拟数据模式**：当 MongoDB 连接失败时，服务会自动切换到模拟数据模式
- **数据库模式**：当 MongoDB 连接成功时，服务会使用真实数据库

## 测试

使用 `test-api.js` 脚本测试 API 接口：

```bash
node test-api.js
```

## 注意事项

1. **端口占用**：如果端口 3000 被占用，需要先终止占用进程或修改端口
2. **数据库**：服务可以在没有 MongoDB 的情况下运行（使用模拟数据）
3. **跨域**：已配置 CORS 支持，允许前端应用访问
4. **安全**：生产环境中请修改 JWT 密钥

## 技术支持

如有问题，请联系：
- 开发者：后端开发团队
- 邮箱：1925992764@qq.com
- 文档：本 README 文件

## 版本历史

- v1.0.0 - 初始版本，实现基础功能
- v1.1.0 - 添加高铁引导和换乘时间管理功能
- v1.2.0 - 优化路线规划算法，增加出行提醒功能

---

**© 2026 出行引导系统 - 后端服务**
