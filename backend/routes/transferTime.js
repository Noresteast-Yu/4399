const express = require('express');
const router = express.Router();

// 换乘时间管理API
router.post('/start', (req, res) => {
  const { from, to, remainingTime } = req.body;
  
  // 模拟换乘时间数据
  const transferInfo = {
    remainingTime: remainingTime || 300, // 默认5分钟
    progressSteps: [
      { title: '换乘步行', progress: 60, time: '3分钟' },
      { title: '站台候车', progress: 30, time: '1分钟' },
      { title: '上车', progress: 10, time: '30秒' },
    ],
    optimalRoute: '从当前位置 → 换乘通道 → 2号线站台',
    alternativePlan: {
      nextTrain: '10:30',
      estimatedArrival: '11:45',
    },
  };
  
  res.status(200).json(transferInfo);
});

// 实时更新换乘时间API
router.get('/update/:sessionId', (req, res) => {
  const { sessionId } = req.params;
  
  // 模拟实时更新数据
  const updateInfo = {
    remainingTime: Math.max(0, Math.floor(Math.random() * 300)),
    progress: Math.min(100, Math.floor(Math.random() * 100)),
  };
  
  res.status(200).json(updateInfo);
});

module.exports = router;