# Smart Travel Backend (Go)

智能出行助手 - Go 后端服务

## 项目结构

```
backend/go/
├── main.go              # 程序入口
├── go.mod               # Go 模块定义
├── go.sum               # 依赖校验文件
├── .env.example         # 环境变量示例
├── config/
│   └── config.go        # 配置加载
├── database/
│   └── database.go      # MySQL 连接
├── models/
│   └── models.go        # 数据模型
── handlers/
│   └── handlers.go      # HTTP 处理器
├── router/
│   └── router.go        # 路由配置
└── services/
    └── route_service.go # 路线规划服务
```

## 运行方式

### 1. 安装 Go

确保已安装 Go 1.21 或更高版本。

```powershell
go version
```

### 2. 初始化数据库

```powershell
# 创建数据库和表结构
mysql -u root -p < database/schema.sql

# 插入演示数据
mysql -u root -p smart_travel < database/seed.sql
```

### 3. 配置环境变量

在 `backend/go/` 目录下复制 `.env.example` 为 `.env`：

```powershell
cp .env.example .env
```

编辑 `.env` 文件，填写你的 MySQL 密码：

```env
PORT=3000
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=你的MySQL密码
DB_NAME=smart_travel
```

### 4. 安装依赖并启动

```powershell
cd backend/go
go mod tidy
go run main.go
```

服务将在 `http://localhost:3000` 启动。

## API 接口

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /health | 健康检查 |
| POST | /api/route-plan/plan | 路线规划 |
| GET | /api/subway-service/station/:id | 获取站点信息 |
| GET | /api/subway-service/lines | 获取所有线路 |

### 路线规划示例

```bash
curl -X POST http://localhost:3000/api/route-plan/plan \
  -H "Content-Type: application/json" \
  -d '{"start": "虹桥火车站", "end": "同济大学"}'
```

## 技术栈

- **框架**：Gin (高性能 HTTP 框架)
- **数据库**：MySQL (go-sql-driver)
- **配置**：godotenv

## 开发说明

- 代码已模块化：config、database、models、handlers、router、services
- 所有 SQL 查询使用参数化防止注入
- 响应格式统一使用 JSON
