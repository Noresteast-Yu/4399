USE smart_travel;

CREATE TABLE IF NOT EXISTS station_geo_points (
    id INT AUTO_INCREMENT PRIMARY KEY,
    station_id VARCHAR(100) NOT NULL UNIQUE,
    latitude DECIMAL(10, 7) NOT NULL,
    longitude DECIMAL(10, 7) NOT NULL,
    source VARCHAR(100) NOT NULL DEFAULT 'manual',
    accuracy_note VARCHAR(255) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (station_id) REFERENCES stations(station_id) ON DELETE CASCADE,
    INDEX idx_station_geo_lat_lng (latitude, longitude)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO station_geo_points (station_id, latitude, longitude, source, accuracy_note) VALUES
('tongji_university', 31.2821000, 121.5063000, 'manual-demo', '同济大学站演示坐标'),
('siping_road', 31.2749000, 121.5082000, 'manual-demo', '四平路站演示坐标'),
('wujiaochang_10', 31.3039000, 121.5145000, 'manual-demo', '五角场站演示坐标'),
('guoquan_road', 31.2895000, 121.5104000, 'manual-demo', '国权路站演示坐标'),
('shanghai_railway_1', 31.2495000, 121.4555000, 'manual-demo', '上海火车站演示坐标'),
('peoples_square', 31.2304000, 121.4737000, 'manual-demo', '人民广场站演示坐标'),
('east_nanjing_road', 31.2392000, 121.4846000, 'manual-demo', '南京东路站演示坐标'),
('hongqiao_railway_2', 31.1943000, 121.3189000, 'manual-demo', '虹桥火车站演示坐标'),
('pudong_airport', 31.1500000, 121.8050000, 'manual-demo', '浦东国际机场站演示坐标')
ON DUPLICATE KEY UPDATE
    latitude = VALUES(latitude),
    longitude = VALUES(longitude),
    source = VALUES(source),
    accuracy_note = VALUES(accuracy_note);

INSERT IGNORE INTO schema_migrations (version, description)
VALUES ('007', 'Add station geo points for nearest station recommendation');
