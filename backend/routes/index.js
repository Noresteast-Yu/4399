const express = require('express');
const router = express.Router();

// 导入各个模块的路由
const routePlanRoutes = require('./routePlan');
const subwayServiceRoutes = require('./subwayService');
const highSpeedRailRoutes = require('./highSpeedRail');
const transferTimeRoutes = require('./transferTime');
const commonRoutesRoutes = require('./commonRoutes');
const travelAlertsRoutes = require('./travelAlerts');

// 注册路由
router.use('/route-plan', routePlanRoutes);
router.use('/subway-service', subwayServiceRoutes);
router.use('/high-speed-rail', highSpeedRailRoutes);
router.use('/transfer-time', transferTimeRoutes);
router.use('/common-routes', commonRoutesRoutes);
router.use('/travel-alerts', travelAlertsRoutes);

module.exports = router;