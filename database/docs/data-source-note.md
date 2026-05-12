# 基础交通数据来源说明

## 1. 当前数据用途

当前数据库中的站点、线路、换乘规则用于课程项目演示和小组联调，不代表完整实时运营数据。

本次重点补齐：

```text
上海地铁10号线：上海虹桥火车站 -> 同济大学，方向为往基隆路方向
```

## 2. 已录入站点区间

```text
上海虹桥火车站
虹桥2号航站楼
虹桥1号航站楼
上海动物园
龙溪路
水城路
伊犁路
宋园路
虹桥路
交通大学
上海图书馆
陕西南路
一大会址·新天地
老西门
豫园
南京东路
天潼路
四川北路
海伦路
邮电新村
四平路
同济大学
```

## 3. 公开资料核对

站点顺序参考公开线路信息进行核对，课程项目后续如需上线或更严谨展示，应继续替换为官方运营数据或人工维护的正式数据源。

参考资料：

- MetroMan 同济大学站信息：https://www.metroman.cn/cities/shanghai/stations/tongji-university
- FindIt City 上海地铁10号线线路信息：https://findit.city/cn/china/shanghai/transport/subway/10
- 车主手册上海地铁10号线虹桥火车站至基隆路方向信息：https://www.icauto.com.cn/chuxing/dt_114.html

## 4. 数据维护建议

后续如果要继续扩展，建议按这个顺序维护：

```text
1. 先维护 stations
2. 再维护 metro_lines
3. 再维护 line_stations
4. 最后维护 transfer_rules 和 station_exits
```

因为换乘规则依赖站点和线路，不能反过来先写规则。
