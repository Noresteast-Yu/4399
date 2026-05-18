const express = require('express');
const router = express.Router();
const databaseRepository = require('../../database/database/services/databaseRepository');

// 地铁站点信息 API
// 数据来源：database/database/services/databaseRepository.js
router.get('/station/:stationId', (req, res) => {
  const { stationId } = req.params;
  const stationInfo = databaseRepository.getStationInfo(stationId);

  if (!stationInfo) {
    return res.status(404).json({
      message: '未找到站点信息',
      stationId
    });
  }

  return res.status(200).json(stationInfo);
});

// 地铁线路信息 API
router.get('/lines', (req, res) => {
  const lines = databaseRepository.listLines();
  return res.status(200).json(lines);
});

// 查询某条线路的站点顺序，方便前端展示线路列表
router.get('/line/:lineId/stations', (req, res) => {
  const { lineId } = req.params;
  const stations = databaseRepository.listStationsByLine(lineId);

  return res.status(200).json({
    lineId,
    count: stations.length,
    stations
  });
});

// 查询指定出发站和线路下的换乘规则
router.get('/transfer-rules', (req, res) => {
  const { originStationId, lineId } = req.query;
  const origin = originStationId || databaseRepository.defaultConfig.default_origin_station_id;
  const line = lineId || databaseRepository.defaultConfig.default_line_id;
  const rules = databaseRepository.listTransferRules(origin, line);

  return res.status(200).json({
    originStationId: origin,
    lineId: line,
    count: rules.length,
    rules
  });
});

module.exports = router;
