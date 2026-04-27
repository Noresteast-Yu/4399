const express = require('express');
const router = express.Router();

// 获取实时出行提醒API
router.get('/', (req, res) => {
  // 模拟出行提醒数据
  const travelAlerts = [
    {
      id: '1',
      type: 'delay',
      title: 'G102次列车晚点',
      message: '预计晚点15分钟',
      timestamp: new Date().toISOString(),
    },
    {
      id: '2',
      type: 'control',
      title: '地铁2号线临时管制',
      message: '因设备检修，部分站点暂停服务',
      timestamp: new Date().toISOString(),
    },
  ];
  
  res.status(200).json(travelAlerts);
});

// 获取特定类型的出行提醒API
router.get('/:type', (req, res) => {
  const { type } = req.params;
  
  // 模拟特定类型的出行提醒
  const filteredAlerts = [
    {
      id: '1',
      type: type,
      title: type === 'delay' ? 'G102次列车晚点' : '地铁2号线临时管制',
      message: type === 'delay' ? '预计晚点15分钟' : '因设备检修，部分站点暂停服务',
      timestamp: new Date().toISOString(),
    },
  ];
  
  res.status(200).json(filteredAlerts);
});

module.exports = router;