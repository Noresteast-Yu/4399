-- 地铁跑酷换乘助手：基础交通数据 MySQL 演示数据
-- 重点：先补齐上海虹桥火车站到同济大学的 10 号线沿途站点。
-- 说明：站点顺序按课程项目演示场景维护，可后续继续替换为更完整的官方运营数据。

USE metro_decision_assistant;
SET NAMES utf8mb4;

INSERT INTO metro_lines (
  line_id,
  line_name,
  city,
  color_name,
  color_hex,
  directions,
  description
) VALUES
('shanghai_metro_line_1', '上海地铁1号线', '上海', '红色', '#E4002B', '往富锦路方向,往莘庄方向', '换乘参考线路。'),
('shanghai_metro_line_2', '上海地铁2号线', '上海', '绿色', '#8CC63F', '往浦东1号2号航站楼方向,往徐泾东方向', '换乘参考线路，连接虹桥枢纽和南京东路等站。'),
('shanghai_metro_line_3', '上海地铁3号线', '上海', '黄色', '#FFD100', '往江杨北路方向,往上海南站方向', '换乘参考线路。'),
('shanghai_metro_line_4', '上海地铁4号线', '上海', '紫色', '#5F259F', '内圈,外圈', '换乘参考线路。'),
('shanghai_metro_line_8', '上海地铁8号线', '上海', '蓝色', '#009BDE', '往市光路方向,往沈杜公路方向', '换乘参考线路。'),
('shanghai_metro_line_10', '上海地铁10号线', '上海', '淡紫色', '#C5A3FF', '往基隆路方向,往虹桥火车站方向', '本项目基础演示线路，默认整理虹桥火车站至同济大学区间。'),
('shanghai_metro_line_11', '上海地铁11号线', '上海', '棕色', '#7A3E2F', '往迪士尼方向,往嘉定北/花桥方向', '换乘参考线路。'),
('shanghai_metro_line_12', '上海地铁12号线', '上海', '深绿色', '#007A3D', '往金海路方向,往七莘路方向', '换乘参考线路。'),
('shanghai_metro_line_13', '上海地铁13号线', '上海', '粉色', '#F4A6C8', '往张江路方向,往金运路方向', '换乘参考线路。'),
('shanghai_metro_line_14', '上海地铁14号线', '上海', '橄榄色', '#B2A72C', '往桂桥路方向,往封浜方向', '换乘参考线路。'),
('shanghai_metro_line_17', '上海地铁17号线', '上海', '棕黄色', '#B08A00', '往东方绿舟方向,往虹桥火车站方向', '虹桥枢纽换乘参考线路。'),
('shanghai_metro_line_18', '上海地铁18号线', '上海', '土黄色', '#C8A45D', '往长江南路方向,往航头方向', '同济大学附近可衔接的参考线路，用于候选路线演示。');

INSERT INTO stations (
  station_id,
  station_name,
  station_alias,
  city,
  district,
  station_type,
  description
) VALUES
('shanghai_hongqiao_railway_station', '上海虹桥火车站', '虹桥火车站', '上海', '闵行区', '高铁站/地铁站', '上海重要综合交通枢纽，可换乘地铁2号线、10号线、17号线。'),
('hongqiao_terminal_2', '虹桥2号航站楼', NULL, '上海', '闵行区', '地铁站/机场航站楼', '虹桥枢纽站点，可换乘2号线。'),
('hongqiao_terminal_1', '虹桥1号航站楼', NULL, '上海', '长宁区', '地铁站/机场航站楼', '10号线虹桥机场相关站点。'),
('shanghai_zoo', '上海动物园', NULL, '上海', '长宁区', '地铁站', '10号线沿线站点。'),
('longxi_road', '龙溪路', NULL, '上海', '长宁区', '地铁站', '10号线沿线站点。'),
('shuicheng_road', '水城路', NULL, '上海', '长宁区', '地铁站', '10号线沿线站点。'),
('yili_road', '伊犁路', NULL, '上海', '长宁区', '地铁站', '10号线沿线站点。'),
('songyuan_road', '宋园路', NULL, '上海', '长宁区', '地铁站', '10号线沿线站点。'),
('hongqiao_road', '虹桥路', NULL, '上海', '长宁区', '地铁站/换乘站', '10号线换乘站，可换乘3号线、4号线。'),
('jiaotong_university', '交通大学', NULL, '上海', '徐汇区', '地铁站/换乘站', '10号线换乘站，可换乘11号线。'),
('shanghai_library', '上海图书馆', NULL, '上海', '徐汇区', '地铁站', '10号线沿线站点。'),
('south_shaanxi_road', '陕西南路', NULL, '上海', '徐汇区/黄浦区', '地铁站/换乘站', '10号线换乘站，可换乘1号线、12号线。'),
('site_first_cpc_xintiandi', '一大会址·新天地', '新天地', '上海', '黄浦区', '地铁站/换乘站', '10号线换乘站，可换乘13号线。'),
('laoximen', '老西门', NULL, '上海', '黄浦区', '地铁站/换乘站', '10号线换乘站，可换乘8号线。'),
('yuyuan', '豫园', NULL, '上海', '黄浦区', '地铁站/换乘站', '10号线换乘站，可换乘14号线。'),
('east_nanjing_road', '南京东路', NULL, '上海', '黄浦区', '地铁站/换乘站', '10号线换乘站，可换乘2号线。'),
('tiantong_road', '天潼路', NULL, '上海', '静安区/虹口区', '地铁站/换乘站', '10号线换乘站，可换乘12号线。'),
('north_sichuan_road', '四川北路', NULL, '上海', '虹口区', '地铁站', '10号线沿线站点。'),
('hailun_road', '海伦路', NULL, '上海', '虹口区', '地铁站/换乘站', '10号线换乘站，可换乘4号线。'),
('youdian_xincun', '邮电新村', NULL, '上海', '虹口区', '地铁站', '10号线沿线站点。'),
('siping_road', '四平路', NULL, '上海', '虹口区/杨浦区', '地铁站/换乘站', '10号线换乘站，可换乘8号线。'),
('tongji_university', '同济大学', NULL, '上海', '杨浦区', '地铁站', '10号线沿线站点，靠近同济大学四平路校区。');

INSERT INTO line_stations (
  line_id,
  station_id,
  direction,
  station_order,
  is_transfer,
  transfer_line_ids,
  platform_tip
) VALUES
('shanghai_metro_line_10', 'shanghai_hongqiao_railway_station', '往基隆路方向', 1, 1, 'shanghai_metro_line_2,shanghai_metro_line_17', '从虹桥火车站进站后按10号线往基隆路方向乘车。'),
('shanghai_metro_line_10', 'hongqiao_terminal_2', '往基隆路方向', 2, 1, 'shanghai_metro_line_2', '机场乘客较多，携带行李用户注意预留时间。'),
('shanghai_metro_line_10', 'hongqiao_terminal_1', '往基隆路方向', 3, 0, NULL, NULL),
('shanghai_metro_line_10', 'shanghai_zoo', '往基隆路方向', 4, 0, NULL, NULL),
('shanghai_metro_line_10', 'longxi_road', '往基隆路方向', 5, 0, NULL, NULL),
('shanghai_metro_line_10', 'shuicheng_road', '往基隆路方向', 6, 0, NULL, NULL),
('shanghai_metro_line_10', 'yili_road', '往基隆路方向', 7, 0, NULL, NULL),
('shanghai_metro_line_10', 'songyuan_road', '往基隆路方向', 8, 0, NULL, NULL),
('shanghai_metro_line_10', 'hongqiao_road', '往基隆路方向', 9, 1, 'shanghai_metro_line_3,shanghai_metro_line_4', '需要换乘3号线、4号线的乘客可在本站下车。'),
('shanghai_metro_line_10', 'jiaotong_university', '往基隆路方向', 10, 1, 'shanghai_metro_line_11', '需要换乘11号线的乘客可在本站下车。'),
('shanghai_metro_line_10', 'shanghai_library', '往基隆路方向', 11, 0, NULL, NULL),
('shanghai_metro_line_10', 'south_shaanxi_road', '往基隆路方向', 12, 1, 'shanghai_metro_line_1,shanghai_metro_line_12', '需要换乘1号线、12号线的乘客可在本站下车。'),
('shanghai_metro_line_10', 'site_first_cpc_xintiandi', '往基隆路方向', 13, 1, 'shanghai_metro_line_13', '需要换乘13号线或前往新天地区域的乘客可在本站下车。'),
('shanghai_metro_line_10', 'laoximen', '往基隆路方向', 14, 1, 'shanghai_metro_line_8', '需要换乘8号线的乘客可在本站下车。'),
('shanghai_metro_line_10', 'yuyuan', '往基隆路方向', 15, 1, 'shanghai_metro_line_14', '需要换乘14号线或前往豫园区域的乘客可在本站下车。'),
('shanghai_metro_line_10', 'east_nanjing_road', '往基隆路方向', 16, 1, 'shanghai_metro_line_2', '需要换乘2号线或前往南京东路步行街的乘客可在本站下车。'),
('shanghai_metro_line_10', 'tiantong_road', '往基隆路方向', 17, 1, 'shanghai_metro_line_12', '需要换乘12号线的乘客可在本站下车。'),
('shanghai_metro_line_10', 'north_sichuan_road', '往基隆路方向', 18, 0, NULL, NULL),
('shanghai_metro_line_10', 'hailun_road', '往基隆路方向', 19, 1, 'shanghai_metro_line_4', '需要换乘4号线的乘客可在本站下车。'),
('shanghai_metro_line_10', 'youdian_xincun', '往基隆路方向', 20, 0, NULL, NULL),
('shanghai_metro_line_10', 'siping_road', '往基隆路方向', 21, 1, 'shanghai_metro_line_8', '需要换乘8号线的乘客可在本站下车。'),
('shanghai_metro_line_10', 'tongji_university', '往基隆路方向', 22, 0, NULL, '前往同济大学四平路校区可在本站下车。');

INSERT INTO transfer_rules (
  rule_id,
  origin_station_id,
  line_id,
  target_station_id,
  direction,
  stops_count,
  estimated_minutes,
  transfer_line_ids,
  carriage_suggestion,
  transfer_tip,
  tags,
  data_level
) VALUES
('rule_hongqiao_to_terminal2', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'hongqiao_terminal_2', '往基隆路方向', 1, 3, 'shanghai_metro_line_2', '中部车厢', '到达虹桥2号航站楼后可按站内指引换乘2号线或前往航站楼。', '机场,换乘2号线,行李用户', 'demo'),
('rule_hongqiao_to_hongqiao_road', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'hongqiao_road', '往基隆路方向', 8, 18, 'shanghai_metro_line_3,shanghai_metro_line_4', '中后部车厢', '到达虹桥路后可换乘3号线、4号线，换乘通道可能需要一定步行时间。', '换乘3号线,换乘4号线,市区', 'demo'),
('rule_hongqiao_to_jiaotong_university', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'jiaotong_university', '往基隆路方向', 9, 20, 'shanghai_metro_line_11', '中部车厢', '到达交通大学后可换乘11号线，适合前往徐家汇、迪士尼等方向。', '换乘11号线,高校,市中心', 'demo'),
('rule_hongqiao_to_south_shaanxi_road', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'south_shaanxi_road', '往基隆路方向', 11, 25, 'shanghai_metro_line_1,shanghai_metro_line_12', '前中部车厢', '到达陕西南路后可换乘1号线、12号线，站内客流较大。', '换乘1号线,换乘12号线,市中心', 'demo'),
('rule_hongqiao_to_xintiandi', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'site_first_cpc_xintiandi', '往基隆路方向', 12, 27, 'shanghai_metro_line_13', '中部车厢', '到达一大会址·新天地后可换乘13号线，也可前往新天地商圈。', '换乘13号线,新天地,市中心', 'demo'),
('rule_hongqiao_to_laoximen', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'laoximen', '往基隆路方向', 13, 29, 'shanghai_metro_line_8', '中部车厢', '到达老西门后可换乘8号线，注意按站内指示选择换乘方向。', '换乘8号线,老城厢', 'demo'),
('rule_hongqiao_to_yuyuan', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'yuyuan', '往基隆路方向', 14, 31, 'shanghai_metro_line_14', '中后部车厢', '到达豫园后可换乘14号线，也可前往豫园景区。', '换乘14号线,景点,市中心', 'demo'),
('rule_hongqiao_to_east_nanjing_road', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'east_nanjing_road', '往基隆路方向', 15, 34, 'shanghai_metro_line_2', '后部车厢', '到达南京东路后可换乘2号线，客流较大，建议预留换乘时间。', '换乘2号线,南京东路,市中心,拥挤', 'demo'),
('rule_hongqiao_to_tiantong_road', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'tiantong_road', '往基隆路方向', 16, 36, 'shanghai_metro_line_12', '中部车厢', '到达天潼路后可换乘12号线。', '换乘12号线,北外滩方向', 'demo'),
('rule_hongqiao_to_hailun_road', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'hailun_road', '往基隆路方向', 18, 40, 'shanghai_metro_line_4', '中部车厢', '到达海伦路后可换乘4号线。', '换乘4号线,虹口', 'demo'),
('rule_hongqiao_to_siping_road', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'siping_road', '往基隆路方向', 20, 43, 'shanghai_metro_line_8', '中后部车厢', '到达四平路后可换乘8号线。', '换乘8号线,杨浦,高校周边', 'demo'),
('rule_hongqiao_to_tongji_university', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'tongji_university', '往基隆路方向', 21, 45, NULL, '中部车厢', '到达同济大学站后，可根据出口指示前往同济大学四平路校区。', '同济大学,高校,10号线直达,少换乘', 'demo');

INSERT INTO station_exits (
  exit_id,
  station_id,
  exit_name,
  nearby_place,
  guide_tip,
  is_accessible
) VALUES
('exit_hongqiao_railway_arrival', 'shanghai_hongqiao_railway_station', '高铁到达层导向', '上海虹桥火车站到达层', '从高铁到达层按地铁10号线标识进站，携带行李用户建议预留进站时间。', 1),
('exit_hongqiao_railway_metro', 'shanghai_hongqiao_railway_station', '地铁换乘大厅', '虹桥综合交通枢纽', '地铁2号线、10号线、17号线换乘客流较大，注意看清线路方向。', 1),
('exit_east_nanjing_road_center', 'east_nanjing_road', '南京东路方向出口', '南京东路步行街', '前往市中心商圈或换乘2号线时注意客流。', 0),
('exit_siping_road_transfer', 'siping_road', '8号线换乘导向', '四平路站换乘通道', '换乘8号线请按站内指示前往对应站台。', 0),
('exit_tongji_university_campus', 'tongji_university', '同济大学方向出口', '同济大学四平路校区', '前往同济大学四平路校区可根据站内出口指示出站。', 0);
