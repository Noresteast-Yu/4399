const defaultConfig = require("../data/defaultConfig")
const stations = require("../data/stations")
const lines = require("../data/lines")
const lineStations = require("../data/lineStations")
const transferRules = require("../data/transferRules")
const staticResources = require("../data/staticResources")

function validateData() {
  const errors = []

  if (!defaultConfig.default_origin_station_id) {
    errors.push("defaultConfig 缺少 default_origin_station_id。")
  }
  if (!defaultConfig.default_line_id) {
    errors.push("defaultConfig 缺少 default_line_id。")
  }
  if (!defaultConfig.default_direction) {
    errors.push("defaultConfig 缺少 default_direction。")
  }

  const stationIdSet = new Set(
    stations.map(function (station) {
      return station.station_id
    })
  )

  const lineIdSet = new Set(
    lines.map(function (line) {
      return line.line_id
    })
  )

  if (
    defaultConfig.default_origin_station_id &&
    !stationIdSet.has(defaultConfig.default_origin_station_id)
  ) {
    errors.push("defaultConfig.default_origin_station_id 在 stations.js 中未找到。")
  }

  if (defaultConfig.default_line_id && !lineIdSet.has(defaultConfig.default_line_id)) {
    errors.push("defaultConfig.default_line_id 在 lines.js 中未找到。")
  }

  stations.forEach(function (station, index) {
    if (!station.station_id || !station.station_name) {
      errors.push(
        "stations.js 第 " +
          (index + 1) +
          " 项缺少 station_id 或 station_name。"
      )
    }
  })

  lines.forEach(function (line, index) {
    if (!line.line_id || !line.line_name) {
      errors.push("lines.js 第 " + (index + 1) + " 项缺少 line_id 或 line_name。")
    }
  })

  lineStations.forEach(function (lineStation, index) {
    if (
      !lineStation.line_id ||
      !lineStation.station_id ||
      typeof lineStation.order !== "number"
    ) {
      errors.push(
        "lineStations.js 第 " +
          (index + 1) +
          " 项缺少 line_id、station_id 或 order。"
      )
      return
    }

    if (!lineIdSet.has(lineStation.line_id)) {
      errors.push(
        "lineStations.js 第 " +
          (index + 1) +
          " 项的 line_id 在 lines.js 中未找到。"
      )
    }

    if (!stationIdSet.has(lineStation.station_id)) {
      errors.push(
        "lineStations.js 第 " +
          (index + 1) +
          " 项的 station_id 在 stations.js 中未找到。"
      )
    }
  })

  transferRules.forEach(function (rule, index) {
    if (
      !rule.rule_id ||
      !rule.origin_station_id ||
      !rule.line_id ||
      !rule.target_station_id
    ) {
      errors.push(
        "transferRules.js 第 " +
          (index + 1) +
          " 项缺少 rule_id、origin_station_id、line_id 或 target_station_id。"
      )
      return
    }

    if (!stationIdSet.has(rule.origin_station_id)) {
      errors.push(
        "transferRules.js 第 " +
          (index + 1) +
          " 项的 origin_station_id 在 stations.js 中未找到。"
      )
    }

    if (!lineIdSet.has(rule.line_id)) {
      errors.push(
        "transferRules.js 第 " +
          (index + 1) +
          " 项的 line_id 在 lines.js 中未找到。"
      )
    }

    if (!stationIdSet.has(rule.target_station_id)) {
      errors.push(
        "transferRules.js 第 " +
          (index + 1) +
          " 项的 target_station_id 在 stations.js 中未找到。"
      )
    }

    if (typeof rule.stops_count !== "number") {
      errors.push(
        "transferRules.js 第 " + (index + 1) + " 项的 stops_count 不是数字。"
      )
    }

    if (typeof rule.estimated_time !== "number") {
      errors.push(
        "transferRules.js 第 " + (index + 1) + " 项的 estimated_time 不是数字。"
      )
    }
  })

  if (!staticResources.icons) {
    errors.push("staticResources.js 缺少 icons。")
  }
  if (!staticResources.maps) {
    errors.push("staticResources.js 缺少 maps。")
  }

  return {
    ok: errors.length === 0,
    errors: errors
  }
}

module.exports = {
  validateData
}
