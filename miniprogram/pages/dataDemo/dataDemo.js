const routeManager = require("../../utils/routeManager")
const dataValidator = require("../../utils/dataValidator")

function formatTransferLineText(lineNames) {
  if (!lineNames || !lineNames.length) {
    return "暂无"
  }
  return lineNames.join("、")
}

Page({
  data: {
    defaultConfig: {},
    defaultOriginStation: {},
    defaultLine: {},
    keyword: "",
    lineStations: [],
    transferRules: [],
    filteredRules: [],
    selectedRuleId: "",
    routePlan: null,
    resources: {
      metroIcon: "",
      transferIcon: "",
      line10Map: ""
    },
    validationResult: {
      ok: true,
      errors: []
    }
  },

  onLoad() {
    this.initDemoData()
  },

  initDemoData() {
    const defaultConfig = routeManager.getDefaultConfig()
    const defaultOriginStation = routeManager.getDefaultOriginStation()
    const defaultLine = routeManager.getDefaultLine()

    const lineStations = this.decorateLineStations(
      routeManager.listStationsByLine(defaultConfig.default_line_id)
    )

    const transferRulesRaw = routeManager.listTransferRulesByOriginAndLine(
      defaultConfig.default_origin_station_id,
      defaultConfig.default_line_id
    )
    const transferRules = this.decorateRules(transferRulesRaw)

    const selectedRuleId = transferRules.length > 0 ? transferRules[0].rule_id : ""
    const routePlan = selectedRuleId
      ? this.decorateRoutePlan(routeManager.getRoutePlan(selectedRuleId))
      : null

    const resources = {
      metroIcon: routeManager.getStaticResource("icons", "metro"),
      transferIcon: routeManager.getStaticResource("icons", "transfer"),
      line10Map: routeManager.getStaticResource("maps", "line10_demo")
    }

    const validationResult = dataValidator.validateData()

    this.setData({
      defaultConfig: defaultConfig,
      defaultOriginStation: defaultOriginStation,
      defaultLine: defaultLine,
      lineStations: lineStations,
      transferRules: transferRules,
      filteredRules: transferRules,
      selectedRuleId: selectedRuleId,
      routePlan: routePlan,
      resources: resources,
      validationResult: validationResult
    })
  },

  decorateLineStations(stations) {
    return stations.map(function (station) {
      const transferLineNames = (station.transfer_line_ids || [])
        .map(function (lineId) {
          const line = routeManager.getLineById(lineId)
          return line ? line.line_name : "未知线路"
        })
        .filter(Boolean)

      return {
        ...station,
        transfer_line_names: transferLineNames,
        transfer_line_text: formatTransferLineText(transferLineNames)
      }
    })
  },

  decorateRules(rules) {
    return rules.map(function (rule) {
      const targetStation = routeManager.getStationById(rule.target_station_id)
      const transferLineNames = (rule.transfer_line_ids || [])
        .map(function (lineId) {
          const line = routeManager.getLineById(lineId)
          return line ? line.line_name : "未知线路"
        })
        .filter(Boolean)

      return {
        ...rule,
        target_station_name: targetStation ? targetStation.station_name : "未知站点",
        transfer_line_names: transferLineNames,
        transfer_line_text: formatTransferLineText(transferLineNames),
        tags_text: (rule.tags || []).join(" · ")
      }
    })
  },

  decorateRoutePlan(plan) {
    if (!plan) {
      return null
    }

    const transferLineNames = (plan.transfer_lines || []).map(function (line) {
      return line.line_name
    })

    return {
      ...plan,
      origin_station_name: plan.origin_station ? plan.origin_station.station_name : "--",
      line_name: plan.line ? plan.line.line_name : "--",
      target_station_name: plan.target_station ? plan.target_station.station_name : "--",
      transfer_line_text: formatTransferLineText(transferLineNames)
    }
  },

  onSearchInput(event) {
    const keyword = event.detail.value || ""
    const defaultConfig = this.data.defaultConfig || {}

    const searchedRulesRaw = routeManager.searchTransferRules(
      keyword,
      defaultConfig.default_origin_station_id,
      defaultConfig.default_line_id
    )
    const filteredRules = this.decorateRules(searchedRulesRaw)

    let selectedRuleId = this.data.selectedRuleId
    let routePlan = this.data.routePlan

    const selectedStillExists = filteredRules.some(function (rule) {
      return rule.rule_id === selectedRuleId
    })

    if (!selectedStillExists) {
      selectedRuleId = filteredRules.length > 0 ? filteredRules[0].rule_id : ""
      routePlan = selectedRuleId
        ? this.decorateRoutePlan(routeManager.getRoutePlan(selectedRuleId))
        : null
    }

    this.setData({
      keyword: keyword,
      filteredRules: filteredRules,
      selectedRuleId: selectedRuleId,
      routePlan: routePlan
    })
  },

  onSelectRule(event) {
    const ruleId = event.currentTarget.dataset.ruleId
    const routePlan = this.decorateRoutePlan(routeManager.getRoutePlan(ruleId))

    this.setData({
      selectedRuleId: ruleId,
      routePlan: routePlan
    })
  }
})
