import crypto from 'node:crypto';
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';

const routes = {
  near: '/api/v1/bst/findNearMetroInfo',
  line: '/api/v1/bst/queryMetroLine',
  arrive: '/api/v1/bst/getMetroStopArriveDetails',
};

const metroLine = {
  indexId: 10010,
  lineId: 'mock-line-10',
  lineName: '10号线',
  cityCode: 'mock-shanghai',
  priceRange: '3-7',
  startStopName: '虹桥火车站',
  branchStartStopName: '航中路',
  endStopName: '基隆路',
  earlyTime: '05:49',
  lateTime: '22:55',
  reverseEarlyTime: '05:58',
  reverseLateTime: '23:18',
};

const mainStations = [
  ['mock-l10-hongqiao-railway', '虹桥火车站', '2号线,17号线', '31.194', '121.320'],
  ['mock-l10-hongqiao-t2', '虹桥2号航站楼', '2号线', '31.194', '121.327'],
  ['mock-l10-hongqiao-t1', '虹桥1号航站楼', '', '31.197', '121.347'],
  ['mock-l10-shanghai-zoo', '上海动物园', '', '31.196', '121.368'],
  ['mock-l10-longxi-road', '龙溪路', '', '31.191', '121.386'],
  ['mock-l10-shuicheng-road', '水城路', '', '31.198', '121.398'],
  ['mock-l10-yili-road', '伊犁路', '', '31.204', '121.410'],
  ['mock-l10-songyuan-road', '宋园路', '', '31.203', '121.421'],
  ['mock-l10-hongqiao-road', '虹桥路', '3号线,4号线', '31.202', '121.429'],
  ['mock-l10-jiaotong-university', '交通大学', '11号线', '31.202', '121.441'],
  ['mock-l10-shanghai-library', '上海图书馆', '', '31.207', '121.450'],
  ['mock-l10-south-shaanxi-road', '陕西南路', '1号线,12号线', '31.216', '121.458'],
  ['mock-l10-xintiandi', '一大会址·新天地', '13号线', '31.221', '121.475'],
  ['mock-l10-laoximen', '老西门', '8号线', '31.224', '121.483'],
  ['mock-l10-yuyuan', '豫园', '14号线', '31.228', '121.493'],
  ['mock-l10-east-nanjing-road', '南京东路', '2号线', '31.239', '121.490'],
  ['mock-l10-tiantong-road', '天潼路', '12号线', '31.250', '121.488'],
  ['mock-l10-north-sichuan-road', '四川北路', '', '31.258', '121.484'],
  ['mock-l10-hailun-road', '海伦路', '4号线', '31.264', '121.488'],
  ['mock-l10-youdian-xincun', '邮电新村', '', '31.274', '121.500'],
  ['mock-l10-siping-road', '四平路', '8号线', '31.280', '121.509'],
  ['mock-l10-tongji-university', '同济大学', '', '31.288', '121.513'],
  ['mock-l10-guoquan-road', '国权路', '18号线', '31.295', '121.516'],
  ['mock-l10-wujiaochang', '五角场', '', '31.303', '121.514'],
  ['mock-l10-jiangwan-stadium', '江湾体育场', '', '31.309', '121.520'],
  ['mock-l10-sanmen-road', '三门路', '', '31.318', '121.522'],
  ['mock-l10-yingao-east-road', '殷高东路', '', '31.327', '121.527'],
  ['mock-l10-xinjiangwan-city', '新江湾城', '', '31.334', '121.506'],
  ['mock-l10-guofan-road', '国帆路', '', '31.348', '121.514'],
  ['mock-l10-shuangjiang-road', '双江路', '', '31.358', '121.542'],
  ['mock-l10-gaoqiao-west', '高桥西', '', '31.356', '121.563'],
  ['mock-l10-gaoqiao', '高桥', '', '31.353', '121.576'],
  ['mock-l10-gangcheng-road', '港城路', '6号线', '31.353', '121.586'],
  ['mock-l10-jilong-road', '基隆路', '', '31.356', '121.597'],
];

const branchStations = [
  ['mock-l10-hangzhong-road', '航中路', '', '31.171', '121.356'],
  ['mock-l10-ziteng-road', '紫藤路', '', '31.177', '121.370'],
  ['mock-l10-longbai-xincun', '龙柏新村', '', '31.183', '121.381'],
  mainStations[4],
];

const tripPatterns = [
  { id: 'main', startName: '虹桥火车站', endName: '基隆路', stations: mainStations },
  { id: 'branch', startName: '航中路', endName: '基隆路', stations: branchStations.concat(mainStations.slice(5)) },
];

function toStation(row, index, upDown, endStation) {
  return {
    stationId: row[0],
    stationName: row[1],
    lineId: metroLine.lineId,
    lineName: metroLine.lineName,
    type: 2,
    stopLevels: index + 1,
    upDown,
    upOpenDoor: index % 2 === 0 ? 'right' : 'left',
    downOpenDoor: index % 2 === 0 ? 'left' : 'right',
    earlyTime: upDown === 0 ? metroLine.earlyTime : metroLine.reverseEarlyTime,
    lateTime: upDown === 0 ? metroLine.lateTime : metroLine.reverseLateTime,
    extEarlyTime: '',
    extLateTime: '',
    endStopId: endStation[0],
    endStopName: endStation[1],
    transferMetroLine: row[2],
    point: { lat: row[3], lon: row[4] },
  };
}

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

function signBody(bodyJson, timestamp, salt) {
  return crypto
    .createHash('sha1')
    .update(`${bodyJson}${timestamp}${salt}`, 'utf8')
    .digest('hex');
}

function jsonResponse(res, status, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
  });
  res.end(body);
}

function success(data) {
  return { retCode: '000000', retMsg: 'success', data };
}

function failure(retCode, retMsg) {
  return { retCode, retMsg, data: null };
}

function minutesOfShanghaiDay(date = new Date()) {
  const parts = new Intl.DateTimeFormat('zh-CN', {
    timeZone: 'Asia/Shanghai',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).formatToParts(date);
  const values = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  return Number(values.hour) * 60 + Number(values.minute);
}

function getServicePlan(now = new Date()) {
  const minute = minutesOfShanghaiDay(now);
  if (minute >= 7 * 60 && minute < 9 * 60) {
    return {
      name: 'morningPeak',
      interval: 4,
      branchInterval: 9,
      segmentMinutes: 2,
      dwellMinutes: 0.5,
      comfort: 3,
      trainTarget: 50,
    };
  }
  if (minute >= 17 * 60 + 30 && minute < 20 * 60) {
    return {
      name: 'eveningPeak',
      interval: 4.5,
      branchInterval: 9,
      segmentMinutes: 2,
      dwellMinutes: 0.5,
      comfort: 3,
      trainTarget: 50,
    };
  }
  if (minute >= 9 * 60 && minute < 17 * 60 + 30) {
    return {
      name: 'offPeak',
      interval: 6,
      branchInterval: 12,
      segmentMinutes: 2,
      dwellMinutes: 0.5,
      comfort: 2,
      trainTarget: 35,
    };
  }
  return {
    name: 'lowPeak',
    interval: 8,
    branchInterval: 14,
    segmentMinutes: 2,
    dwellMinutes: 0.5,
    comfort: 1,
    trainTarget: 20,
  };
}

function findStationRow(stopId, stopName) {
  const allRows = [...mainStations, ...branchStations];
  return allRows.find((row) => row[0] === stopId) ||
    allRows.find((row) => row[1] === stopName) ||
    mainStations[0];
}

function patternContains(pattern, stationRow) {
  return pattern.stations.some((row) => row[0] === stationRow[0]);
}

function getPatternsForDirection(direction, stationRow) {
  const patterns = tripPatterns.filter((pattern) => patternContains(pattern, stationRow));
  return orientPatterns(patterns, direction);
}

function orientPatterns(patterns, direction) {
  if (Number(direction) === 1) {
    return patterns.map((pattern) => ({
      ...pattern,
      startName: pattern.endName,
      endName: pattern.startName,
      stations: [...pattern.stations].reverse(),
    }));
  }
  return patterns;
}

function buildLineResponse(body) {
  const direction = Number(body.direction ?? 0);
  const hasStationFilter = Boolean(body.stopId || body.stopName);
  const stationRow = hasStationFilter ? findStationRow(body.stopId, body.stopName) : null;
  const patterns = hasStationFilter
    ? getPatternsForDirection(direction, stationRow)
    : orientPatterns(tripPatterns, direction);
  const plan = getServicePlan();

  return success({
    metroLine: patterns.map((pattern) => {
      const selectedRow = stationRow
        ? pattern.stations.find((row) => row[0] === stationRow[0]) || pattern.stations[0]
        : pattern.stations[0];
      return {
        indexId: metroLine.indexId,
        lineId: body.lineId || metroLine.lineId,
        lineName: metroLine.lineName,
        startStopName: pattern.startName,
        endStopName: pattern.endName,
        priceRange: metroLine.priceRange,
        interval: String(plan.interval),
        upDown: direction,
        earlyTime: direction === 0 ? metroLine.earlyTime : metroLine.reverseEarlyTime,
        lateTime: direction === 0 ? metroLine.lateTime : metroLine.reverseLateTime,
        reverseEarlyTime: direction === 0 ? metroLine.reverseEarlyTime : metroLine.earlyTime,
        reverseLateTime: direction === 0 ? metroLine.reverseLateTime : metroLine.lateTime,
        stopName: selectedRow[1],
        stopId: selectedRow[0],
        sll: pattern.stations.map((row, index) =>
          toStation(row, index, direction, pattern.stations[pattern.stations.length - 1]),
        ),
      };
    }),
  });
}

function buildNearResponse() {
  const plan = getServicePlan();
  const nearbyRows = [mainStations[0], mainStations[1], branchStations[0]];

  return success({
    sites: nearbyRows.map((row, index) => ({
      stopName: row[1],
      distance: [180, 520, 2200][index],
      lines: [
        {
          indexId: metroLine.indexId,
          stopId: row[0],
          lineName: metroLine.lineName,
          lineId: metroLine.lineId,
          startStopName: row[0] === branchStations[0][0] ? metroLine.branchStartStopName : metroLine.startStopName,
          endStopName: metroLine.endStopName,
          startEarlyTime: metroLine.earlyTime,
          startLateTime: metroLine.lateTime,
          endEarlyTime: metroLine.reverseEarlyTime,
          endLateTime: metroLine.reverseLateTime,
          upDown: 0,
          interval: String(plan.interval),
        },
      ],
    })),
    info: [
      {
        lineName: metroLine.lineName,
        notification: '本响应来自本地 Mock Server，仅用于接口联调；站点 ID 不是随申行官方 ID。',
      },
    ],
  });
}

function getPatternInterval(pattern, plan) {
  return pattern.id === 'branch' ? plan.branchInterval : plan.interval;
}

function getPatternRuntime(pattern, plan) {
  return Math.max(0, (pattern.stations.length - 1) * (plan.segmentMinutes + plan.dwellMinutes));
}

function generateVirtualTrains(pattern, direction, plan, currentMinute) {
  const interval = getPatternInterval(pattern, plan);
  const runtime = getPatternRuntime(pattern, plan);
  const serviceStart = direction === 0 ? 5 * 60 + 45 : 5 * 60 + 55;
  const serviceEnd = direction === 0 ? 23 * 60 : 23 * 60 + 20;
  const firstDeparture = Math.floor((serviceStart - runtime - interval) / interval) * interval;
  const trains = [];

  for (let departure = firstDeparture; departure <= currentMinute + runtime + interval; departure += interval) {
    if (departure < serviceStart || departure > serviceEnd) continue;

    const age = currentMinute - departure;
    if (age < -interval * 2 || age > runtime) continue;

    const progress = Math.max(0, age) / (plan.segmentMinutes + plan.dwellMinutes);
    const currentIndex = Math.min(pattern.stations.length - 1, Math.max(0, Math.floor(progress)));
    const nextIndex = Math.min(pattern.stations.length - 1, currentIndex + 1);
    trains.push({
      id: `${pattern.id}-${direction}-${Math.round(departure)}`,
      pattern,
      departure,
      active: age >= 0,
      currentIndex,
      nextIndex,
      currentStopName: pattern.stations[currentIndex]?.[1] || pattern.startName,
      nextStopName: pattern.stations[nextIndex]?.[1] || pattern.endName,
    });
  }

  return trains;
}

function getArrivalCandidates(body) {
  const direction = Number(body.direction ?? 0);
  const stationRow = findStationRow(body.stopId, body.stopName);
  const patterns = getPatternsForDirection(direction, stationRow);
  const plan = getServicePlan();
  const currentMinute = minutesOfShanghaiDay();
  const candidates = [];
  let activeTrainCount = 0;

  for (const pattern of patterns) {
    const stationIndex = pattern.stations.findIndex((row) => row[0] === stationRow[0]);
    if (stationIndex < 0) continue;

    const trains = generateVirtualTrains(pattern, direction, plan, currentMinute);
    activeTrainCount += trains.filter((train) => train.active).length;

    for (const train of trains) {
      if (train.currentIndex > stationIndex) continue;

      const arrivalMinute = train.departure + stationIndex * (plan.segmentMinutes + plan.dwellMinutes);
      const arriveIn = arrivalMinute - currentMinute;
      if (arriveIn < 0) continue;

      candidates.push({
        arriveIn,
        stopCount: Math.max(0, stationIndex - train.currentIndex),
        pattern,
        train,
      });
    }
  }

  candidates.sort((a, b) => a.arriveIn - b.arriveIn);
  return { stationRow, plan, candidates, activeTrainCount };
}

function computeArrival(body) {
  const { stationRow, plan, candidates, activeTrainCount } = getArrivalCandidates(body);
  const first = candidates[0] || { arriveIn: plan.interval, stopCount: 1, train: null };
  const second = candidates[1] || { arriveIn: first.arriveIn + plan.interval, train: null };

  return {
    stationRow,
    interval: plan.interval,
    comfort: plan.comfort,
    firstMinutes: Math.max(1, Math.ceil(first.arriveIn)),
    secondMinutes: Math.max(1, Math.ceil(second.arriveIn)),
    stopCount: first.stopCount,
    activeTrainCount: Math.max(activeTrainCount, plan.trainTarget),
    servicePlan: plan.name,
    currentTrainId: first.train?.id || '',
    currentTrainLocation: first.train?.currentStopName || '',
    currentTrainNextStop: first.train?.nextStopName || '',
    nextTrainId: second.train?.id || '',
  };
}

function buildArriveResponse(body) {
  const arrival = computeArrival(body);

  return success({
    interval: String(arrival.interval),
    stopArriveInfo: {
      stopName: body.stopName || arrival.stationRow[1],
      currentBusComfort: arrival.comfort,
      upDown: String(body.direction ?? 0),
      currentBusStopCount: arrival.stopCount,
      currentBusArriveTime: String(arrival.firstMinutes),
      nextBusArriveTime: String(arrival.secondMinutes),
      mockTrainId: arrival.currentTrainId,
      mockTrainLocation: arrival.currentTrainLocation,
      mockTrainNextStop: arrival.currentTrainNextStop,
      mockNextTrainId: arrival.nextTrainId,
      mockActiveTrainCount: arrival.activeTrainCount,
      mockServicePlan: arrival.servicePlan,
    },
  });
}

async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  return Buffer.concat(chunks).toString('utf8');
}

function validateGateway(req, bodyJson) {
  const merchantId = req.headers['x-merchantid'];
  const timestamp = req.headers['x-timestamp'];
  const algorithm = req.headers['x-signalgorithm'];
  const sign = req.headers['x-sign'];

  if (!merchantId || !timestamp || !algorithm || !sign) {
    return failure('-2903001', 'missing gateway headers');
  }
  if (merchantId !== MERCHANT_ID) {
    return failure('-2903002', 'invalid merchantId');
  }
  if (algorithm !== '1') {
    return failure('-2903004', 'unsupported sign algorithm');
  }
  const expected = signBody(bodyJson, timestamp, SALT);
  if (expected !== sign) {
    return failure('-2903015', 'invalid sign');
  }
  return null;
}

loadDotEnv();

const PORT = Number(process.env.MOCK_PORT || 8787);
const MERCHANT_ID = process.env.MOCK_MERCHANT_ID || 'mock-merchant';
const SALT = process.env.MOCK_SALT || 'mock-salt';

const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Content-Type,X-Sign,X-SignAlgorithm,X-Timestamp,X-MerchantId',
      'Access-Control-Allow-Methods': 'POST,OPTIONS',
    });
    res.end();
    return;
  }

  if (req.method !== 'POST') {
    jsonResponse(res, 405, failure('-2903005', 'method not allowed'));
    return;
  }

  const bodyJson = await readBody(req);
  const gatewayError = validateGateway(req, bodyJson);
  if (gatewayError) {
    jsonResponse(res, 200, gatewayError);
    return;
  }

  let body = {};
  try {
    body = bodyJson ? JSON.parse(bodyJson) : {};
  } catch {
    jsonResponse(res, 200, failure('-2903006', 'invalid json'));
    return;
  }

  if (req.url === routes.near) {
    jsonResponse(res, 200, buildNearResponse(body));
    return;
  }
  if (req.url === routes.line) {
    jsonResponse(res, 200, buildLineResponse(body));
    return;
  }
  if (req.url === routes.arrive) {
    jsonResponse(res, 200, buildArriveResponse(body));
    return;
  }

  jsonResponse(res, 404, failure('-2903042', `unknown path: ${req.url}`));
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`Mock Shmaas server listening on http://127.0.0.1:${PORT}`);
  console.log(`merchantId=${MERCHANT_ID}`);
  console.log('salt=已隐藏');
  console.log('line=10号线 mock, main+branch, minute-level arrivals');
});
