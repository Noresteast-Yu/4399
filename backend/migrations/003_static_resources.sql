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

-- 删除历史上指向不存在文件的记录，避免接口返回不可用资源。
DELETE FROM static_resources
WHERE (resource_type = 'icon' AND resource_name IN ('timer', 'transfer'))
   OR (resource_type = 'diagram' AND resource_name = 'hongqiao-transfer');

INSERT INTO static_resources (resource_type, resource_name, resource_path, description) VALUES
('diagram', 'tongji-university', 'backend/go/data/station_topologies/tongji_university.json', '同济大学站站内拓扑数据')
ON DUPLICATE KEY UPDATE
    resource_path = VALUES(resource_path),
    description = VALUES(description);

INSERT IGNORE INTO schema_migrations (version, description)
VALUES ('003', 'Clean and register static resources');
