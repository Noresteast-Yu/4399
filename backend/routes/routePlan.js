const express = require('express');
const router = express.Router();
const databaseRepository = require('../../database/database/services/databaseRepository');

// 路线规划 API
// 目前先接入本地数据库/静态数据模块，后续可以把 databaseRepository 替换为 MySQL 实现。
router.post('/plan', (req, res) => {
  const { start, end } = req.body || {};

  try {
    const routePlans = databaseRepository.getRoutePlans(start, end);
    return res.status(200).json(routePlans);
  } catch (error) {
    return res.status(500).json({
      message: '路线规划失败',
      error: error.message
    });
  }
});

module.exports = router;
