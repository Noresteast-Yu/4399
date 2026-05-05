# 数据库设计说明

## 当前版本

Week 01 数据库基础数据雏形

## 数据范围

包含上海虹桥火车站至交通大学范围内的演示数据。

## 核心数据集合

- stations：站点基础数据
- lines：线路基础数据
- lineStations：线路站序数据
- transferRules：换乘推荐规则
- commonRoutes：常用路线演示数据
- travelAlerts：出行提醒演示数据
- trains：高铁车次演示数据

## 后续迁移

当前使用 CommonJS 静态数据文件模拟数据库，后续可以迁移到 MongoDB 或 MySQL。
