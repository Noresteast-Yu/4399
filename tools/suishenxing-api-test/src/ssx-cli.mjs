import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

const ENDPOINTS = {
  near: '/api/v1/bst/findNearMetroInfo',
  line: '/api/v1/bst/queryMetroLine',
  arrive: '/api/v1/bst/getMetroStopArriveDetails',
};

function loadDotEnv(filePath = path.resolve(process.cwd(), '.env')) {
  if (!fs.existsSync(filePath)) return;

  const content = fs.readFileSync(filePath, 'utf8');
  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;

    const equalIndex = line.indexOf('=');
    if (equalIndex < 0) continue;

    const key = line.slice(0, equalIndex).trim();
    let value = line.slice(equalIndex + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    if (!(key in process.env)) process.env[key] = value;
  }
}

function parseArgs(argv) {
  const args = {};
  const positional = [];

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith('--')) {
      positional.push(token);
      continue;
    }

    const raw = token.slice(2);
    const inlineEqual = raw.indexOf('=');
    if (inlineEqual >= 0) {
      args[raw.slice(0, inlineEqual)] = raw.slice(inlineEqual + 1);
      continue;
    }

    const next = argv[i + 1];
    if (next && !next.startsWith('--')) {
      args[raw] = next;
      i += 1;
    } else {
      args[raw] = true;
    }
  }

  return { args, positional };
}

function requireValue(value, name) {
  if (value === undefined || value === null || value === '') {
    throw new Error(`缺少必填参数：${name}`);
  }
  return String(value);
}

function getConfig() {
  const host = process.env.SHMAAS_HOST;
  const merchantId = process.env.SHMAAS_MERCHANT_ID;
  const salt = process.env.SHMAAS_SALT;

  if (!host || !merchantId || !salt) {
    throw new Error(
      '缺少配置：请在 .env 中填写 SHMAAS_HOST、SHMAAS_MERCHANT_ID、SHMAAS_SALT',
    );
  }

  return {
    host: host.replace(/\/+$/, ''),
    merchantId,
    salt,
  };
}

function formatTimestamp(date = new Date()) {
  const parts = new Intl.DateTimeFormat('zh-CN', {
    timeZone: 'Asia/Shanghai',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  }).formatToParts(date);

  const values = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  return `${values.year}${values.month}${values.day}${values.hour}${values.minute}${values.second}`;
}

function signBody(bodyJson, timestamp, salt) {
  return crypto
    .createHash('sha1')
    .update(`${bodyJson}${timestamp}${salt}`, 'utf8')
    .digest('hex');
}

async function requestShmaas(endpoint, body) {
  const config = getConfig();
  const bodyJson = JSON.stringify(body);
  const timestamp = formatTimestamp();
  const sign = signBody(bodyJson, timestamp, config.salt);
  const url = `${config.host}${endpoint}`;

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'X-Sign': sign,
      'X-SignAlgorithm': '1',
      'X-Timestamp': timestamp,
      'X-MerchantId': config.merchantId,
      'Content-Type': 'application/json',
    },
    body: bodyJson,
  });

  const text = await response.text();
  let data;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }

  return {
    ok: response.ok,
    status: response.status,
    url,
    requestBody: body,
    response: data,
  };
}

function unwrapPayload(response) {
  if (!response || typeof response !== 'object') return response;
  return response.data ?? response.result ?? response.returnData ?? response;
}

function printRaw(result) {
  console.log(JSON.stringify(result, null, 2));
}

function printGatewayStatus(result) {
  const response = result.response;
  const retCode = response && typeof response === 'object' ? response.retCode : undefined;
  const retMsg = response && typeof response === 'object' ? response.retMsg : undefined;

  console.log(`HTTP ${result.status} ${result.ok ? 'OK' : 'FAILED'}`);
  if (retCode !== undefined) console.log(`retCode: ${retCode}`);
  if (retMsg !== undefined) console.log(`retMsg: ${retMsg}`);
}

function getArray(value, keys) {
  if (Array.isArray(value)) return value;
  if (!value || typeof value !== 'object') return [];
  for (const key of keys) {
    if (Array.isArray(value[key])) return value[key];
  }
  return [];
}

function formatLineSummary(line) {
  const parts = [
    line.lineName,
    line.lineId ? `lineId=${line.lineId}` : '',
    line.stopId ? `stopId=${line.stopId}` : '',
    line.indexId !== undefined ? `indexId=${line.indexId}` : '',
    line.upDown !== undefined ? `direction=${line.upDown}` : '',
    line.interval ? `间隔=${line.interval}分钟` : '',
  ].filter(Boolean);
  return parts.join(' | ');
}

function printNear(result) {
  printGatewayStatus(result);
  const payload = unwrapPayload(result.response);
  const sites = getArray(payload, ['sites']);

  if (!sites.length) {
    console.log('未在响应中找到 sites。原始响应如下：');
    printRaw(result.response);
    return;
  }

  console.log(`\n附近地铁站：${sites.length} 个`);
  for (const site of sites) {
    console.log(`\n- ${site.stopName ?? '未知站名'} (${site.distance ?? '?'}m)`);
    for (const line of getArray(site, ['lines'])) {
      console.log(`  ${formatLineSummary(line)}`);
    }
  }
}

function printLine(result) {
  printGatewayStatus(result);
  const payload = unwrapPayload(result.response);
  const lines = getArray(payload, ['metroLine', 'metroLines']);

  if (!lines.length) {
    console.log('未在响应中找到 metroLine。原始响应如下：');
    printRaw(result.response);
    return;
  }

  for (const line of lines) {
    console.log(
      `\n${line.lineName ?? '未知线路'} ${line.startStopName ?? '?'} -> ${line.endStopName ?? '?'}`,
    );
    console.log(
      [
        line.lineId ? `lineId=${line.lineId}` : '',
        line.stopName ? `查询站点=${line.stopName}` : '',
        line.stopId ? `stopId=${line.stopId}` : '',
        line.upDown !== undefined ? `direction=${line.upDown}` : '',
        line.interval ? `间隔=${line.interval}分钟` : '',
        line.earlyTime ? `首班=${line.earlyTime}` : '',
        line.lateTime ? `末班=${line.lateTime}` : '',
      ].filter(Boolean).join(' | '),
    );

    const stations = getArray(line, ['sll']);
    for (const station of stations) {
      console.log(
        `  ${String(station.stopLevels ?? '').padStart(2, '0')} ${station.stationName ?? '未知站'} | stationId=${station.stationId ?? ''} | 换乘=${station.transferMetroLine ?? ''}`,
      );
    }
  }
}

function comfortText(value) {
  const map = {
    0: '未知',
    1: '舒适',
    2: '较舒适',
    3: '拥挤',
  };
  return map[value] ?? value ?? '未知';
}

function printArrive(result) {
  printGatewayStatus(result);
  const payload = unwrapPayload(result.response);
  const info = payload?.stopArriveInfo ?? payload?.data?.stopArriveInfo;

  if (!info) {
    console.log('未在响应中找到 stopArriveInfo。原始响应如下：');
    printRaw(result.response);
    return;
  }

  console.log(`\n站点：${info.stopName ?? '未知站点'}`);
  if (payload.interval) console.log(`发车间隔：${payload.interval}分钟`);
  console.log(`方向：${info.upDown ?? ''}`);
  console.log(`最近一班：${info.currentBusArriveTime ?? '?'} 分钟后到达`);
  console.log(`距离站数：${info.currentBusStopCount ?? '?'}`);
  console.log(`下一班：${info.nextBusArriveTime ?? '?'} 分钟后到达`);
  console.log(`拥挤度：${comfortText(info.currentBusComfort)}`);
  if (info.mockTrainId) console.log(`Mock train: ${info.mockTrainId}`);
  if (info.mockTrainLocation) console.log(`Mock location: ${info.mockTrainLocation}`);
  if (info.mockTrainNextStop) console.log(`Mock next stop: ${info.mockTrainNextStop}`);
  if (info.mockActiveTrainCount) console.log(`Mock active trains: ${info.mockActiveTrainCount}`);
}

function printHelp() {
  console.log(`上海地铁 / 随申行 API 最小测试工具

用法：
  npm.cmd run mock
  npm.cmd run near -- --lat <经度> --clilon <纬度> [--radius 3000]
  npm.cmd run line -- --cityCode <城市码> --lineId <线路ID> --direction <0|1> --indexId <数据库唯一ID> [--stopName 站名]
  npm.cmd run arrive -- --cityCode <城市码> --lineId <线路ID> --lineName <线路名> --stopId <站点ID> --stopName <站名> --direction <0|1>

配置：
  在 .env 中填写 SHMAAS_HOST、SHMAAS_MERCHANT_ID、SHMAAS_SALT。
  没有真实权限时，可以先复制 env.mock.example 为 .env，然后启动 mock。

调试：
  任意命令追加 --raw 可打印原始响应。
`);
}

async function run() {
  loadDotEnv();
  const [, , command = 'help', ...rest] = process.argv;
  const { args } = parseArgs(rest);

  if (command === 'help' || args.help) {
    printHelp();
    return;
  }

  let result;
  if (command === 'near') {
    const body = {
      lat: requireValue(args.lat ?? process.env.SHMAAS_DEFAULT_LAT, '--lat'),
      clilon: requireValue(args.clilon ?? process.env.SHMAAS_DEFAULT_CLILON, '--clilon'),
    };
    const radius = args.radius ?? process.env.SHMAAS_DEFAULT_RADIUS;
    if (radius !== undefined && radius !== '') {
      body.nearRadiusDistance = Number(radius);
    }
    result = await requestShmaas(ENDPOINTS.near, body);
    args.raw ? printRaw(result) : printNear(result);
    return;
  }

  if (command === 'line') {
    const body = {
      cityCode: requireValue(args.cityCode ?? process.env.SHMAAS_CITY_CODE, '--cityCode'),
      lineId: requireValue(args.lineId, '--lineId'),
      direction: requireValue(args.direction, '--direction'),
      indexId: Number(requireValue(args.indexId, '--indexId')),
    };
    if (args.stopName) body.stopName = String(args.stopName);
    if (args.lat && args.lon) {
      body.point = {
        lat: String(args.lat),
        lon: String(args.lon),
        ...(body.cityCode ? { cityCode: body.cityCode } : {}),
      };
    }
    result = await requestShmaas(ENDPOINTS.line, body);
    args.raw ? printRaw(result) : printLine(result);
    return;
  }

  if (command === 'arrive') {
    const body = {
      lineId: requireValue(args.lineId, '--lineId'),
      lineName: requireValue(args.lineName, '--lineName'),
      stopId: requireValue(args.stopId, '--stopId'),
      stopName: requireValue(args.stopName, '--stopName'),
      direction: requireValue(args.direction, '--direction'),
      cityCode: requireValue(args.cityCode ?? process.env.SHMAAS_CITY_CODE, '--cityCode'),
    };
    result = await requestShmaas(ENDPOINTS.arrive, body);
    args.raw ? printRaw(result) : printArrive(result);
    return;
  }

  throw new Error(`未知命令：${command}`);
}

run().catch((error) => {
  console.error(`错误：${error.message}`);
  process.exitCode = 1;
});
