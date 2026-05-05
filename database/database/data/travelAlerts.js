const travelAlerts = [
  {
    "id": "alert_demo_peak_hongqiao",
    "type": "crowd",
    "level": "info",
    "title": "虹桥枢纽客流提示",
    "message": "早晚高峰虹桥火车站进站客流较大，建议提前预留进站和安检时间。",
    "related_station_id": "shanghai_hongqiao_railway_station",
    "created_at": "2026-05-05"
  },
  {
    "id": "alert_demo_tongji_peak",
    "type": "campus",
    "level": "info",
    "title": "同济大学站客流提示",
    "message": "同济大学站在上课、放学和晚高峰时段可能出现短时客流集中。",
    "related_station_id": "tongji_university",
    "created_at": "2026-05-05"
  }
]

module.exports = travelAlerts
