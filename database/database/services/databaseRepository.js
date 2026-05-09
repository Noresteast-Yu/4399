const defaultConfig = require("../data/defaultConfig")
const stations = require("../data/stations")
const lines = require("../data/lines")
const lineStations = require("../data/lineStations")
const transferRules = require("../data/transferRules")
const commonRoutes = require("../data/commonRoutes")
const travelAlerts = require("../data/travelAlerts")
const trains = require("../data/trains")

const lineColors = {
  shanghai_metro_line_1: "#e60012",
  shanghai_metro_line_2: "#8bc34a",
  shanghai_metro_line_3: "#ffd200",
  shanghai_metro_line_4: "#4b0082",
  shanghai_metro_line_8: "#009fe8",
  shanghai_metro_line_10: "#c7a5d8",
  shanghai_metro_line_11: "#8d5a2b",
  shanghai_metro_line_12: "#007a60",
  shanghai_metro_line_13: "#f6a6c9",
  shanghai_metro_line_14: "#d7a300",
  shanghai_metro_line_17: "#b98b5f",
  shanghai_metro_line_18: "#b99a5b"
}

const stationAliases = {
  // The current Android demo still requests beijing_south.
  // Keep this alias so the database module can be connected without crashing.
  beijing_south: defaultConfig.default_origin_station_id,
  hongqiao: "shanghai_hongqiao_railway_station",
  tongji: "tongji_university"
}

function normalizeText(value) {
  return String(value || "").trim().toLowerCase()
}

function normalizeStationId(stationId) {
  return stationAliases[stationId] || stationId
}

function getStationById(stationId) {
  const normalizedId = normalizeStationId(stationId)
  return stations.find((station) => station.station_id === normalizedId) || null
}

function getStationByName(stationName) {
  const keyword = normalizeText(stationName)
  return (
    stations.find((station) =>
      normalizeText(station.station_name).includes(keyword)
    ) || null
  )
}

function getLineById(lineId) {
  return lines.find((line) => line.line_id === lineId) || null
}

function listLines() {
  return lines.map((line) => ({
    id: line.line_id,
    name: line.line_name,
    city: line.city,
    color: lineColors[line.line_id] || "#666666",
    directions: line.directions
  }))
}

function listStationsByLine(lineId) {
  return lineStations
    .filter((item) => item.line_id === lineId)
    .slice()
    .sort((a, b) => a.order - b.order)
}

function listTransferRules(originStationId, lineId) {
  return transferRules.filter(
    (rule) =>
      rule.origin_station_id === normalizeStationId(originStationId) &&
      rule.line_id === lineId
  )
}

function getTransferLineNames(lineIds) {
  return lineIds
    .map((lineId) => getLineById(lineId))
    .filter(Boolean)
    .map((line) => line.line_name)
}

function getStationInfo(stationId) {
  const station = getStationById(stationId)
  if (!station) {
    return null
  }

  const sequenceItem = lineStations.find(
    (item) => item.station_id === station.station_id
  )

  return {
    id: station.station_id,
    name: station.station_name,
    city: station.city,
    stationType: station.station_type,
    description: station.description,
    lines: getTransferLineNames(station.available_line_ids),
    firstTrain: "05:30",
    lastTrain: "23:30",
    interval: "约3-6分钟",
    order: sequenceItem ? sequenceItem.order : null,
    facilities: [
      { name: "卫生间", icon: "wc", location: "站厅层靠近主要出入口" },
      { name: "扶梯", icon: "escalator", location: "站厅至站台连接处" },
      { name: "无障碍电梯", icon: "accessibility", location: "站厅中部" }
    ],
    crowdLevels: [
      { time: "07:00-09:00", level: "拥挤", color: "#ff4757" },
      { time: "09:00-17:00", level: "适中", color: "#ffa502" },
      { time: "17:00-19:00", level: "拥挤", color: "#ff4757" },
      { time: "19:00-23:00", level: "宽松", color: "#2ed573" }
    ]
  }
}

function findBestTransferRule(start, end) {
  const startStation =
    getStationByName(start) || getStationById(defaultConfig.default_origin_station_id)
  const endStation = getStationByName(end)

  if (endStation) {
    const exactRule = transferRules.find(
      (rule) =>
        rule.origin_station_id === startStation.station_id &&
        rule.target_station_id === endStation.station_id
    )
    if (exactRule) {
      return exactRule
    }
  }

  return (
    transferRules.find(
      (rule) =>
        rule.origin_station_id === startStation.station_id &&
        rule.target_station_id === "tongji_university"
    ) || transferRules[0]
  )
}

function buildRoutePlanFromRule(rule, index) {
  const origin = getStationById(rule.origin_station_id)
  const target = getStationById(rule.target_station_id)
  const line = getLineById(rule.line_id)
  const transferLineNames = getTransferLineNames(rule.transfer_line_ids)

  return {
    id: rule.rule_id || String(index + 1),
    title: index === 0 ? "推荐路线" : `备选路线${index + 1}`,
    time: `${rule.estimated_time}分钟`,
    transfers: `${rule.transfer_line_ids.length}次换乘`,
    distance: `约${Math.max(1, Math.round(rule.stops_count * 1.2))}公里`,
    start: origin ? origin.station_name : "默认出发站",
    end: target ? target.station_name : "目标站",
    direction: rule.direction,
    carriageSuggestion: rule.carriage_suggestion,
    transferTip: rule.transfer_tip,
    transferLines: transferLineNames,
    tags: rule.tags,
    segments: [
      { type: "walk", distance: "约300米", time: "约5分钟" },
      {
        type: "subway",
        line: line ? line.line_name : rule.line_id,
        distance: `约${Math.max(1, Math.round(rule.stops_count * 1.2))}公里`,
        time: `${rule.estimated_time}分钟`
      },
      { type: "walk", distance: "约200米", time: "约3分钟" }
    ]
  }
}

function getRoutePlans(start, end) {
  const selectedRule = findBestTransferRule(start, end)
  const backupRules = transferRules
    .filter((rule) => rule.rule_id !== selectedRule.rule_id)
    .slice(0, 2)

  return [selectedRule].concat(backupRules).map(buildRoutePlanFromRule)
}

function getTrainInfo(trainNumber) {
  return (
    trains.find((train) => train.number === trainNumber) || {
      ...trains[0],
      number: trainNumber || trains[0].number
    }
  )
}

function getTrainGuide({ trainNumber, destination, currentCarriage }) {
  const train = getTrainInfo(trainNumber)
  return {
    recommendedCarriage: "17号",
    reason: `${destination || train.end} 到达后距离换乘通道更近`,
    path: `从当前${currentCarriage || "10"}号车厢向17号车厢方向移动，到站后按地铁换乘标识前往站厅。`,
    estimatedTime: "约2-4分钟"
  }
}

function startTransferSession(payload) {
  return {
    remainingTime: Number(payload.remainingTime) || 300,
    progressSteps: [
      { title: "换乘步行", progress: 60, time: "3分钟" },
      { title: "站台候车", progress: 30, time: "1分钟" },
      { title: "上车", progress: 10, time: "30秒" }
    ],
    optimalRoute: "从当前位置 -> 换乘通道 -> 目标线路站台",
    alternativePlan: {
      nextTrain: "10:30",
      estimatedArrival: "11:45"
    }
  }
}

function listCommonRoutes(userId) {
  return commonRoutes.filter((route) => route.userId === (userId || "default"))
}

function listTravelAlerts(type) {
  if (!type) {
    return travelAlerts
  }
  return travelAlerts.filter((alert) => alert.type === type)
}

module.exports = {
  defaultConfig,
  getStationById,
  getStationByName,
  getLineById,
  listLines,
  listStationsByLine,
  listTransferRules,
  getStationInfo,
  getRoutePlans,
  getTrainInfo,
  getTrainGuide,
  startTransferSession,
  listCommonRoutes,
  listTravelAlerts
}
