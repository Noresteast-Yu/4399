const transferRules = [
  {
    "rule_id": "rule_hongqiao_to_terminal2_line2",
    "origin_station_id": "shanghai_hongqiao_railway_station",
    "line_id": "shanghai_metro_line_10",
    "target_station_id": "hongqiao_terminal_2",
    "direction": "往基隆路方向",
    "stops_count": 1,
    "estimated_time": 3,
    "transfer_line_ids": [
      "shanghai_metro_line_2"
    ],
    "carriage_suggestion": "建议前部车厢，便于到达换乘通道。",
    "transfer_tip": "到站后根据2号线指引标识步行换乘，通道较直观。",
    "tags": [
      "机场联动",
      "快速换乘",
      "出行常用"
    ]
  },
  {
    "rule_id": "rule_hongqiao_to_hongqiao_road",
    "origin_station_id": "shanghai_hongqiao_railway_station",
    "line_id": "shanghai_metro_line_10",
    "target_station_id": "hongqiao_road",
    "direction": "往基隆路方向",
    "stops_count": 8,
    "estimated_time": 18,
    "transfer_line_ids": [
      "shanghai_metro_line_3",
      "shanghai_metro_line_4"
    ],
    "carriage_suggestion": "建议中部车厢，换乘3/4号线步行距离更均衡。",
    "transfer_tip": "该站人流较大，注意看清3号线与4号线站台方向。",
    "tags": [
      "环线联动",
      "市区通达",
      "换乘"
    ]
  },
  {
    "rule_id": "rule_hongqiao_to_jiaoda",
    "origin_station_id": "shanghai_hongqiao_railway_station",
    "line_id": "shanghai_metro_line_10",
    "target_station_id": "jiaotong_university",
    "direction": "往基隆路方向",
    "stops_count": 9,
    "estimated_time": 20,
    "transfer_line_ids": [
      "shanghai_metro_line_11"
    ],
    "carriage_suggestion": "建议后部车厢，便于转乘11号线。",
    "transfer_tip": "11号线站台层级较深，预留2-3分钟步行与上下扶梯时间。",
    "tags": [
      "高校片区",
      "换乘",
      "中距离"
    ]
  }
]

module.exports = transferRules
