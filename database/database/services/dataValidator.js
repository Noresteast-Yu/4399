const defaultConfig = require("../data/defaultConfig")
const stations = require("../data/stations")
const lines = require("../data/lines")
const lineStations = require("../data/lineStations")
const transferRules = require("../data/transferRules")
const commonRoutes = require("../data/commonRoutes")
const travelAlerts = require("../data/travelAlerts")
const trains = require("../data/trains")

function hasDuplicateIds(items, key) {
  const seen = new Set()
  const duplicates = []

  items.forEach((item) => {
    if (seen.has(item[key])) {
      duplicates.push(item[key])
    }
    seen.add(item[key])
  })

  return duplicates
}

function validateData() {
  const errors = []
  const stationIds = new Set(stations.map((station) => station.station_id))
  const lineIds = new Set(lines.map((line) => line.line_id))
  const ruleIds = new Set(transferRules.map((rule) => rule.rule_id))

  ;["default_origin_station_id", "default_line_id", "default_direction"].forEach(
    (key) => {
      if (!defaultConfig[key]) {
        errors.push(`defaultConfig 缺少字段：${key}`)
      }
    }
  )

  if (!stationIds.has(defaultConfig.default_origin_station_id)) {
    errors.push("defaultConfig.default_origin_station_id 在 stations 中不存在")
  }

  if (!lineIds.has(defaultConfig.default_line_id)) {
    errors.push("defaultConfig.default_line_id 在 lines 中不存在")
  }

  hasDuplicateIds(stations, "station_id").forEach((id) => {
    errors.push(`stations 存在重复 station_id：${id}`)
  })

  hasDuplicateIds(lines, "line_id").forEach((id) => {
    errors.push(`lines 存在重复 line_id：${id}`)
  })

  hasDuplicateIds(transferRules, "rule_id").forEach((id) => {
    errors.push(`transferRules 存在重复 rule_id：${id}`)
  })

  stations.forEach((station) => {
    if (!station.station_id || !station.station_name) {
      errors.push("stations 中存在缺少 station_id 或 station_name 的数据")
    }
    ;(station.available_line_ids || []).forEach((lineId) => {
      if (!lineIds.has(lineId)) {
        errors.push(`${station.station_name} 的 available_line_ids 引用了不存在的线路：${lineId}`)
      }
    })
  })

  lines.forEach((line) => {
    if (!line.line_id || !line.line_name) {
      errors.push("lines 中存在缺少 line_id 或 line_name 的数据")
    }
  })

  lineStations.forEach((item) => {
    if (!item.line_id || !item.station_id || typeof item.order !== "number") {
      errors.push("lineStations 中存在缺少 line_id、station_id 或 order 的数据")
    }
    if (!lineIds.has(item.line_id)) {
      errors.push(`lineStations 引用了不存在的 line_id：${item.line_id}`)
    }
    if (!stationIds.has(item.station_id)) {
      errors.push(`lineStations 引用了不存在的 station_id：${item.station_id}`)
    }
    ;(item.transfer_line_ids || []).forEach((lineId) => {
      if (!lineIds.has(lineId)) {
        errors.push(`${item.station_name} 的 transfer_line_ids 引用了不存在的线路：${lineId}`)
      }
    })
  })

  transferRules.forEach((rule) => {
    if (!rule.rule_id || !rule.origin_station_id || !rule.line_id || !rule.target_station_id) {
      errors.push("transferRules 中存在缺少 rule_id、origin_station_id、line_id 或 target_station_id 的数据")
    }
    if (!stationIds.has(rule.origin_station_id)) {
      errors.push(`transferRules 引用了不存在的 origin_station_id：${rule.origin_station_id}`)
    }
    if (!lineIds.has(rule.line_id)) {
      errors.push(`transferRules 引用了不存在的 line_id：${rule.line_id}`)
    }
    if (!stationIds.has(rule.target_station_id)) {
      errors.push(`transferRules 引用了不存在的 target_station_id：${rule.target_station_id}`)
    }
    if (typeof rule.stops_count !== "number") {
      errors.push(`${rule.rule_id} 的 stops_count 必须是数字`)
    }
    if (typeof rule.estimated_time !== "number") {
      errors.push(`${rule.rule_id} 的 estimated_time 必须是数字`)
    }
    ;(rule.transfer_line_ids || []).forEach((lineId) => {
      if (!lineIds.has(lineId)) {
        errors.push(`${rule.rule_id} 的 transfer_line_ids 引用了不存在的线路：${lineId}`)
      }
    })
  })

  commonRoutes.forEach((route) => {
    if (!route.id || !route.userId || !route.start || !route.end) {
      errors.push("commonRoutes 中存在缺少 id、userId、start 或 end 的数据")
    }
    if (route.related_rule_id && !ruleIds.has(route.related_rule_id)) {
      errors.push(`commonRoutes 引用了不存在的 related_rule_id：${route.related_rule_id}`)
    }
  })

  travelAlerts.forEach((alert) => {
    if (!alert.id || !alert.type || !alert.title || !alert.message) {
      errors.push("travelAlerts 中存在缺少 id、type、title 或 message 的数据")
    }
    if (alert.related_station_id && !stationIds.has(alert.related_station_id)) {
      errors.push(`travelAlerts 引用了不存在的 related_station_id：${alert.related_station_id}`)
    }
  })

  trains.forEach((train) => {
    if (!train.number || !train.start || !train.end) {
      errors.push("trains 中存在缺少 number、start 或 end 的数据")
    }
  })

  return {
    ok: errors.length === 0,
    errors
  }
}

module.exports = {
  validateData
}
