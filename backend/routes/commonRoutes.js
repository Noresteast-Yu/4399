const express = require('express');
const router = express.Router();

// 获取用户常用路线API
router.get('/user/:userId', (req, res) => {
  const { userId } = req.params;
  
  // 模拟常用路线数据
  const commonRoutes = [
    {
      id: '1',
      start: '北京南站',
      end: '中关村',
      time: '30分钟',
      distance: '12公里',
    },
    {
      id: '2',
      start: '上海虹桥站',
      end: '陆家嘴',
      time: '45分钟',
      distance: '18公里',
    },
  ];
  
  res.status(200).json(commonRoutes);
});

// 添加常用路线API
router.post('/add', (req, res) => {
  const { userId, start, end } = req.body;
  
  // 模拟添加常用路线
  const newRoute = {
    id: Date.now().toString(),
    start,
    end,
    time: '35分钟',
    distance: '14公里',
  };
  
  res.status(201).json(newRoute);
});

// 删除常用路线API
router.delete('/:routeId', (req, res) => {
  const { routeId } = req.params;
  
  res.status(200).json({ message: '路线删除成功' });
});

module.exports = router;