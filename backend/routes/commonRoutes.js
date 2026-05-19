const express = require('express');
const router = express.Router();

// 模拟常用路线数据存储
let commonRoutes = [
  {
    id: '1',
    start: '同济大学',
    end: '虹桥火车站',
    time: '32分钟',
    distance: '15公里',
  },
  {
    id: '2',
    start: '人民广场',
    end: '浦东机场',
    time: '65分钟',
    distance: '35公里',
  },
];

// 获取用户常用路线API - 支持 /user/default 和 /user/:userId
router.get('/user/default', (req, res) => {
  res.status(200).json({
    success: true,
    data: commonRoutes,
  });
});

router.get('/user/:userId', (req, res) => {
  res.status(200).json({
    success: true,
    data: commonRoutes,
  });
});

// 添加常用路线API
router.post('/add', (req, res) => {
  try {
    const { start, end } = req.body;

    if (!start || !end) {
      return res.status(400).json({
        success: false,
        error: '请提供起点和终点',
      });
    }

    const newRoute = {
      id: Date.now().toString(),
      start,
      end,
      time: '35分钟',
      distance: '14公里',
    };

    commonRoutes.push(newRoute);

    res.status(201).json({
      success: true,
      message: '路线添加成功',
      data: newRoute,
    });
  } catch (error) {
    console.error('添加常用路线失败:', error);
    res.status(500).json({
      success: false,
      error: '添加路线失败',
    });
  }
});

// 删除常用路线API
router.delete('/:routeId', (req, res) => {
  try {
    const { routeId } = req.params;

    const index = commonRoutes.findIndex(route => route.id === routeId);
    if (index === -1) {
      return res.status(404).json({
        success: false,
        error: '路线不存在',
      });
    }

    commonRoutes.splice(index, 1);

    res.status(200).json({
      success: true,
      message: '路线删除成功',
    });
  } catch (error) {
    console.error('删除常用路线失败:', error);
    res.status(500).json({
      success: false,
      error: '删除路线失败',
    });
  }
});

// 更新常用路线API
router.put('/:routeId', (req, res) => {
  try {
    const { routeId } = req.params;
    const { start, end } = req.body;

    const index = commonRoutes.findIndex(route => route.id === routeId);
    if (index === -1) {
      return res.status(404).json({
        success: false,
        error: '路线不存在',
      });
    }

    if (start) commonRoutes[index].start = start;
    if (end) commonRoutes[index].end = end;

    res.status(200).json({
      success: true,
      message: '路线更新成功',
      data: commonRoutes[index],
    });
  } catch (error) {
    console.error('更新常用路线失败:', error);
    res.status(500).json({
      success: false,
      error: '更新路线失败',
    });
  }
});

module.exports = router;
