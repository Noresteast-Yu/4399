USE smart_travel;

SELECT 'stations' AS table_name, COUNT(*) AS row_count FROM stations
UNION ALL SELECT 'metro_lines', COUNT(*) FROM metro_lines
UNION ALL SELECT 'line_directions', COUNT(*) FROM line_directions
UNION ALL SELECT 'line_stations', COUNT(*) FROM line_stations
UNION ALL SELECT 'line_station_transfer_lines', COUNT(*) FROM line_station_transfer_lines
UNION ALL SELECT 'transfer_rules', COUNT(*) FROM transfer_rules
UNION ALL SELECT 'transfer_rule_tags', COUNT(*) FROM transfer_rule_tags
UNION ALL SELECT 'transfer_rule_transfer_lines', COUNT(*) FROM transfer_rule_transfer_lines
UNION ALL SELECT 'static_resources', COUNT(*) FROM static_resources
UNION ALL SELECT 'station_exits', COUNT(*) FROM station_exits
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
UNION ALL SELECT 'user_luggage', COUNT(*) FROM user_luggage;
