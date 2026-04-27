# 地铁跑酷换乘助手 - 数据整理与静态资源开发模块

## 1. 模块名称

数据整理与静态资源开发模块

## 2. 当前版本范围（第一次提交）

本次提交采用 **“默认参数 + 可扩展数据结构”** 设计。

当前内置默认演示数据：

- 默认出发站：上海虹桥火车站
- 默认线路：上海地铁10号线
- 默认方向：往基隆路方向

说明：

- 当前页面默认展示“上海虹桥火车站 + 上海地铁10号线”场景。
- 但系统并非写死，后续可继续添加其他城市/站点/线路/站序/规则，页面主逻辑无需大改。

## 3. 模块作用

本模块负责：

- 整理站点基础数据
- 整理地铁线路数据
- 整理线路站点顺序
- 整理换乘推荐规则
- 管理静态图标和示意图资源
- 提供统一的数据查询接口
- 为后续路径规划和页面展示模块提供数据基础

## 4. 文件说明

项目核心结构如下：

```text
miniprogram/
├─ app.js
├─ app.json
├─ app.wxss
├─ pages/
│  ├─ index/
│  │  ├─ index.js
│  │  ├─ index.wxml
│  │  ├─ index.wxss
│  │  └─ index.json
│  └─ dataDemo/
│     ├─ dataDemo.js
│     ├─ dataDemo.wxml
│     ├─ dataDemo.wxss
│     └─ dataDemo.json
├─ data/
│  ├─ defaultConfig.js
│  ├─ stations.js
│  ├─ lines.js
│  ├─ lineStations.js
│  ├─ transferRules.js
│  └─ staticResources.js
├─ utils/
│  ├─ routeManager.js
│  └─ dataValidator.js
└─ assets/
   ├─ icons/
   │  ├─ train.svg
   │  ├─ metro.svg
   │  ├─ transfer.svg
   │  └─ exit.svg
   └─ maps/
      └─ line10_demo_map.svg
```

各文件职责：

- `data/defaultConfig.js`：默认演示参数（默认出发站、线路、方向）
- `data/stations.js`：站点基础信息
- `data/lines.js`：线路基础信息
- `data/lineStations.js`：线路站点顺序（通过 `line_id` 关联）
- `data/transferRules.js`：换乘推荐规则（通过 `origin_station_id + line_id + target_station_id` 关联）
- `data/staticResources.js`：图标与示意图路径管理
- `utils/routeManager.js`：统一查询接口层（供页面与其他模块调用）
- `utils/dataValidator.js`：数据完整性校验工具
- `pages/index`：入口页
- `pages/dataDemo`：数据模块演示页
- `assets/icons`：静态图标资源
- `assets/maps`：线路示意图资源

## 5. 主要接口说明

`utils/routeManager.js`：

- `getDefaultConfig()`
- `getDefaultOriginStation()`
- `getDefaultLine()`
- `listStations()`
- `listLines()`
- `getStationById(stationId)`
- `getLineById(lineId)`
- `listStationsByLine(lineId)`
- `listTransferRulesByOriginAndLine(originStationId, lineId)`
- `searchTransferRules(keyword, originStationId, lineId)`
- `getRoutePlan(ruleId)`
- `getStaticResource(resourceType, resourceName)`

`utils/dataValidator.js`：

- `validateData()`

## 6. 与其他模块的对接方式

推荐其他页面统一通过 `routeManager.js` 获取数据，不直接读取 `data` 文件。

示例：

```javascript
const routeManager = require("../../utils/routeManager")

const defaultConfig = routeManager.getDefaultConfig()
const defaultLine = routeManager.getDefaultLine()
const rules = routeManager.listTransferRulesByOriginAndLine(
  defaultConfig.default_origin_station_id,
  defaultConfig.default_line_id
)
const plan = routeManager.getRoutePlan(rules[0].rule_id)
```

说明：

- 页面层只负责展示与交互。
- 数据组织、搜索、拼装逻辑由 `routeManager` 统一维护。
- 后续扩展数据时，优先改 `data` 目录即可。

## 7. 运行方式

1. 使用微信开发者工具导入项目根目录。
2. 若无正式 AppID，可使用测试号或无 AppID 模式。
3. 编译运行后，首页进入“数据模块演示”页即可查看模块效果。

## 8. 当前进度

已完成：

- 默认配置文件
- 站点基础数据
- 线路基础数据
- 10号线部分站点顺序
- 默认场景下的重点换乘规则
- 静态资源占位图（图标 + 10号线示意图）
- 数据查询工具函数（`routeManager`）
- 数据校验工具函数（`dataValidator`）
- 小程序演示页面（`index` + `dataDemo`）

## 9. 后续扩展方向

- 增加更多出发站
- 增加更多地铁线路
- 增加真实站内换乘路线
- 增加更准确的推荐车厢
- 增加高铁到地铁的站内步行指引
- 接入用户输入的起点和终点
- 与路径规划模块、地图展示模块、搜索模块对接

## 10. 数据说明

当前数据为课程项目演示数据，不代表完整真实运营数据。  
后续可以使用真实站点数据库或人工维护数据进行替换。
