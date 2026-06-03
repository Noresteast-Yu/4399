# Smart Travel Backend (Go)

智能出行助手 - Go 后端服务

## 环境要求

| 组件 | 版本要求 |
|------|---------|
| Go | 1.21+ |
| MySQL | 5.7+ 或 8.0+ |
| Git | 任意版本 |

## 项目结构

```
backend/
├── schema.sql           # 数据库表结构
├── seed.sql             # 数据库种子数据（上海地铁演示数据）
└── go/
    ├── main.go          # 程序入口
    ├── go.mod           # Go 模块定义
    ├── go.sum           # 依赖校验文件
    ├── .env.example     # 环境变量示例
    ├── config/          # 配置加载
    ├── database/        # MySQL 连接
    ├── models/          # 数据模型
    ├── handlers/        # HTTP 处理器
    ├── router/          # 路由配置
    └── services/        # 业务服务层
```

## 快速开始

### 1. 安装 Go

下载并安装 Go 1.21 或更高版本：[https://go.dev/dl/](https://go.dev/dl/)

```powershell
go version
```

### 2. 安装并配置 MySQL

**方式一：本地安装**

下载 [MySQL Community Server](https://dev.mysql.com/downloads/mysql/)，安装后启动服务。

**方式二：Docker（推荐）**

```powershell
docker run -d --name mysql-smarttravel `
  -e MYSQL_ROOT_PASSWORD=your_password `
  -e MYSQL_DATABASE=smart_travel `
  -p 3306:3306 `
  mysql:8.0
```

### 3. 初始化数据库

```powershell
cd backend

mysql -u root -p < schema.sql

mysql -u root -p smart_travel < seed.sql
```

> 种子数据包含上海地铁 1/2/3/4/8/10/11/12/13/14/17/18 号线的演示数据（10号线完整数据 + 换乘关系）。

### 4. 配置环境变量

```powershell
cd backend/go
copy .env.example .env
```

编辑 `.env` 文件：

```env
PORT=3000
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=你的MySQL密码
DB_NAME=smart_travel
SHMAAS_HOST=http://127.0.0.1:8787
SHMAAS_MERCHANT_ID=mock-merchant
SHMAAS_SALT=mock-salt
SHMAAS_CITY_CODE=mock-shanghai
```

> 如果数据库连接失败，服务仍会以模拟模式启动，但数据将是空的。

### 5. 安装依赖并启动

```powershell
cd backend/go
go mod tidy
go run main.go
```

服务将在 `http://localhost:3000` 启动，默认监听所有网卡（`0.0.0.0`）。

### 6. 连接 Flutter 应用

服务启动后，在 App 的 **设置 → 服务配置** 中配置后端地址：

| 场景 | 服务器地址 | 端口 |
|------|-----------|------|
| Android 模拟器 | `10.0.2.2` | `3000` |
| iOS 模拟器 | `localhost` | `3000` |
| Web 浏览器 | `localhost` | `3000` |
| 真机调试（同一WiFi） | 电脑局域网 IP（如 `192.168.1.x`） | `3000` |

> 校园网等环境可能存在客户端隔离，此时建议使用手机热点让手机和电脑组成私有局域网。

**验证连接：**

```bash
curl http://localhost:3000/health
# 预期返回: {"mode":"database","status":"ok"}
```

### 7. 编译为可执行文件（可选）

```powershell
go build -o smart-travel-server.exe
```

直接运行 `smart-travel-server.exe` 即可启动服务（仍需 `.env` 文件在同目录下）。

## API 接口

所有业务接口均以 `/api` 为前缀，已配置 CORS 支持。

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/health` | 健康检查 |
| POST | `/api/route-plan/plan` | 路线规划 |
| GET | `/api/subway-service/station/:id` | 获取站点信息 |
| GET | `/api/subway-service/station/:id/facilities` | 获取站点设施 |
| GET | `/api/subway-service/facilities` | 获取所有站点设施 |
| GET | `/api/subway-service/lines` | 获取所有线路 |
| GET | `/api/metro/arrival` | 获取地铁到站信息 |
| GET | `/api/indoor-guide` | 获取室内导航 |
| GET | `/api/high-speed-rail/train/:number` | 获取高铁车次信息 |
| POST | `/api/high-speed-rail/guide` | 获取高铁乘车指引 |
| POST | `/api/transfer-time/start` | 开始换乘计时 |
| GET | `/api/transfer-time/update/:sessionId` | 获取换乘更新 |
| GET | `/api/common-routes/user/:userId` | 获取常用路线 |
| POST | `/api/common-routes/add` | 添加常用路线 |
| DELETE | `/api/common-routes/:id` | 删除常用路线 |
| GET | `/api/travel-alerts` | 获取出行提醒 |
| POST | `/api/feedback/submit` | 提交反馈 |

### 路线规划示例

```bash
curl -X POST http://localhost:3000/api/route-plan/plan \
  -H "Content-Type: application/json" \
  -d '{"start": "虹桥火车站", "end": "同济大学"}'
```

### 常用路线示例

```bash
# 获取用户常用路线
curl http://localhost:3000/api/common-routes/user/default

# 添加常用路线
curl -X POST http://localhost:3000/api/common-routes/add \
  -H "Content-Type: application/json" \
  -d '{"userId": "default", "start": "虹桥火车站", "end": "同济大学"}'
```

## 环境变量说明

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `PORT` | `3000` | 服务监听端口 |
| `DB_HOST` | `localhost` | MySQL 主机地址 |
| `DB_PORT` | `3306` | MySQL 端口 |
| `DB_USER` | `root` | MySQL 用户名 |
| `DB_PASSWORD` | 空 | MySQL 密码 |
| `DB_NAME` | `smart_travel` | 数据库名称 |
| `SHMAAS_HOST` | `http://127.0.0.1:8787` | 上海地铁 API 服务地址 |
| `SHMAAS_MERCHANT_ID` | `mock-merchant` | 商户 ID（签名用） |
| `SHMAAS_SALT` | `mock-salt` | 签名密钥 |
| `SHMAAS_CITY_CODE` | `mock-shanghai` | 城市代码 |

## 常见问题

**Q: 启动报错 "数据库连接失败"？**

A: 检查 MySQL 是否在运行，以及 `.env` 中的数据库密码是否正确。服务会以降级模式运行（数据库功能不可用）。

**Q: 手机连接不上后端？**

A: 确保手机和电脑在同一 WiFi 下，使用电脑的局域网 IP 而非 `localhost`。如果校园网有客户端隔离，可尝试使用手机热点。

**Q: Go 依赖下载慢？**

A: 设置 Go 代理：

```powershell
go env -w GOPROXY=https://goproxy.cn,direct
```

**Q: 跨域问题？**

A: 后端已内置 CORS 中间件，支持所有来源、GET/POST/PUT/DELETE/OPTIONS 方法。

## 技术栈

- **框架**：Gin（高性能 HTTP 框架）
- **数据库**：MySQL（go-sql-driver）
- **配置**：godotenv
