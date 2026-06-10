USE smart_travel;

CREATE TABLE IF NOT EXISTS static_resources (
    id INT AUTO_INCREMENT PRIMARY KEY,
    resource_type VARCHAR(100) NOT NULL,
    resource_name VARCHAR(200) NOT NULL,
    resource_path VARCHAR(500) NOT NULL,
    description TEXT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_resource (resource_type, resource_name),
    INDEX idx_resource_type (resource_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO static_resources (resource_type, resource_name, resource_path, description) VALUES
('icon', 'timer', 'app/assets/icons/timer.png', '换乘倒计时图标'),
('icon', 'transfer', 'app/assets/icons/transfer.png', '站内换乘图标'),
('diagram', 'hongqiao-transfer', 'backend/go/data/station_topologies/hongqiao_railway_station.json', '虹桥火车站平面换乘拓扑数据'),
('diagram', 'tongji-university', 'backend/go/data/station_topologies/tongji_university.json', '同济大学站平面换乘拓扑数据')
ON DUPLICATE KEY UPDATE
    resource_path = VALUES(resource_path),
    description = VALUES(description);
