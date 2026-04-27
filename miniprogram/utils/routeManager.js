const defaultConfig = require("../data/defaultConfig")
const stations = require("../data/stations")
const lines = require("../data/lines")
const lineStations = require("../data/lineStations")
const transferRules = require("../data/transferRules")
const staticResources = require("../data/staticResources")

function getDefaultConfig() {
  return { ...defaultConfig }
}

function getDefaultOriginStation() {
  const station = stations.find(function (item) {
    return item.station_id === defaultConfig.default_origin_station_id
  })
  return station ? { ...station } : null
}

function getDefaultLine() {
  const line = lines.find(function (item) {
    return item.line_id === defaultConfig.default_line_id
  })
  return line ? { ...line } : null
}

function listStations() {
  return stations.map(function (item) {
    return { ...item }
  })
}

function listLines() {
  return lines.map(function (item) {
    return { ...item }
  })
}

function getStationById(stationId) {
  const station = stations.find(function (item) {
    return item.station_id === stationId
  })
  return station ? { ...station } : null
}

function getLineById(lineId) {
  const line = lines.find(function (item) {
    return item.line_id === lineId
  })
  return line ? { ...line } : null
}

function listStationsByLine(lineId) {
  return lineStations
    .filter(function (item) {
      return item.line_id === lineId
    })
    .sort(function (a, b) {
      return a.order - b.order
    })
    .map(function (item) {
      return { ...item }
    })
}

function listTransferRulesByOriginAndLine(originStationId, lineId) {
  return transferRules
    .filter(function (rule) {
      return rule.origin_station_id === originStationId && rule.line_id === lineId
    })
    .map(function (rule) {
      return { ...rule }
    })
}

function searchTransferRules(keyword, originStationId, lineId) {
  const rules = listTransferRulesByOriginAndLine(originStationId, lineId)
  const normalizedKeyword = String(keyword || "")
    .trim()
    .toLowerCase()

  if (!normalizedKeyword) {
    return rules
  }

  return rules.filter(function (rule) {
    const targetStation = getStationById(rule.target_station_id)
    const transferLineNames = rule.transfer_line_ids
      .map(function (transferLineId) {
        const line = getLineById(transferLineId)
        return line ? line.line_name : ""
      })
      .filter(Boolean)
      .join(" ")
      .toLowerCase()

    const searchText = [
      targetStation ? targetStation.station_name : "",
      transferLineNames,
      (rule.tags || []).join(" "),
      rule.transfer_tip || ""
    ]
      .join(" ")
      .toLowerCase()

    return searchText.indexOf(normalizedKeyword) > -1
  })
}

function getRoutePlan(ruleId) {
  const rule = transferRules.find(function (item) {
    return item.rule_id === ruleId
  })

  if (!rule) {
    return null
  }

  const originStation = getStationById(rule.origin_station_id)
  const line = getLineById(rule.line_id)
  const targetStation = getStationById(rule.target_station_id)
  const transferLines = (rule.transfer_line_ids || [])
    .map(function (transferLineId) {
      return getLineById(transferLineId)
    })
    .filter(Boolean)

  return {
    rule_id: rule.rule_id,
    origin_station: originStation,
    line: line,
    target_station: targetStation,
    transfer_lines: transferLines,
    direction: rule.direction,
    stops_count: rule.stops_count,
    estimated_time: rule.estimated_time,
    carriage_suggestion: rule.carriage_suggestion,
    transfer_tip: rule.transfer_tip,
    tags: (rule.tags || []).slice()
  }
}

function getStaticResource(resourceType, resourceName) {
  if (!staticResources[resourceType]) {
    return null
  }

  return staticResources[resourceType][resourceName] || null
}

module.exports = {
  getDefaultConfig,
  getDefaultOriginStation,
  getDefaultLine,
  listStations,
  listLines,
  getStationById,
  getLineById,
  listStationsByLine,
  listTransferRulesByOriginAndLine,
  searchTransferRules,
  getRoutePlan,
  getStaticResource
}
