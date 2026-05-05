# Week 01 数据库基础数据雏形

## 本周定位

完成数据库模块的基础结构和第一批站点、线路、换乘规则数据。

## 本周新增

- 建立 database/data 数据目录
- 整理上海虹桥火车站、10号线部分站点和基础换乘规则
- 加入数据校验脚本

## 验证方式

在本目录执行：

```bash
node database/scripts/validateDatabaseData.js
```

预期输出包含：

```json
{
  "ok": true,
  "errors": []
}
```

## 说明

本版本只包含数据库/数据模块内容，不包含 Android 页面代码，也不包含后端路由开发。
