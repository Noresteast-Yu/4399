# 上海地铁 / 随申行 API 最小测试工具

这是一个无第三方依赖的 Node.js CLI，用来测试随申行开放平台公共交通服务里的地铁接口。现在也内置了一个本地 Mock 服务，方便在真实接口权限还没下来前，先验证我们自己的调用、解析和展示逻辑。

## 已支持的接口

- 查询附近地铁：`/api/v1/bst/findNearMetroInfo`
- 查询地铁线路：`/api/v1/bst/queryMetroLine`
- 查询地铁到站详情：`/api/v1/bst/getMetroStopArriveDetails`

## 本地 Mock 能模拟什么

- 10 号线主线：虹桥火车站到基隆路
- 10 号线支线：航中路到基隆路
- 10 号线换乘站的换乘线路标签，例如虹桥火车站换乘 2 号线、17 号线
- 按早高峰、晚高峰、平峰、低峰生成不同发车间隔
- 查询时临时推演虚拟列车，不常驻消耗资源
- 返回随申行风格的分钟级到站信息，并附带 Mock 调试字段

注意：Mock 里的 2 号线、17 号线等只作为换乘标签存在，暂时不模拟这些线路的完整运行。

## 配置

真实接口配置可以参考 `env.example`：

```ini
SHMAAS_HOST=https://...
SHMAAS_MERCHANT_ID=...
SHMAAS_SALT=...
SHMAAS_CITY_CODE=...
```

真实 `merchantId`、`salt`、`host` 不要提交到仓库。

如果还没有真实随申行权限，可以先使用本地 Mock：

```powershell
copy env.mock.example .env
npm.cmd run mock
```

然后另开一个终端调用下面的测试命令。

## 命令

查询附近地铁站：

```powershell
npm.cmd run near -- --lat 31.194 --clilon 121.320 --radius 3000
```

查询 10 号线上行，方向为虹桥火车站/航中路到基隆路：

```powershell
npm.cmd run line -- --cityCode mock-shanghai --lineId mock-line-10 --direction 0 --indexId 10010
```

查询 10 号线下行，方向为基隆路到虹桥火车站/航中路：

```powershell
npm.cmd run line -- --cityCode mock-shanghai --lineId mock-line-10 --direction 1 --indexId 10010
```

查询五角场到站时间：

```powershell
npm.cmd run arrive -- --cityCode mock-shanghai --lineId mock-line-10 --lineName "10号线" --stopId mock-l10-wujiaochang --stopName "五角场" --direction 0
```

查询虹桥火车站到站时间：

```powershell
npm.cmd run arrive -- --cityCode mock-shanghai --lineId mock-line-10 --lineName "10号线" --stopId mock-l10-hongqiao-railway --stopName "虹桥火车站" --direction 0
```

查询航中路支线到站时间：

```powershell
npm.cmd run arrive -- --cityCode mock-shanghai --lineId mock-line-10 --lineName "10号线" --stopId mock-l10-hangzhong-road --stopName "航中路" --direction 0
```

查看帮助：

```powershell
npm.cmd run ssx -- help
```

## 签名说明

随申行网关要求请求体必须是紧凑 JSON。本工具使用：

```text
SHA1(JSON请求体 + X-Timestamp + SHMAAS_SALT)
```

生成 `X-Sign`，并带上 `X-Timestamp`、`X-MerchantId`、`X-SignAlgorithm` 请求头。
