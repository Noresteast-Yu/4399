const express = require('express');
const router = express.Router();
const routeService = require('../services/routeService');

router.post('/plan', async (req, res) => {
  try {
    const { start, end } = req.body;
    
    if (!start || !end) {
      return res.status(400).json({
        success: false,
        error: '请提供起点和终点',
        routes: []
      });
    }

    const result = await routeService.planRoute(start, end);
    
    res.status(200).json(result);
  } catch (error) {
    console.error('路线规划API错误:', error);
    res.status(500).json({
      success: false,
      error: '服务器内部错误',
      routes: []
    });
  }
});

module.exports = router;