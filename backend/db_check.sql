USE smart_travel;

SELECT 'schema_migrations' AS table_name, COUNT(*) AS row_count FROM schema_migrations
UNION ALL SELECT 'stations', COUNT(*) FROM stations
UNION ALL SELECT 'metro_lines', COUNT(*) FROM metro_lines
UNION ALL SELECT 'line_directions', COUNT(*) FROM line_directions
UNION ALL SELECT 'line_stations', COUNT(*) FROM line_stations
UNION ALL SELECT 'line_station_transfer_lines', COUNT(*) FROM line_station_transfer_lines
UNION ALL SELECT 'transfer_rules', COUNT(*) FROM transfer_rules
UNION ALL SELECT 'transfer_rule_tags', COUNT(*) FROM transfer_rule_tags
UNION ALL SELECT 'transfer_rule_transfer_lines', COUNT(*) FROM transfer_rule_transfer_lines
UNION ALL SELECT 'static_resources', COUNT(*) FROM static_resources
UNION ALL SELECT 'station_exits', COUNT(*) FROM station_exits
UNION ALL SELECT 'station_geo_points', COUNT(*) FROM station_geo_points
UNION ALL SELECT 'station_facilities', COUNT(*) FROM station_facilities
UNION ALL SELECT 'travel_alerts', COUNT(*) FROM travel_alerts
UNION ALL SELECT 'travel_alert_routes', COUNT(*) FROM travel_alert_routes
UNION ALL SELECT 'trains', COUNT(*) FROM trains
UNION ALL SELECT 'train_stations', COUNT(*) FROM train_stations
UNION ALL SELECT 'train_carriages', COUNT(*) FROM train_carriages
UNION ALL SELECT 'common_routes', COUNT(*) FROM common_routes
UNION ALL SELECT 'common_route_segments', COUNT(*) FROM common_route_segments
UNION ALL SELECT 'user_preferences', COUNT(*) FROM user_preferences
UNION ALL SELECT 'user_abilities', COUNT(*) FROM user_abilities
UNION ALL SELECT 'user_luggage', COUNT(*) FROM user_luggage
UNION ALL SELECT 'feedbacks', COUNT(*) FROM feedbacks;

-- 关键关系完整性检查。所有结果都应为 0。
SELECT 'orphan_line_stations' AS check_name, COUNT(*) AS issue_count
FROM line_stations ls
LEFT JOIN metro_lines ml ON ml.line_id = ls.line_id
LEFT JOIN stations s ON s.station_id = ls.station_id
WHERE ml.line_id IS NULL OR s.station_id IS NULL
UNION ALL
SELECT 'orphan_station_exits', COUNT(*)
FROM station_exits se
LEFT JOIN stations s ON s.station_id = se.station_id
WHERE s.station_id IS NULL
UNION ALL
SELECT 'orphan_station_facilities', COUNT(*)
FROM station_facilities sf
LEFT JOIN stations s ON s.station_id = sf.station_id
WHERE s.station_id IS NULL
UNION ALL
SELECT 'orphan_transfer_rules', COUNT(*)
FROM transfer_rules tr
LEFT JOIN stations origin ON origin.station_id = tr.origin_station_id
LEFT JOIN stations target ON target.station_id = tr.target_station_id
LEFT JOIN metro_lines ml ON ml.line_id = tr.line_id
WHERE origin.station_id IS NULL
   OR target.station_id IS NULL
   OR ml.line_id IS NULL;

-- 核心演示数据检查。所有结果都应大于 0。
SELECT 'core_stations' AS check_name, COUNT(*) AS row_count FROM stations
UNION ALL SELECT 'core_metro_lines', COUNT(*) FROM metro_lines
UNION ALL SELECT 'core_line_stations', COUNT(*) FROM line_stations
UNION ALL SELECT 'core_transfer_rules', COUNT(*) FROM transfer_rules
UNION ALL SELECT 'core_static_resources', COUNT(*) FROM static_resources
UNION ALL SELECT 'core_travel_alerts', COUNT(*) FROM travel_alerts;
