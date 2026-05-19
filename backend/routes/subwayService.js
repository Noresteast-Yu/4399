const express = require('express');
const router = express.Router();

// 地铁站点信息API
router.get('/station/:stationId', (req, res) => {
  const { stationId } = req.params;
  
  // 模拟地铁站点数据
  const stationInfo = {
    id: stationId,
    name: '北京南站',
    lines: ['地铁4号线', '14号线'],
    firstTrain: '05:30',
    lastTrain: '23:30',
    interval: '2-5分钟',
    facilities: [
      { name: '卫生间', icon: 'wc', location: '站厅层东侧' },
      { name: '电梯', icon: 'elevator', location: '站台中部' },
      { name: '扶梯', icon: 'escalator', location: '站厅层南北两侧' },
      { name: '便利店', icon: 'store', location: '站厅层西侧' },
      { name: '无障碍设施', icon: 'accessibility', location: '全站覆盖' },
    ],
    crowdLevels: [
      { time: '07:00-09:00', level: '拥挤', color: '#ff4757' },
      { time: '09:00-17:00', level: '适中', color: '#ffa502' },
      { time: '17:00-19:00', level: '拥挤', color: '#ff4757' },
      { time: '19:00-23:00', level: '宽松', color: '#2ed573' },
    ],
  };
  
  res.status(200).json(stationInfo);
});

// 地铁线路信息API
router.get('/lines', (req, res) => {
  // 模拟地铁线路数据
  const lines = [
    { id: '1', name: '地铁1号线', color: '#ff4757' },
    { id: '2', name: '地铁2号线', color: '#2ed573' },
    { id: '4', name: '地铁4号线', color: '#70a1ff' },
    { id: '14', name: '地铁14号线', color: '#ff6b81' },
  ];
  
  res.status(200).json(lines);
});

module.exports = router;