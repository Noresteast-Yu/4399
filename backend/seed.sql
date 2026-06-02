-- Smart Travel MySQL 数据库种子数据
-- 用于初始化上海地铁10号线演示数据
USE smart_travel;

-- 清空现有数据（按依赖顺序）
DELETE FROM common_route_segments;
DELETE FROM common_routes;
DELETE FROM train_carriages;
DELETE FROM train_stations;
DELETE FROM trains;
DELETE FROM travel_alert_routes;
DELETE FROM travel_alerts;
DELETE FROM user_luggage;
DELETE FROM user_abilities;
DELETE FROM user_preferences;
DELETE FROM line_station_transfer_lines;
DELETE FROM transfer_rule_transfer_lines;
DELETE FROM transfer_rule_tags;
DELETE FROM line_stations;
DELETE FROM station_facilities;
DELETE FROM station_exits;
DELETE FROM transfer_rules;
DELETE FROM line_directions;
DELETE FROM metro_lines;
DELETE FROM stations;

-- 重置自增ID
ALTER TABLE common_route_segments AUTO_INCREMENT = 1;
ALTER TABLE common_routes AUTO_INCREMENT = 1;
ALTER TABLE train_carriages AUTO_INCREMENT = 1;
ALTER TABLE train_stations AUTO_INCREMENT = 1;
ALTER TABLE trains AUTO_INCREMENT = 1;
ALTER TABLE travel_alert_routes AUTO_INCREMENT = 1;
ALTER TABLE travel_alerts AUTO_INCREMENT = 1;
ALTER TABLE user_luggage AUTO_INCREMENT = 1;
ALTER TABLE user_abilities AUTO_INCREMENT = 1;
ALTER TABLE user_preferences AUTO_INCREMENT = 1;
ALTER TABLE line_station_transfer_lines AUTO_INCREMENT = 1;
ALTER TABLE transfer_rule_transfer_lines AUTO_INCREMENT = 1;
ALTER TABLE transfer_rule_tags AUTO_INCREMENT = 1;
ALTER TABLE line_stations AUTO_INCREMENT = 1;
ALTER TABLE station_facilities AUTO_INCREMENT = 1;
ALTER TABLE station_exits AUTO_INCREMENT = 1;
ALTER TABLE transfer_rules AUTO_INCREMENT = 1;
ALTER TABLE line_directions AUTO_INCREMENT = 1;
ALTER TABLE metro_lines AUTO_INCREMENT = 1;
ALTER TABLE stations AUTO_INCREMENT = 1;

-- 插入地铁线路
INSERT INTO metro_lines (line_id, line_name, city, color_name, color_hex, description) VALUES
('shanghai_metro_line_1', '上海地铁1号线', '上海', '红色', '#E4002B', '换乘参考线路。'),
('shanghai_metro_line_2', '上海地铁2号线', '上海', '绿色', '#8CC63F', '换乘参考线路，连接虹桥枢纽和南京东路等站。'),
('shanghai_metro_line_3', '上海地铁3号线', '上海', '黄色', '#FFD100', '换乘参考线路。'),
('shanghai_metro_line_4', '上海地铁4号线', '上海', '紫色', '#5F259F', '换乘参考线路。'),
('shanghai_metro_line_8', '上海地铁8号线', '上海', '蓝色', '#009BDE', '换乘参考线路。'),
('shanghai_metro_line_10', '上海地铁10号线', '上海', '淡紫色', '#C5A3FF', '本项目基础演示线路，默认整理虹桥火车站至同济大学区间。'),
('shanghai_metro_line_11', '上海地铁11号线', '上海', '棕色', '#7A3E2F', '换乘参考线路。'),
('shanghai_metro_line_12', '上海地铁12号线', '上海', '深绿色', '#007A3D', '换乘参考线路。'),
('shanghai_metro_line_13', '上海地铁13号线', '上海', '粉色', '#F4A6C8', '换乘参考线路。'),
('shanghai_metro_line_14', '上海地铁14号线', '上海', '橄榄色', '#B2A72C', '换乘参考线路。'),
('shanghai_metro_line_17', '上海地铁17号线', '上海', '棕黄色', '#B08A00', '虹桥枢纽换乘参考线路。'),
('shanghai_metro_line_18', '上海地铁18号线', '上海', '土黄色', '#C8A45D', '同济大学附近可衔接的参考线路，用于候选路线演示。');

-- 插入线路方向
INSERT INTO line_directions (line_id, direction) VALUES
('shanghai_metro_line_1', '往富锦路方向'),
('shanghai_metro_line_1', '往莘庄方向'),
('shanghai_metro_line_2', '往浦东1号2号航站楼方向'),
('shanghai_metro_line_2', '往徐泾东方向'),
('shanghai_metro_line_3', '往江杨北路方向'),
('shanghai_metro_line_3', '往上海南站方向'),
('shanghai_metro_line_4', '内圈'),
('shanghai_metro_line_4', '外圈'),
('shanghai_metro_line_8', '往市光路方向'),
('shanghai_metro_line_8', '往沈杜公路方向'),
('shanghai_metro_line_10', '往基隆路方向'),
('shanghai_metro_line_10', '往虹桥火车站方向'),
('shanghai_metro_line_11', '往迪士尼方向'),
('shanghai_metro_line_11', '往嘉定北/花桥方向'),
('shanghai_metro_line_12', '往金海路方向'),
('shanghai_metro_line_12', '往七莘路方向'),
('shanghai_metro_line_13', '往张江路方向'),
('shanghai_metro_line_13', '往金运路方向'),
('shanghai_metro_line_14', '往桂桥路方向'),
('shanghai_metro_line_14', '往封浜方向'),
('shanghai_metro_line_17', '往东方绿舟方向'),
('shanghai_metro_line_17', '往虹桥火车站方向'),
('shanghai_metro_line_18', '往长江南路方向'),
('shanghai_metro_line_18', '往航头方向');

-- 插入站点
INSERT INTO stations (station_id, station_name, station_alias, city, district, station_type, description) VALUES
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

-- 插入线路站点顺序（10号线往基隆路方向）
INSERT INTO line_stations (line_id, station_id, direction, station_order, is_transfer, platform_tip) VALUES
('shanghai_metro_line_10', 'shanghai_hongqiao_railway_station', '往基隆路方向', 1, 1, '从虹桥火车站进站后按10号线往基隆路方向乘车。'),
('shanghai_metro_line_10', 'hongqiao_terminal_2', '往基隆路方向', 2, 1, '机场乘客较多，携带行李用户注意预留时间。'),
('shanghai_metro_line_10', 'hongqiao_terminal_1', '往基隆路方向', 3, 0, NULL),
('shanghai_metro_line_10', 'shanghai_zoo', '往基隆路方向', 4, 0, NULL),
('shanghai_metro_line_10', 'longxi_road', '往基隆路方向', 5, 0, NULL),
('shanghai_metro_line_10', 'shuicheng_road', '往基隆路方向', 6, 0, NULL),
('shanghai_metro_line_10', 'yili_road', '往基隆路方向', 7, 0, NULL),
('shanghai_metro_line_10', 'songyuan_road', '往基隆路方向', 8, 0, NULL),
('shanghai_metro_line_10', 'hongqiao_road', '往基隆路方向', 9, 1, '需要换乘3号线、4号线的乘客可在本站下车。'),
('shanghai_metro_line_10', 'jiaotong_university', '往基隆路方向', 10, 1, '需要换乘11号线的乘客可在本站下车。'),
('shanghai_metro_line_10', 'shanghai_library', '往基隆路方向', 11, 0, NULL),
('shanghai_metro_line_10', 'south_shaanxi_road', '往基隆路方向', 12, 1, '需要换乘1号线、12号线的乘客可在本站下车。'),
('shanghai_metro_line_10', 'site_first_cpc_xintiandi', '往基隆路方向', 13, 1, '需要换乘13号线或前往新天地区域的乘客可在本站下车。'),
('shanghai_metro_line_10', 'laoximen', '往基隆路方向', 14, 1, '需要换乘8号线的乘客可在本站下车。'),
('shanghai_metro_line_10', 'yuyuan', '往基隆路方向', 15, 1, '需要换乘14号线或前往豫园区域的乘客可在本站下车。'),
('shanghai_metro_line_10', 'east_nanjing_road', '往基隆路方向', 16, 1, '需要换乘2号线或前往南京东路步行街的乘客可在本站下车。'),
('shanghai_metro_line_10', 'tiantong_road', '往基隆路方向', 17, 1, '需要换乘12号线的乘客可在本站下车。'),
('shanghai_metro_line_10', 'north_sichuan_road', '往基隆路方向', 18, 0, NULL),
('shanghai_metro_line_10', 'hailun_road', '往基隆路方向', 19, 1, '需要换乘4号线的乘客可在本站下车。'),
('shanghai_metro_line_10', 'youdian_xincun', '往基隆路方向', 20, 0, NULL),
('shanghai_metro_line_10', 'siping_road', '往基隆路方向', 21, 1, '需要换乘8号线的乘客可在本站下车。'),
('shanghai_metro_line_10', 'tongji_university', '往基隆路方向', 22, 0, '前往同济大学四平路校区可在本站下车。');

-- 插入线路站点换乘线路关联
INSERT INTO line_station_transfer_lines (line_station_id, transfer_line_id)
SELECT ls.id, transfer_line_id
FROM line_stations ls
CROSS JOIN (SELECT 'shanghai_metro_line_2' AS transfer_line_id UNION ALL
            SELECT 'shanghai_metro_line_17' UNION ALL
            SELECT 'shanghai_metro_line_3' UNION ALL
            SELECT 'shanghai_metro_line_4' UNION ALL
            SELECT 'shanghai_metro_line_11' UNION ALL
            SELECT 'shanghai_metro_line_1' UNION ALL
            SELECT 'shanghai_metro_line_12' UNION ALL
            SELECT 'shanghai_metro_line_13' UNION ALL
            SELECT 'shanghai_metro_line_8' UNION ALL
            SELECT 'shanghai_metro_line_14') AS t
WHERE (ls.station_id = 'shanghai_hongqiao_railway_station' AND t.transfer_line_id IN ('shanghai_metro_line_2', 'shanghai_metro_line_17'))
   OR (ls.station_id = 'hongqiao_terminal_2' AND t.transfer_line_id IN ('shanghai_metro_line_2'))
   OR (ls.station_id = 'hongqiao_road' AND t.transfer_line_id IN ('shanghai_metro_line_3', 'shanghai_metro_line_4'))
   OR (ls.station_id = 'jiaotong_university' AND t.transfer_line_id IN ('shanghai_metro_line_11'))
   OR (ls.station_id = 'south_shaanxi_road' AND t.transfer_line_id IN ('shanghai_metro_line_1', 'shanghai_metro_line_12'))
   OR (ls.station_id = 'site_first_cpc_xintiandi' AND t.transfer_line_id IN ('shanghai_metro_line_13'))
   OR (ls.station_id = 'laoximen' AND t.transfer_line_id IN ('shanghai_metro_line_8'))
   OR (ls.station_id = 'yuyuan' AND t.transfer_line_id IN ('shanghai_metro_line_14'))
   OR (ls.station_id = 'east_nanjing_road' AND t.transfer_line_id IN ('shanghai_metro_line_2'))
   OR (ls.station_id = 'tiantong_road' AND t.transfer_line_id IN ('shanghai_metro_line_12'))
   OR (ls.station_id = 'hailun_road' AND t.transfer_line_id IN ('shanghai_metro_line_4'))
   OR (ls.station_id = 'siping_road' AND t.transfer_line_id IN ('shanghai_metro_line_8'));

-- 插入换乘规则
INSERT INTO transfer_rules (rule_id, origin_station_id, line_id, target_station_id, direction, stops_count, estimated_minutes, carriage_suggestion, transfer_tip, data_level) VALUES
('rule_hongqiao_to_terminal2', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'hongqiao_terminal_2', '往基隆路方向', 1, 3, '中部车厢', '到达虹桥2号航站楼后可按站内指引换乘2号线或前往航站楼。', 'demo'),
('rule_hongqiao_to_hongqiao_road', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'hongqiao_road', '往基隆路方向', 8, 18, '中后部车厢', '到达虹桥路后可换乘3号线、4号线，换乘通道可能需要一定步行时间。', 'demo'),
('rule_hongqiao_to_jiaotong_university', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'jiaotong_university', '往基隆路方向', 9, 20, '中部车厢', '到达交通大学后可换乘11号线，适合前往徐家汇、迪士尼等方向。', 'demo'),
('rule_hongqiao_to_south_shaanxi_road', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'south_shaanxi_road', '往基隆路方向', 11, 25, '前中部车厢', '到达陕西南路后可换乘1号线、12号线，站内客流较大。', 'demo'),
('rule_hongqiao_to_xintiandi', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'site_first_cpc_xintiandi', '往基隆路方向', 12, 27, '中部车厢', '到达一大会址·新天地后可换乘13号线，也可前往新天地商圈。', 'demo'),
('rule_hongqiao_to_laoximen', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'laoximen', '往基隆路方向', 13, 29, '中部车厢', '到达老西门后可换乘8号线，注意按站内指示选择换乘方向。', 'demo'),
('rule_hongqiao_to_yuyuan', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'yuyuan', '往基隆路方向', 14, 31, '中后部车厢', '到达豫园后可换乘14号线，也可前往豫园景区。', 'demo'),
('rule_hongqiao_to_east_nanjing_road', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'east_nanjing_road', '往基隆路方向', 15, 34, '后部车厢', '到达南京东路后可换乘2号线，客流较大，建议预留换乘时间。', 'demo'),
('rule_hongqiao_to_tiantong_road', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'tiantong_road', '往基隆路方向', 16, 36, '中部车厢', '到达天潼路后可换乘12号线。', 'demo'),
('rule_hongqiao_to_hailun_road', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'hailun_road', '往基隆路方向', 18, 40, '中部车厢', '到达海伦路后可换乘4号线。', 'demo'),
('rule_hongqiao_to_siping_road', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'siping_road', '往基隆路方向', 20, 43, '中后部车厢', '到达四平路后可换乘8号线。', 'demo'),
('rule_hongqiao_to_tongji_university', 'shanghai_hongqiao_railway_station', 'shanghai_metro_line_10', 'tongji_university', '往基隆路方向', 21, 45, '中部车厢', '到达同济大学站后，可根据出口指示前往同济大学四平路校区。', 'demo');

-- 插入换乘规则标签
INSERT INTO transfer_rule_tags (transfer_rule_id, tag)
SELECT tr.id, t.tag
FROM transfer_rules tr
CROSS JOIN (
    SELECT 'rule_hongqiao_to_terminal2' AS rule_id, '机场' AS tag UNION ALL
    SELECT 'rule_hongqiao_to_terminal2', '换乘2号线' UNION ALL
    SELECT 'rule_hongqiao_to_terminal2', '行李用户' UNION ALL
    SELECT 'rule_hongqiao_to_hongqiao_road', '换乘3号线' UNION ALL
    SELECT 'rule_hongqiao_to_hongqiao_road', '换乘4号线' UNION ALL
    SELECT 'rule_hongqiao_to_hongqiao_road', '市区' UNION ALL
    SELECT 'rule_hongqiao_to_jiaotong_university', '换乘11号线' UNION ALL
    SELECT 'rule_hongqiao_to_jiaotong_university', '高校' UNION ALL
    SELECT 'rule_hongqiao_to_jiaotong_university', '市中心' UNION ALL
    SELECT 'rule_hongqiao_to_south_shaanxi_road', '换乘1号线' UNION ALL
    SELECT 'rule_hongqiao_to_south_shaanxi_road', '换乘12号线' UNION ALL
    SELECT 'rule_hongqiao_to_south_shaanxi_road', '市中心' UNION ALL
    SELECT 'rule_hongqiao_to_xintiandi', '换乘13号线' UNION ALL
    SELECT 'rule_hongqiao_to_xintiandi', '新天地' UNION ALL
    SELECT 'rule_hongqiao_to_xintiandi', '市中心' UNION ALL
    SELECT 'rule_hongqiao_to_laoximen', '换乘8号线' UNION ALL
    SELECT 'rule_hongqiao_to_laoximen', '老城厢' UNION ALL
    SELECT 'rule_hongqiao_to_yuyuan', '换乘14号线' UNION ALL
    SELECT 'rule_hongqiao_to_yuyuan', '景点' UNION ALL
    SELECT 'rule_hongqiao_to_yuyuan', '市中心' UNION ALL
    SELECT 'rule_hongqiao_to_east_nanjing_road', '换乘2号线' UNION ALL
    SELECT 'rule_hongqiao_to_east_nanjing_road', '南京东路' UNION ALL
    SELECT 'rule_hongqiao_to_east_nanjing_road', '市中心' UNION ALL
    SELECT 'rule_hongqiao_to_east_nanjing_road', '拥挤' UNION ALL
    SELECT 'rule_hongqiao_to_tiantong_road', '换乘12号线' UNION ALL
    SELECT 'rule_hongqiao_to_tiantong_road', '北外滩方向' UNION ALL
    SELECT 'rule_hongqiao_to_hailun_road', '换乘4号线' UNION ALL
    SELECT 'rule_hongqiao_to_hailun_road', '虹口' UNION ALL
    SELECT 'rule_hongqiao_to_siping_road', '换乘8号线' UNION ALL
    SELECT 'rule_hongqiao_to_siping_road', '杨浦' UNION ALL
    SELECT 'rule_hongqiao_to_siping_road', '高校周边' UNION ALL
    SELECT 'rule_hongqiao_to_tongji_university', '同济大学' UNION ALL
    SELECT 'rule_hongqiao_to_tongji_university', '高校' UNION ALL
    SELECT 'rule_hongqiao_to_tongji_university', '10号线直达' UNION ALL
    SELECT 'rule_hongqiao_to_tongji_university', '少换乘'
) AS t ON tr.rule_id = t.rule_id;

-- 插入换乘规则可换乘线路
INSERT INTO transfer_rule_transfer_lines (transfer_rule_id, transfer_line_id)
SELECT tr.id, t.transfer_line_id
FROM transfer_rules tr
CROSS JOIN (
    SELECT 'rule_hongqiao_to_terminal2' AS rule_id, 'shanghai_metro_line_2' AS transfer_line_id UNION ALL
    SELECT 'rule_hongqiao_to_hongqiao_road', 'shanghai_metro_line_3' UNION ALL
    SELECT 'rule_hongqiao_to_hongqiao_road', 'shanghai_metro_line_4' UNION ALL
    SELECT 'rule_hongqiao_to_jiaotong_university', 'shanghai_metro_line_11' UNION ALL
    SELECT 'rule_hongqiao_to_south_shaanxi_road', 'shanghai_metro_line_1' UNION ALL
    SELECT 'rule_hongqiao_to_south_shaanxi_road', 'shanghai_metro_line_12' UNION ALL
    SELECT 'rule_hongqiao_to_xintiandi', 'shanghai_metro_line_13' UNION ALL
    SELECT 'rule_hongqiao_to_laoximen', 'shanghai_metro_line_8' UNION ALL
    SELECT 'rule_hongqiao_to_yuyuan', 'shanghai_metro_line_14' UNION ALL
    SELECT 'rule_hongqiao_to_east_nanjing_road', 'shanghai_metro_line_2' UNION ALL
    SELECT 'rule_hongqiao_to_tiantong_road', 'shanghai_metro_line_12' UNION ALL
    SELECT 'rule_hongqiao_to_hailun_road', 'shanghai_metro_line_4' UNION ALL
    SELECT 'rule_hongqiao_to_siping_road', 'shanghai_metro_line_8'
) AS t ON tr.rule_id = t.rule_id;

-- 插入站点出口
INSERT INTO station_exits (exit_id, station_id, exit_name, nearby_place, guide_tip, is_accessible) VALUES
('exit_hongqiao_railway_arrival', 'shanghai_hongqiao_railway_station', '高铁到达层导向', '上海虹桥火车站到达层', '从高铁到达层按地铁10号线标识进站，携带行李用户建议预留进站时间。', 1),
('exit_hongqiao_railway_metro', 'shanghai_hongqiao_railway_station', '地铁换乘大厅', '虹桥综合交通枢纽', '地铁2号线、10号线、17号线换乘客流较大，注意看清线路方向。', 1),
('exit_east_nanjing_road_center', 'east_nanjing_road', '南京东路方向出口', '南京东路步行街', '前往市中心商圈或换乘2号线时注意客流。', 0),
('exit_siping_road_transfer', 'siping_road', '8号线换乘导向', '四平路站换乘通道', '换乘8号线请按站内指示前往对应站台。', 0),
('exit_tongji_university_campus', 'tongji_university', '同济大学方向出口', '同济大学四平路校区', '前往同济大学四平路校区可根据站内出口指示出站。', 0);

-- 插入站点设施
INSERT INTO station_facilities (
    station_id, has_elevator, has_escalator, has_wheelchair_ramp, has_wide_gate,
    has_accessible_restroom, has_blind_path, elevator_count, elevator_location, escalator_count,
    restroom_location, has_restroom_in_paid, has_restroom_outside, has_mother_baby_room,
    has_third_bathroom, has_aed, has_service_center, facility_note
) VALUES
('shanghai_hongqiao_railway_station', 1, 1, 1, 1, 1, 1, 6, '到达层、换乘大厅、站台层均有无障碍电梯', 18, '站厅层服务中心旁', 1, 1, 1, 1, 1, 1, '综合交通枢纽站，电梯、无障碍通道和服务台较完善，建议携带行李用户预留进站时间。'),
('hongqiao_terminal_2', 1, 1, 1, 1, 1, 1, 4, '航站楼连廊和站厅两侧', 12, '站厅层近航站楼通道', 1, 1, 1, 1, 1, 1, '航站楼换乘站，机场客流较大，注意按站内导向前往对应航站楼。'),
('hongqiao_terminal_1', 1, 1, 1, 1, 0, 1, 2, '站厅至站台各1部', 8, '站厅层费区外', 0, 1, 0, 0, 1, 1, '机场相关站点，基础无障碍设施可用。'),
('shanghai_zoo', 1, 1, 1, 1, 0, 1, 2, '2号口附近和站台中部', 6, '站厅层费区外', 0, 1, 1, 0, 1, 1, '周末亲子客流较多，建议错峰出行。'),
('longxi_road', 1, 1, 1, 1, 0, 1, 2, '站厅至站台各1部', 6, '站厅层费区外', 0, 1, 0, 0, 1, 1, '普通地铁站，基础无障碍设施可用。'),
('shuicheng_road', 1, 1, 1, 1, 0, 1, 2, '站厅至站台各1部', 6, '站厅层费区外', 0, 1, 0, 0, 1, 1, '普通地铁站，基础无障碍设施可用。'),
('yili_road', 1, 1, 1, 1, 0, 1, 2, '站厅至站台各1部', 6, '站厅层费区外', 0, 1, 0, 0, 1, 1, '普通地铁站，基础无障碍设施可用。'),
('songyuan_road', 1, 1, 1, 1, 0, 1, 2, '站厅至站台各1部', 6, '站厅层费区外', 0, 1, 0, 0, 1, 1, '普通地铁站，基础无障碍设施可用。'),
('hongqiao_road', 1, 1, 1, 1, 1, 1, 3, '10号线站台中部及换乘通道附近', 10, '换乘大厅内', 1, 0, 0, 1, 1, 1, '3/4/10号线换乘站，换乘步行距离较长。'),
('jiaotong_university', 1, 1, 1, 1, 1, 1, 3, '10号线站台中部、11号线换乘侧', 10, '站厅层近服务中心', 1, 0, 0, 1, 1, 1, '10/11号线换乘站，靠近高校和商业区。'),
('shanghai_library', 1, 1, 1, 1, 0, 1, 2, '站台中部和出入口侧', 6, '站厅层费区外', 0, 1, 0, 0, 1, 1, '靠近上海图书馆，出入口周边步行环境较好。'),
('south_shaanxi_road', 1, 1, 1, 1, 1, 1, 4, '换乘大厅和各线路站台中部', 14, '换乘大厅内', 1, 0, 1, 1, 1, 1, '1/10/12号线换乘站，晚高峰客流较大。'),
('site_first_cpc_xintiandi', 1, 1, 1, 1, 1, 1, 3, '站厅东侧及站台中部', 10, '站厅层近新天地出口', 1, 0, 1, 1, 1, 1, '10/13号线换乘站，靠近新天地商圈。'),
('laoximen', 1, 1, 1, 1, 1, 1, 3, '8号线换乘通道附近', 9, '换乘大厅内', 1, 0, 0, 1, 1, 1, '8/10号线换乘站，站内导向较密集。'),
('yuyuan', 1, 1, 1, 1, 1, 1, 3, '14号线换乘侧和站台中部', 9, '站厅层近景区出口', 1, 0, 1, 1, 1, 1, '10/14号线换乘站，节假日景区客流明显增加。'),
('east_nanjing_road', 1, 1, 1, 1, 1, 1, 4, '2号线换乘大厅和10号线站台中部', 16, '换乘大厅内', 1, 0, 1, 1, 1, 1, '2/10号线换乘站，南京东路商圈客流大。'),
('tiantong_road', 1, 1, 1, 1, 0, 1, 2, '12号线换乘通道附近', 8, '站厅层费区外', 0, 1, 0, 0, 1, 1, '10/12号线换乘站，换乘通道请留意方向。'),
('north_sichuan_road', 1, 1, 1, 1, 0, 1, 2, '站厅至站台各1部', 6, '站厅层费区外', 0, 1, 0, 0, 1, 1, '普通地铁站，基础无障碍设施可用。'),
('hailun_road', 1, 1, 1, 1, 1, 1, 3, '4号线换乘侧和10号线站台中部', 9, '换乘大厅内', 1, 0, 0, 1, 1, 1, '4/10号线换乘站，换乘时注意内外圈方向。'),
('youdian_xincun', 1, 1, 1, 1, 0, 1, 2, '站厅至站台各1部', 6, '站厅层费区外', 0, 1, 0, 0, 1, 1, '普通地铁站，基础无障碍设施可用。'),
('siping_road', 1, 1, 1, 1, 1, 1, 3, '8号线换乘通道附近', 9, '站厅层近换乘通道', 1, 0, 0, 1, 1, 1, '8/10号线换乘站，靠近同济大学生活区。'),
('tongji_university', 1, 1, 1, 1, 1, 1, 2, '站厅至站台各1部，近校园方向出口', 8, '站厅层近校园方向出口', 1, 0, 1, 1, 1, 1, '靠近同济大学四平路校区，早晚高峰学生客流较多。');

-- 插入出行提醒
INSERT INTO travel_alerts (type, title, message) VALUES
('delay', '10号线局部列车间隔延长', '受早高峰客流影响，虹桥火车站至南京东路方向部分列车间隔略有延长，请预留5-8分钟。'),
('control', '南京东路站节假日客流管控', '节假日南京东路站可能采取临时限流，请按现场工作人员引导进出站。'),
('other', '同济大学站周边施工提醒', '同济大学站部分出口周边有道路施工，步行前往校园请留意现场导向。');

INSERT INTO travel_alert_routes (alert_id, route)
SELECT id, route
FROM travel_alerts
JOIN (
    SELECT '10号线局部列车间隔延长' AS title, '上海地铁10号线' AS route UNION ALL
    SELECT '南京东路站节假日客流管控', '上海地铁2号线' UNION ALL
    SELECT '南京东路站节假日客流管控', '上海地铁10号线' UNION ALL
    SELECT '同济大学站周边施工提醒', '上海地铁10号线'
) AS t USING (title);

-- 插入高铁演示数据
INSERT INTO trains (number, start, end, departure, arrival, platform, door_direction) VALUES
('G7001', '上海虹桥', '南京南', '08:00', '09:05', '12', '左侧开门'),
('G7315', '上海虹桥', '杭州东', '09:20', '10:18', '18', '右侧开门');

INSERT INTO train_stations (train_id, station_name, station_order)
SELECT t.id, s.station_name, s.station_order
FROM trains t
JOIN (
    SELECT 'G7001' AS number, '上海虹桥' AS station_name, 1 AS station_order UNION ALL
    SELECT 'G7001', '苏州北', 2 UNION ALL
    SELECT 'G7001', '无锡东', 3 UNION ALL
    SELECT 'G7001', '南京南', 4 UNION ALL
    SELECT 'G7315', '上海虹桥', 1 UNION ALL
    SELECT 'G7315', '嘉兴南', 2 UNION ALL
    SELECT 'G7315', '杭州东', 3
) AS s ON t.number = s.number;

INSERT INTO train_carriages (train_id, carriage_number, carriage_type, distance)
SELECT t.id, c.carriage_number, c.carriage_type, c.distance
FROM trains t
JOIN (
    SELECT 'G7001' AS number, '01' AS carriage_number, '商务/一等座' AS carriage_type, '距检票口约80米' AS distance UNION ALL
    SELECT 'G7001', '08', '二等座', '距检票口约180米' UNION ALL
    SELECT 'G7315', '02', '一等座', '距检票口约100米' UNION ALL
    SELECT 'G7315', '06', '二等座', '距检票口约160米'
) AS c ON t.number = c.number;

-- 插入常用路线和用户偏好演示数据
INSERT INTO common_routes (user_id, start, end, time, distance) VALUES
('demo_user', '上海虹桥火车站', '同济大学', '45分钟', '约22站'),
('demo_user', '上海虹桥火车站', '南京东路', '34分钟', '约15站');

INSERT INTO common_route_segments (route_id, segment_type, distance, time)
SELECT cr.id, s.segment_type, s.distance, s.time
FROM common_routes cr
JOIN (
    SELECT '上海虹桥火车站' AS start, '同济大学' AS end, 'ride' AS segment_type, '10号线直达21站' AS distance, '45分钟' AS time UNION ALL
    SELECT '上海虹桥火车站', '南京东路', 'ride', '10号线直达15站', '34分钟'
) AS s ON cr.start = s.start AND cr.end = s.end;

INSERT INTO user_preferences (user_id, theme_color, theme_mode, font_size) VALUES
('demo_user', 'system', 'system', 'medium');

INSERT INTO user_abilities (user_id, ability_type, ability_level, description) VALUES
('demo_user', 'mobility', 1, '轻度行动不便，优先推荐少步行、少换乘路线'),
('demo_user', 'accessibility', 1, '优先选择电梯和无障碍卫生间信息更完整的站点');

INSERT INTO user_luggage (user_id, luggage_type, weight, size) VALUES
('demo_user', 'suitcase', '12kg', '24寸');
