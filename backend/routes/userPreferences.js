const express = require('express');
const router = express.Router();

let userPreferences = {
  travelPreferences: {
    preferLessWalking: false,
    preferLessTransfers: true,
    preferFastestRoute: false,
    avoidCrowdedLines: false,
    preferredRouteType: 'fastest',
  },
  mobilitySettings: {
    mobilityLevel: 'normal',
    needElevator: false,
    needEscalator: false,
    avoidStairs: false,
    maxWalkingDistance: 500,
  },
  luggageSettings: {
    hasLuggage: false,
    luggageSize: 'small',
    luggageCount: 0,
    needWideGate: false,
  },
};

router.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    data: userPreferences,
  });
});

router.put('/', (req, res) => {
  try {
    const { travelPreferences, mobilitySettings, luggageSettings } = req.body;

    if (travelPreferences) {
      userPreferences.travelPreferences = {
        ...userPreferences.travelPreferences,
        ...travelPreferences,
      };
    }

    if (mobilitySettings) {
      userPreferences.mobilitySettings = {
        ...userPreferences.mobilitySettings,
        ...mobilitySettings,
      };
    }

    if (luggageSettings) {
      userPreferences.luggageSettings = {
        ...userPreferences.luggageSettings,
        ...luggageSettings,
      };
    }

    res.status(200).json({
      success: true,
      message: '偏好设置已更新',
      data: userPreferences,
    });
  } catch (error) {
    console.error('更新用户偏好失败:', error);
    res.status(500).json({
      success: false,
      error: '更新偏好设置失败',
    });
  }
});

router.put('/travel-preferences', (req, res) => {
  try {
    userPreferences.travelPreferences = {
      ...userPreferences.travelPreferences,
      ...req.body,
    };

    res.status(200).json({
      success: true,
      message: '出行偏好已更新',
      data: userPreferences.travelPreferences,
    });
  } catch (error) {
    console.error('更新出行偏好失败:', error);
    res.status(500).json({
      success: false,
      error: '更新出行偏好失败',
    });
  }
});

router.put('/mobility-settings', (req, res) => {
  try {
    userPreferences.mobilitySettings = {
      ...userPreferences.mobilitySettings,
      ...req.body,
    };

    res.status(200).json({
      success: true,
      message: '行动能力设置已更新',
      data: userPreferences.mobilitySettings,
    });
  } catch (error) {
    console.error('更新行动能力设置失败:', error);
    res.status(500).json({
      success: false,
      error: '更新行动能力设置失败',
    });
  }
});

router.put('/luggage-settings', (req, res) => {
  try {
    userPreferences.luggageSettings = {
      ...userPreferences.luggageSettings,
      ...req.body,
    };

    res.status(200).json({
      success: true,
      message: '行李设置已更新',
      data: userPreferences.luggageSettings,
    });
  } catch (error) {
    console.error('更新行李设置失败:', error);
    res.status(500).json({
      success: false,
      error: '更新行李设置失败',
    });
  }
});

module.exports = router;
