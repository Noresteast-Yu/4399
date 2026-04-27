const lineStations = [
  {
    line_id: "shanghai_metro_line_10",
    station_id: "shanghai_hongqiao_railway_station",
    station_name: "上海虹桥火车站",
    order: 1,
    is_transfer: true,
    transfer_line_ids: ["shanghai_metro_line_2", "shanghai_metro_line_17"]
  },
  {
    line_id: "shanghai_metro_line_10",
    station_id: "hongqiao_terminal_2",
    station_name: "虹桥2号航站楼",
    order: 2,
    is_transfer: true,
    transfer_line_ids: ["shanghai_metro_line_2"]
  },
  {
    line_id: "shanghai_metro_line_10",
    station_id: "hongqiao_terminal_1",
    station_name: "虹桥1号航站楼",
    order: 3,
    is_transfer: false,
    transfer_line_ids: []
  },
  {
    line_id: "shanghai_metro_line_10",
    station_id: "shanghai_zoo",
    station_name: "上海动物园",
    order: 4,
    is_transfer: false,
    transfer_line_ids: []
  },
  {
    line_id: "shanghai_metro_line_10",
    station_id: "longxi_road",
    station_name: "龙溪路",
    order: 5,
    is_transfer: false,
    transfer_line_ids: []
  },
  {
    line_id: "shanghai_metro_line_10",
    station_id: "shuicheng_road",
    station_name: "水城路",
    order: 6,
    is_transfer: false,
    transfer_line_ids: []
  },
  {
    line_id: "shanghai_metro_line_10",
    station_id: "yili_road",
    station_name: "伊犁路",
    order: 7,
    is_transfer: false,
    transfer_line_ids: []
  },
  {
    line_id: "shanghai_metro_line_10",
    station_id: "songyuan_road",
    station_name: "宋园路",
    order: 8,
    is_transfer: false,
    transfer_line_ids: []
  },
  {
    line_id: "shanghai_metro_line_10",
    station_id: "hongqiao_road",
    station_name: "虹桥路",
    order: 9,
    is_transfer: true,
    transfer_line_ids: ["shanghai_metro_line_3", "shanghai_metro_line_4"]
  },
  {
    line_id: "shanghai_metro_line_10",
    station_id: "jiaotong_university",
    station_name: "交通大学",
    order: 10,
    is_transfer: true,
    transfer_line_ids: ["shanghai_metro_line_11"]
  },
  {
    line_id: "shanghai_metro_line_10",
    station_id: "shanghai_library",
    station_name: "上海图书馆",
    order: 11,
    is_transfer: false,
    transfer_line_ids: []
  },
  {
    line_id: "shanghai_metro_line_10",
    station_id: "south_shaanxi_road",
    station_name: "陕西南路",
    order: 12,
    is_transfer: true,
    transfer_line_ids: ["shanghai_metro_line_1", "shanghai_metro_line_12"]
  },
  {
    line_id: "shanghai_metro_line_10",
    station_id: "xintiandi",
    station_name: "新天地",
    order: 13,
    is_transfer: true,
    transfer_line_ids: ["shanghai_metro_line_13"]
  },
  {
    line_id: "shanghai_metro_line_10",
    station_id: "laoximen",
    station_name: "老西门",
    order: 14,
    is_transfer: true,
    transfer_line_ids: ["shanghai_metro_line_8"]
  },
  {
    line_id: "shanghai_metro_line_10",
    station_id: "yuyuan",
    station_name: "豫园",
    order: 15,
    is_transfer: true,
    transfer_line_ids: ["shanghai_metro_line_14"]
  },
  {
    line_id: "shanghai_metro_line_10",
    station_id: "east_nanjing_road",
    station_name: "南京东路",
    order: 16,
    is_transfer: true,
    transfer_line_ids: ["shanghai_metro_line_2"]
  },
  {
    line_id: "shanghai_metro_line_10",
    station_id: "tiantong_road",
    station_name: "天潼路",
    order: 17,
    is_transfer: true,
    transfer_line_ids: ["shanghai_metro_line_12"]
  },
  {
    line_id: "shanghai_metro_line_10",
    station_id: "sichuan_north_road",
    station_name: "四川北路",
    order: 18,
    is_transfer: false,
    transfer_line_ids: []
  },
  {
    line_id: "shanghai_metro_line_10",
    station_id: "hailun_road",
    station_name: "海伦路",
    order: 19,
    is_transfer: false,
    transfer_line_ids: []
  },
  {
    line_id: "shanghai_metro_line_10",
    station_id: "youdian_xincun",
    station_name: "邮电新村",
    order: 20,
    is_transfer: false,
    transfer_line_ids: []
  },
  {
    line_id: "shanghai_metro_line_10",
    station_id: "siping_road",
    station_name: "四平路",
    order: 21,
    is_transfer: true,
    transfer_line_ids: ["shanghai_metro_line_8"]
  }
]

module.exports = lineStations
