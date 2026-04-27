const express = require('express');
const router = express.Router();

// 路线规划API
router.post('/plan', (req, res) => {
  const { start, end } = req.body;
  
  // 模拟路线规划数据
  const routePlans = [
    {
      id: '1',
      title: '最快路线',
      time: '30分钟',
      transfers: '1次换乘',
      distance: '12公里',
      segments: [
        { type: 'walk', distance: '500米', time: '7分钟' },
        { type: 'subway', distance: '10公里', time: '20分钟' },
        { type: 'walk', distance: '500米', time: '3分钟' },
      ],
    },
    {
      id: '2',
      title: '最少换乘',
      time: '35分钟',
      transfers: '0次换乘',
      distance: '15公里',
      segments: [
        { type: 'walk', distance: '300米', time: '5分钟' },
        { type: 'subway', distance: '14公里', time: '28分钟' },
        { type: 'walk', distance: '200米', time: '2分钟' },
      ],
    },
    {
      id: '3',
      title: '最省体力',
      time: '40分钟',
      transfers: '1次换乘',
      distance: '13公里',
      segments: [
        { type: 'walk', distance: '200米', time: '3分钟' },
        { type: 'subway', distance: '12公里', time: '25分钟' },
        { type: 'walk', distance: '100米', time: '2分钟' },
      ],
    },
  ];
  
  res.status(200).json(routePlans);
});

module.exports = router;