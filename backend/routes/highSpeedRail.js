const express = require('express');
const router = express.Router();

// 高铁车次查询API
router.get('/train/:trainNumber', (req, res) => {
  const { trainNumber } = req.params;
  
  // 模拟高铁车次数据
  const trainInfo = {
    number: trainNumber || 'G102',
    start: '北京南站',
    end: '上海虹桥站',
    departure: '08:00',
    arrival: '13:00',
    platform: '5',
    doorDirection: '左侧',
    stations: [
      '北京南站',
      '济南西站',
      '南京南站',
      '上海虹桥站',
    ],
    carriages: [
      { number: '1', type: '商务座', distance: '100米' },
      { number: '2-3', type: '一等座', distance: '80米' },
      { number: '4-15', type: '二等座', distance: '60米' },
      { number: '16', type: '餐车', distance: '40米' },
      { number: '17', type: '无障碍车厢', distance: '20米' },
    ],
  };
  
  res.status(200).json(trainInfo);
});

// 高铁下车引导API
router.post('/guide', (req, res) => {
  const { trainNumber, destination, currentCarriage } = req.body;
  
  // 模拟下车引导数据
  const guideInfo = {
    recommendedCarriage: '17号',
    reason: '距离换乘口最近',
    path: '从当前车厢 → 走到17号车厢 → 下车后右转 → 换乘通道',
    estimatedTime: '2分钟',
  };
  
  res.status(200).json(guideInfo);
});

module.exports = router;