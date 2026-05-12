# Week 03 基础交通数据库补全

## 本周主题

基础交通数据库先做出来，用户画像先不作为重点。

本周完成：

- 站点基础表 `stations`
- 地铁线路表 `metro_lines`
- 线路站点顺序表 `line_stations`
- 换乘推荐规则表 `transfer_rules`
- 出入口和站内导向表 `station_exits`
- 上海虹桥火车站到同济大学的 10 号线沿途站点数据

## 本周文件

```text
database/schema.sql          建基础交通表
database/seed.sql            插入站点、线路、换乘规则数据
database/query_examples.sql  查询基础交通数据
docs/data-source-note.md     数据来源和演示数据说明
```

## 运行顺序

在 MySQL Workbench 中依次运行：

```text
database/schema.sql
database/seed.sql
database/query_examples.sql
```

## 本周可展示内容

可以展示：

```text
10号线从上海虹桥火车站到同济大学的站点顺序
重点换乘站
虹桥火车站到同济大学的路线规则
出入口和站内导向演示数据
```

## 说明

当前数据为课程项目演示数据，后续可以继续替换为更完整的真实运营数据。
