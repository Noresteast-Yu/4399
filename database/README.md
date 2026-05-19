# 基础交通数据库

## 概述

本项目使用 MongoDB 作为基础交通数据存储，包含上海地铁线路、站点、换乘规则等数据。

## 数据模型

### MongoDB Collections

| Collection | 说明 | 对应 Model |
|------------|------|------------|
| `stations` | 站点基础信息 | [Station.js](../../backend/models/Station.js) |
| `metroLines` | 地铁线路信息 | [MetroLine.js](../../backend/models/MetroLine.js) |
| `lineStations` | 线路站点顺序 | [LineStation.js](../../backend/models/LineStation.js) |
| `transferRules` | 换乘推荐规则 | [TransferRule.js](../../backend/models/TransferRule.js) |
| `stationExits` | 站点出入口和导向 | [StationExit.js](../../backend/models/StationExit.js) |

## 文件结构

```
database/
├── database/
│   ├── schema.sql              MySQL 建表脚本（已废弃，保留参考）
│   ├── seed.sql                MySQL 种子数据（已废弃，保留参考）
│   ├── query_examples.sql      MySQL 查询示例（已废弃，保留参考）
│   └── scripts/
│       └── seedMongoDB.js      MongoDB 数据初始化脚本
└── README.md                   本文档
```

## 运行方式

### 前置条件

1. 确保 MongoDB 已安装并运行
2. 配置 `.env` 文件中的 `MONGODB_URI`

### 初始化数据

```bash
# 进入 backend 目录
cd backend

# 安装依赖（如果未安装）
npm install

# 运行种子脚本
node ../database/database/scripts/seedMongoDB.js
```

### 或者直接在 backend 目录运行

```bash
cd backend
node ../database/database/scripts/seedMongoDB.js
```

## 数据内容

当前包含以下演示数据：

- 12 条上海地铁线路（1、2、3、4、8、10、11、12、13、14、17、18号线）
- 22 个站点（虹桥火车站到同济大学 10 号线沿途站点）
- 22 条线路站点顺序记录
- 12 条换乘规则
- 5 个站点出入口信息

## 查询示例

### 查询所有线路

```javascript
const MetroLine = require('./models/MetroLine');
const lines = await MetroLine.find({ city: '上海' });
```

### 查询某线路的所有站点

```javascript
const LineStation = require('./models/LineStation');
const stations = await LineStation.find({
  lineId: 'shanghai_metro_line_10',
  direction: '往基隆路方向'
}).sort({ stationOrder: 1 });
```

### 查询换乘规则

```javascript
const TransferRule = require('./models/TransferRule');
const rules = await TransferRule.find({
  originStationId: 'shanghai_hongqiao_railway_station'
});
```

## 说明

当前数据为课程项目演示数据，后续可以继续替换为更完整的真实运营数据。
