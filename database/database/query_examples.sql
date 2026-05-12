-- 地铁跑酷换乘助手：基础交通数据查询示例
-- 用途：给后端、Android 端、课程演示验证车站线路数据是否可用。

USE metro_decision_assistant;
SET NAMES utf8mb4;

-- 1. 查询所有基础站点
SELECT
  station_id,
  station_name,
  station_alias,
  city,
  district,
  station_type
FROM stations
ORDER BY station_name;

-- 2. 查询所有地铁线路
SELECT
  line_id,
  line_name,
  color_name,
  color_hex,
  directions
FROM metro_lines
ORDER BY line_name;

-- 3. 查询10号线从虹桥火车站到同济大学的站点顺序
SELECT
  ls.station_order,
  s.station_name,
  s.station_alias,
  ls.is_transfer,
  ls.transfer_line_ids,
  ls.platform_tip
FROM line_stations ls
JOIN stations s ON ls.station_id = s.station_id
WHERE ls.line_id = 'shanghai_metro_line_10'
  AND ls.direction = '往基隆路方向'
ORDER BY ls.station_order;

-- 4. 查询10号线换乘站及可换乘线路名称
SELECT
  ls.station_order,
  s.station_name,
  GROUP_CONCAT(ml.line_name ORDER BY ml.line_name SEPARATOR '、') AS transfer_lines
FROM line_stations ls
JOIN stations s ON ls.station_id = s.station_id
JOIN metro_lines ml ON FIND_IN_SET(ml.line_id, ls.transfer_line_ids)
WHERE ls.line_id = 'shanghai_metro_line_10'
  AND ls.direction = '往基隆路方向'
  AND ls.is_transfer = 1
GROUP BY ls.station_order, s.station_name
ORDER BY ls.station_order;

-- 5. 查询从虹桥火车站乘10号线的所有换乘推荐规则
SELECT
  tr.rule_id,
  origin.station_name AS origin_station,
  ml.line_name AS ride_line,
  tr.direction,
  target.station_name AS target_station,
  tr.stops_count,
  tr.estimated_minutes,
  tr.transfer_line_ids,
  tr.carriage_suggestion,
  tr.tags
FROM transfer_rules tr
JOIN stations origin ON tr.origin_station_id = origin.station_id
JOIN metro_lines ml ON tr.line_id = ml.line_id
JOIN stations target ON tr.target_station_id = target.station_id
WHERE tr.origin_station_id = 'shanghai_hongqiao_railway_station'
  AND tr.line_id = 'shanghai_metro_line_10'
ORDER BY tr.stops_count;

-- 6. 搜索目标站、标签或换乘提示，例如搜索“同济大学”
SELECT
  tr.rule_id,
  target.station_name AS target_station,
  tr.stops_count,
  tr.estimated_minutes,
  tr.transfer_tip,
  tr.tags
FROM transfer_rules tr
JOIN stations target ON tr.target_station_id = target.station_id
WHERE tr.origin_station_id = 'shanghai_hongqiao_railway_station'
  AND tr.line_id = 'shanghai_metro_line_10'
  AND (
    target.station_name LIKE '%同济大学%'
    OR IFNULL(target.station_alias, '') LIKE '%同济大学%'
    OR IFNULL(tr.transfer_tip, '') LIKE '%同济大学%'
    OR IFNULL(tr.tags, '') LIKE '%同济大学%'
  );

-- 7. 搜索可换乘2号线的规则
SELECT
  tr.rule_id,
  target.station_name AS target_station,
  tr.stops_count,
  tr.estimated_minutes,
  tr.transfer_line_ids,
  tr.transfer_tip
FROM transfer_rules tr
JOIN stations target ON tr.target_station_id = target.station_id
WHERE FIND_IN_SET('shanghai_metro_line_2', tr.transfer_line_ids)
ORDER BY tr.stops_count;

-- 8. 查询某个站点的出入口或站内导向
SELECT
  s.station_name,
  se.exit_name,
  se.nearby_place,
  se.guide_tip,
  se.is_accessible
FROM station_exits se
JOIN stations s ON se.station_id = s.station_id
WHERE se.station_id = 'shanghai_hongqiao_railway_station';

-- 9. 给后端使用的完整路线建议示例：虹桥火车站到同济大学
SELECT
  origin.station_name AS origin_station,
  ml.line_name AS ride_line,
  tr.direction,
  target.station_name AS target_station,
  tr.stops_count,
  tr.estimated_minutes,
  tr.carriage_suggestion,
  tr.transfer_tip,
  tr.tags
FROM transfer_rules tr
JOIN stations origin ON tr.origin_station_id = origin.station_id
JOIN stations target ON tr.target_station_id = target.station_id
JOIN metro_lines ml ON tr.line_id = ml.line_id
WHERE tr.rule_id = 'rule_hongqiao_to_tongji_university';

-- 10. 统计当前基础交通数据规模
SELECT 'stations' AS table_name, COUNT(*) AS total_count FROM stations
UNION ALL
SELECT 'metro_lines' AS table_name, COUNT(*) AS total_count FROM metro_lines
UNION ALL
SELECT 'line_stations' AS table_name, COUNT(*) AS total_count FROM line_stations
UNION ALL
SELECT 'transfer_rules' AS table_name, COUNT(*) AS total_count FROM transfer_rules
UNION ALL
SELECT 'station_exits' AS table_name, COUNT(*) AS total_count FROM station_exits;
