const stations = [
  {
    station_id: "shanghai_hongqiao_railway_station",
    station_name: "上海虹桥火车站",
    city: "上海",
    station_type: "高铁站/地铁站",
    available_line_ids: [
      "shanghai_metro_line_2",
      "shanghai_metro_line_10",
      "shanghai_metro_line_17"
    ],
    description:
      "上海虹桥火车站是上海重要综合交通枢纽。本项目第一版以内置默认场景演示从虹桥火车站乘坐10号线进行换乘。"
  },
  {
    station_id: "hongqiao_terminal_2",
    station_name: "虹桥2号航站楼",
    city: "上海",
    station_type: "地铁站",
    available_line_ids: ["shanghai_metro_line_2", "shanghai_metro_line_10"],
    description: "连接虹桥机场2号航站楼与轨道交通网络。"
  },
  {
    station_id: "hongqiao_terminal_1",
    station_name: "虹桥1号航站楼",
    city: "上海",
    station_type: "地铁站",
    available_line_ids: ["shanghai_metro_line_10"],
    description: "10号线沿线站点，服务虹桥片区。"
  },
  {
    station_id: "shanghai_zoo",
    station_name: "上海动物园",
    city: "上海",
    station_type: "地铁站",
    available_line_ids: ["shanghai_metro_line_10"],
    description: "10号线沿线站点。"
  },
  {
    station_id: "longxi_road",
    station_name: "龙溪路",
    city: "上海",
    station_type: "地铁站",
    available_line_ids: ["shanghai_metro_line_10"],
    description: "10号线沿线站点。"
  },
  {
    station_id: "shuicheng_road",
    station_name: "水城路",
    city: "上海",
    station_type: "地铁站",
    available_line_ids: ["shanghai_metro_line_10"],
    description: "10号线沿线站点。"
  },
  {
    station_id: "yili_road",
    station_name: "伊犁路",
    city: "上海",
    station_type: "地铁站",
    available_line_ids: ["shanghai_metro_line_10"],
    description: "10号线沿线站点。"
  },
  {
    station_id: "songyuan_road",
    station_name: "宋园路",
    city: "上海",
    station_type: "地铁站",
    available_line_ids: ["shanghai_metro_line_10"],
    description: "10号线沿线站点。"
  },
  {
    station_id: "hongqiao_road",
    station_name: "虹桥路",
    city: "上海",
    station_type: "地铁站",
    available_line_ids: [
      "shanghai_metro_line_3",
      "shanghai_metro_line_4",
      "shanghai_metro_line_10"
    ],
    description: "连接3号线、4号线和10号线的重要换乘站。"
  },
  {
    station_id: "jiaotong_university",
    station_name: "交通大学",
    city: "上海",
    station_type: "地铁站",
    available_line_ids: ["shanghai_metro_line_10", "shanghai_metro_line_11"],
    description: "连接10号线与11号线的换乘站。"
  },
  {
    station_id: "shanghai_library",
    station_name: "上海图书馆",
    city: "上海",
    station_type: "地铁站",
    available_line_ids: ["shanghai_metro_line_10"],
    description: "10号线沿线站点。"
  },
  {
    station_id: "south_shaanxi_road",
    station_name: "陕西南路",
    city: "上海",
    station_type: "地铁站",
    available_line_ids: [
      "shanghai_metro_line_1",
      "shanghai_metro_line_10",
      "shanghai_metro_line_12"
    ],
    description: "连接1号线、10号线与12号线的换乘站。"
  },
  {
    station_id: "xintiandi",
    station_name: "新天地",
    city: "上海",
    station_type: "地铁站",
    available_line_ids: ["shanghai_metro_line_10", "shanghai_metro_line_13"],
    description: "连接10号线与13号线，可前往市中心核心商圈。"
  },
  {
    station_id: "laoximen",
    station_name: "老西门",
    city: "上海",
    station_type: "地铁站",
    available_line_ids: ["shanghai_metro_line_8", "shanghai_metro_line_10"],
    description: "连接8号线与10号线。"
  },
  {
    station_id: "yuyuan",
    station_name: "豫园",
    city: "上海",
    station_type: "地铁站",
    available_line_ids: ["shanghai_metro_line_10", "shanghai_metro_line_14"],
    description: "连接10号线与14号线，靠近历史文化景区。"
  },
  {
    station_id: "east_nanjing_road",
    station_name: "南京东路",
    city: "上海",
    station_type: "地铁站",
    available_line_ids: ["shanghai_metro_line_2", "shanghai_metro_line_10"],
    description: "连接2号线与10号线，位于市中心商业区。"
  },
  {
    station_id: "tiantong_road",
    station_name: "天潼路",
    city: "上海",
    station_type: "地铁站",
    available_line_ids: ["shanghai_metro_line_10", "shanghai_metro_line_12"],
    description: "连接10号线与12号线。"
  },
  {
    station_id: "sichuan_north_road",
    station_name: "四川北路",
    city: "上海",
    station_type: "地铁站",
    available_line_ids: ["shanghai_metro_line_10"],
    description: "10号线沿线站点。"
  },
  {
    station_id: "hailun_road",
    station_name: "海伦路",
    city: "上海",
    station_type: "地铁站",
    available_line_ids: ["shanghai_metro_line_10"],
    description: "10号线沿线站点。"
  },
  {
    station_id: "youdian_xincun",
    station_name: "邮电新村",
    city: "上海",
    station_type: "地铁站",
    available_line_ids: ["shanghai_metro_line_10"],
    description: "10号线沿线站点。"
  },
  {
    station_id: "siping_road",
    station_name: "四平路",
    city: "上海",
    station_type: "地铁站",
    available_line_ids: ["shanghai_metro_line_8", "shanghai_metro_line_10"],
    description: "连接8号线与10号线。"
  }
]

module.exports = stations
