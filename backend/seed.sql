-- Smart Travel MySQL 数据库种子数据
-- 用于初始化上海地铁10号线演示数据
USE smart_travel;

-- 清空现有数据（按依赖顺序）
DELETE FROM line_station_transfer_lines;
DELETE FROM transfer_rule_transfer_lines;
DELETE FROM transfer_rule_tags;
DELETE FROM line_stations;
DELETE FROM station_exits;
DELETE FROM transfer_rules;
DELETE FROM line_directions;
DELETE FROM metro_lines;
DELETE FROM stations;

-- 重置自增ID
ALTER TABLE line_station_transfer_lines AUTO_INCREMENT = 1;
ALTER TABLE transfer_rule_transfer_lines AUTO_INCREMENT = 1;
ALTER TABLE transfer_rule_tags AUTO_INCREMENT = 1;
ALTER TABLE line_stations AUTO_INCREMENT = 1;
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
('tongji_university', '同济大学', NULL, '上海', '杨浦区', '地铁站', '10号线沿线站点，靠近同济大学四平路校区。'),
('fujin_road', '富锦路', NULL, '上海', '宝山区', '地铁站', '1号线北端站点。'),
('west_youyi_road', '友谊西路', NULL, '上海', '宝山区', '地铁站', '1号线沿线站点。'),
('baoan_highway', '宝安公路', NULL, '上海', '宝山区', '地铁站', '1号线沿线站点。'),
('gongfu_xincun', '共富新村', NULL, '上海', '宝山区', '地铁站', '1号线沿线站点。'),
('hulan_road', '呼兰路', NULL, '上海', '宝山区', '地铁站', '1号线沿线站点。'),
('tonghe_xincun', '通河新村', NULL, '上海', '宝山区', '地铁站', '1号线沿线站点。'),
('gongkang_road', '共康路', NULL, '上海', '宝山区', '地铁站', '1号线沿线站点。'),
('pengpu_xincun', '彭浦新村', NULL, '上海', '静安区', '地铁站', '1号线沿线站点。'),
('wenshui_road', '汶水路', NULL, '上海', '静安区', '地铁站', '1号线沿线站点。'),
('shanghai_circus_world', '上海马戏城', NULL, '上海', '静安区', '地铁站', '1号线沿线站点。'),
('yanchang_road', '延长路', NULL, '上海', '静安区', '地铁站', '1号线沿线站点。'),
('north_zhongshan_road', '中山北路', NULL, '上海', '静安区', '地铁站', '1号线沿线站点。'),
('shanghai_railway_station', '上海火车站', NULL, '上海', '静安区', '地铁站/火车站', '1号线沿线交通枢纽。'),
('hanzhong_road', '汉中路', NULL, '上海', '静安区', '地铁站', '1号线沿线站点。'),
('xinzha_road', '新闸路', NULL, '上海', '黄浦区', '地铁站', '1号线沿线站点。'),
('people_square', '人民广场', NULL, '上海', '黄浦区', '地铁站/换乘站', '1号线市中心换乘站。'),
('south_huangpi_road', '黄陂南路', NULL, '上海', '黄浦区', '地铁站', '1号线沿线站点。'),
('changshu_road', '常熟路', NULL, '上海', '徐汇区', '地铁站', '1号线沿线站点。'),
('hengshan_road', '衡山路', NULL, '上海', '徐汇区', '地铁站', '1号线沿线站点。'),
('xujiahui', '徐家汇', NULL, '上海', '徐汇区', '地铁站/换乘站', '1号线商业中心站点。'),
('shanghai_indoor_stadium', '上海体育馆', NULL, '上海', '徐汇区', '地铁站', '1号线沿线站点。'),
('caobao_road', '漕宝路', NULL, '上海', '徐汇区', '地铁站', '1号线沿线站点。'),
('shanghai_south_railway_station', '上海南站', NULL, '上海', '徐汇区', '地铁站/火车站', '1号线南部交通枢纽。'),
('jinjiang_park', '锦江乐园', NULL, '上海', '闵行区', '地铁站', '1号线沿线站点。'),
('lianhua_road', '莲花路', NULL, '上海', '闵行区', '地铁站', '1号线沿线站点。'),
('waihuanlu', '外环路', NULL, '上海', '闵行区', '地铁站', '1号线沿线站点。'),
('xinzhuang', '莘庄', NULL, '上海', '闵行区', '地铁站', '1号线南端换乘站。');

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

-- 插入线路站点顺序（1号线富锦路至莘庄方向）
INSERT INTO line_stations (line_id, station_id, direction, station_order, is_transfer, platform_tip) VALUES
('shanghai_metro_line_1', 'fujin_road', '往莘庄方向', 1, 0, NULL),
('shanghai_metro_line_1', 'west_youyi_road', '往莘庄方向', 2, 0, NULL),
('shanghai_metro_line_1', 'baoan_highway', '往莘庄方向', 3, 0, NULL),
('shanghai_metro_line_1', 'gongfu_xincun', '往莘庄方向', 4, 0, NULL),
('shanghai_metro_line_1', 'hulan_road', '往莘庄方向', 5, 0, NULL),
('shanghai_metro_line_1', 'tonghe_xincun', '往莘庄方向', 6, 0, NULL),
('shanghai_metro_line_1', 'gongkang_road', '往莘庄方向', 7, 0, NULL),
('shanghai_metro_line_1', 'pengpu_xincun', '往莘庄方向', 8, 0, NULL),
('shanghai_metro_line_1', 'wenshui_road', '往莘庄方向', 9, 0, NULL),
('shanghai_metro_line_1', 'shanghai_circus_world', '往莘庄方向', 10, 0, NULL),
('shanghai_metro_line_1', 'yanchang_road', '往莘庄方向', 11, 0, NULL),
('shanghai_metro_line_1', 'north_zhongshan_road', '往莘庄方向', 12, 0, NULL),
('shanghai_metro_line_1', 'shanghai_railway_station', '往莘庄方向', 13, 1, '可前往铁路上海站，注意站内客流。'),
('shanghai_metro_line_1', 'hanzhong_road', '往莘庄方向', 14, 0, NULL),
('shanghai_metro_line_1', 'xinzha_road', '往莘庄方向', 15, 0, NULL),
('shanghai_metro_line_1', 'people_square', '往莘庄方向', 16, 1, '市中心大客流站点，注意换乘导向。'),
('shanghai_metro_line_1', 'south_huangpi_road', '往莘庄方向', 17, 0, NULL),
('shanghai_metro_line_1', 'south_shaanxi_road', '往莘庄方向', 18, 1, '可换乘10号线、12号线。'),
('shanghai_metro_line_1', 'changshu_road', '往莘庄方向', 19, 0, NULL),
('shanghai_metro_line_1', 'hengshan_road', '往莘庄方向', 20, 0, NULL),
('shanghai_metro_line_1', 'xujiahui', '往莘庄方向', 21, 1, '徐家汇商圈站点，注意站内换乘导向。'),
('shanghai_metro_line_1', 'shanghai_indoor_stadium', '往莘庄方向', 22, 0, NULL),
('shanghai_metro_line_1', 'caobao_road', '往莘庄方向', 23, 0, NULL),
('shanghai_metro_line_1', 'shanghai_south_railway_station', '往莘庄方向', 24, 1, '可前往上海南站铁路枢纽。'),
('shanghai_metro_line_1', 'jinjiang_park', '往莘庄方向', 25, 0, NULL),
('shanghai_metro_line_1', 'lianhua_road', '往莘庄方向', 26, 0, NULL),
('shanghai_metro_line_1', 'waihuanlu', '往莘庄方向', 27, 0, NULL),
('shanghai_metro_line_1', 'xinzhuang', '往莘庄方向', 28, 1, '可换乘5号线。');

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

-- 插入静态资源
INSERT INTO static_resources (resource_type, resource_name, resource_path, description) VALUES
('icon', 'timer', 'app/assets/icons/timer.png', '换乘倒计时图标'),
('icon', 'transfer', 'app/assets/icons/transfer.png', '站内换乘图标'),
('diagram', 'hongqiao-transfer', 'backend/go/data/station_topologies/hongqiao_railway_station.json', '虹桥火车站平面换乘拓扑数据'),
('diagram', 'tongji-university', 'backend/go/data/station_topologies/tongji_university.json', '同济大学站平面换乘拓扑数据');

-- 插入站点出口
INSERT INTO station_exits (exit_id, station_id, exit_name, nearby_place, guide_tip, is_accessible) VALUES
('exit_hongqiao_railway_arrival', 'shanghai_hongqiao_railway_station', '高铁到达层导向', '上海虹桥火车站到达层', '从高铁到达层按地铁10号线标识进站，携带行李用户建议预留进站时间。', 1),
('exit_hongqiao_railway_metro', 'shanghai_hongqiao_railway_station', '地铁换乘大厅', '虹桥综合交通枢纽', '地铁2号线、10号线、17号线换乘客流较大，注意看清线路方向。', 1),
('exit_east_nanjing_road_center', 'east_nanjing_road', '南京东路方向出口', '南京东路步行街', '前往市中心商圈或换乘2号线时注意客流。', 0),
('exit_siping_road_transfer', 'siping_road', '8号线换乘导向', '四平路站换乘通道', '换乘8号线请按站内指示前往对应站台。', 0),
('exit_tongji_university_1', 'tongji_university', '1号口', '同济联合广场', '靠近同济联合广场，适合作为同济大学周边进出站口。', 1),
('exit_tongji_university_2', 'tongji_university', '2号口', '彰武路，赤峰路', '前往彰武路、赤峰路方向可选择2号口。', 1),
('exit_tongji_university_3', 'tongji_university', '3号口', '站厅南侧通道', '从站厅南侧通道出站，适合前往四平路沿线。', 0),
('exit_tongji_university_4', 'tongji_university', '4号口', '站厅南侧通道', '从站厅南侧通道出站，注意查看站内导向牌。', 0),
('exit_tongji_university_5', 'tongji_university', '5号口', '四平路，同济大学正门', '前往同济大学正门优先选择5号口。', 1);
