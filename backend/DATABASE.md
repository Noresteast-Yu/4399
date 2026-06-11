# Smart Travel 数据库维护说明

## 文件职责

- `schema.sql`：当前完整数据库基线，仅用于创建全新的数据库。
- `seed.sql`：空数据库首次使用的演示数据，不会主动删除已有数据。
- `migrations/*.sql`：已有数据库的增量升级脚本。
- `db_check.sql`：表数量、孤立关系和核心演示数据检查。
- `docker-compose.yml`：本地 MySQL 8.0 开发环境。

`schema_clean.sql` 已移除。数据库结构只能以 `schema.sql` 为准，避免两份
schema 长期漂移。

## 数据所有权

- MySQL：线路、站点、出口、设施摘要、提醒、反馈和用户业务数据。
- `backend/go/data/station_topologies/*.json`：站内节点、边、方向与照片槽位。
- MinIO：站内实景照片对象。

同济大学站的详细导航拓扑不重复拆入 MySQL。MySQL 只保存可查询的设施摘要，
拓扑 JSON 保存图结构，MinIO 保存媒体，三者职责不同。

## 新建数据库

Docker 首次创建空数据卷时会按顺序执行：

1. `schema.sql`
2. `seed.sql`

已有 Docker 数据卷不会再次执行初始化脚本。不要为了应用迁移而删除数据卷。

## 升级已有数据库

先备份，再从 `backend/go` 目录执行迁移器：

```powershell
$env:MIGRATIONS_DIR = "..\migrations"
go run .\cmd\db-migrate
```

迁移脚本按文件名排序执行，并在 `schema_migrations` 中留下版本记录。当前迁移
均为幂等操作，可以再次执行；后续迁移也必须遵守这一原则。

## 健康检查

```powershell
& "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" `
  -h 127.0.0.1 -P 3306 -u root -p smart_travel `
  < .\db_check.sql
```

检查结果要求：

- `orphan_*` 项全部为 `0`。
- `core_*` 项全部大于 `0`。
- `schema_migrations` 能看到当前升级记录。

## 维护规则

1. 不在业务接口中新增或修改表结构，所有结构变化都写成新迁移。
2. 不修改已经发布的迁移语义；新增变化使用下一个编号。
3. 种子数据不得删除已有业务数据。
4. 未调查的设施默认值为 `0`，不能把“未知”写成“存在”。
5. 静态资源入库前必须确认文件或对象确实存在。
6. 密码只放在本地 `.env`，不得提交到 Git。
7. 每次结构升级前执行 `mysqldump`，升级后执行 `db_check.sql`。
