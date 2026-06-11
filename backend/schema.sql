-- Smart Travel MySQL 数据库结构
-- 数据库：smart_travel

CREATE DATABASE IF NOT EXISTS smart_travel DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE smart_travel;

-- 数据库版本记录。schema.sql 表示当前完整基线，后续升级由 migrations 维护。
CREATE TABLE schema_migrations (
    version VARCHAR(100) PRIMARY KEY,
    description VARCHAR(255) NOT NULL,
    applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO schema_migrations (version, description)
VALUES ('000_current_baseline', 'Current complete schema baseline');

-- 站点表
CREATE TABLE stations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    station_id VARCHAR(100) NOT NULL UNIQUE,
    station_name VARCHAR(200) NOT NULL,
    station_alias VARCHAR(200) DEFAULT NULL,
    city VARCHAR(100) NOT NULL DEFAULT '上海',
    district VARCHAR(100) DEFAULT NULL,
    station_type VARCHAR(100) NOT NULL DEFAULT '地铁站',
    description TEXT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_station_name (station_name),
    INDEX idx_city (city)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 地铁线路表
CREATE TABLE metro_lines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    line_id VARCHAR(100) NOT NULL UNIQUE,
    line_name VARCHAR(200) NOT NULL,
    city VARCHAR(100) NOT NULL DEFAULT '上海',
    color_name VARCHAR(100) DEFAULT NULL,
    color_hex VARCHAR(20) DEFAULT NULL,
    description TEXT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_line_name (line_name),
    INDEX idx_city (city)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 线路方向表（一对多关系）
CREATE TABLE line_directions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    line_id VARCHAR(100) NOT NULL,
    direction VARCHAR(200) NOT NULL,
    FOREIGN KEY (line_id) REFERENCES metro_lines(line_id) ON DELETE CASCADE,
    UNIQUE KEY uk_line_direction (line_id, direction)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 线路站点关联表
CREATE TABLE line_stations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    line_id VARCHAR(100) NOT NULL,
    station_id VARCHAR(100) NOT NULL,
    direction VARCHAR(200) NOT NULL,
    station_order INT NOT NULL,
    is_transfer TINYINT(1) DEFAULT 0,
    platform_tip TEXT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (line_id) REFERENCES metro_lines(line_id) ON DELETE CASCADE,
    FOREIGN KEY (station_id) REFERENCES stations(station_id) ON DELETE CASCADE,
    INDEX idx_line_direction_order (line_id, direction, station_order),
    INDEX idx_line_direction_station (line_id, direction, station_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 线路站点换乘线路关联表（多对多）
CREATE TABLE line_station_transfer_lines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    line_station_id INT NOT NULL,
    transfer_line_id VARCHAR(100) NOT NULL,
    FOREIGN KEY (line_station_id) REFERENCES line_stations(id) ON DELETE CASCADE,
    UNIQUE KEY uk_line_station_transfer (line_station_id, transfer_line_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 换乘规则表
CREATE TABLE transfer_rules (
    id INT AUTO_INCREMENT PRIMARY KEY,
    rule_id VARCHAR(100) NOT NULL UNIQUE,
    origin_station_id VARCHAR(100) NOT NULL,
    line_id VARCHAR(100) NOT NULL,
    target_station_id VARCHAR(100) NOT NULL,
    direction VARCHAR(200) NOT NULL,
    stops_count INT NOT NULL,
    estimated_minutes INT NOT NULL,
    carriage_suggestion VARCHAR(100) DEFAULT NULL,
    transfer_tip TEXT DEFAULT NULL,
    data_level ENUM('demo', 'verified', 'manual') DEFAULT 'demo',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (origin_station_id) REFERENCES stations(station_id) ON DELETE CASCADE,
    FOREIGN KEY (line_id) REFERENCES metro_lines(line_id) ON DELETE CASCADE,
    FOREIGN KEY (target_station_id) REFERENCES stations(station_id) ON DELETE CASCADE,
    INDEX idx_origin_line (origin_station_id, line_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 换乘规则标签表（多对多）
CREATE TABLE transfer_rule_tags (
    id INT AUTO_INCREMENT PRIMARY KEY,
    transfer_rule_id INT NOT NULL,
    tag VARCHAR(100) NOT NULL,
    FOREIGN KEY (transfer_rule_id) REFERENCES transfer_rules(id) ON DELETE CASCADE,
    UNIQUE KEY uk_rule_tag (transfer_rule_id, tag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 换乘规则可换乘线路表（多对多）
CREATE TABLE transfer_rule_transfer_lines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    transfer_rule_id INT NOT NULL,
    transfer_line_id VARCHAR(100) NOT NULL,
    FOREIGN KEY (transfer_rule_id) REFERENCES transfer_rules(id) ON DELETE CASCADE,
    UNIQUE KEY uk_rule_transfer_line (transfer_rule_id, transfer_line_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 静态资源表（图标、站内示意图、演示资源）
CREATE TABLE static_resources (
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

-- 站点出口表
CREATE TABLE station_exits (
    id INT AUTO_INCREMENT PRIMARY KEY,
    exit_id VARCHAR(100) NOT NULL UNIQUE,
    station_id VARCHAR(100) NOT NULL,
    exit_name VARCHAR(200) NOT NULL,
    nearby_place VARCHAR(200) DEFAULT NULL,
    guide_tip TEXT DEFAULT NULL,
    is_accessible TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (station_id) REFERENCES stations(station_id) ON DELETE CASCADE,
    INDEX idx_station (station_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 站点无障碍与服务设施表
CREATE TABLE station_facilities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    station_id VARCHAR(100) NOT NULL UNIQUE,
    has_elevator TINYINT(1) NOT NULL DEFAULT 0,
    has_escalator TINYINT(1) NOT NULL DEFAULT 0,
    has_wheelchair_ramp TINYINT(1) NOT NULL DEFAULT 0,
    has_wide_gate TINYINT(1) NOT NULL DEFAULT 0,
    has_accessible_restroom TINYINT(1) NOT NULL DEFAULT 0,
    has_blind_path TINYINT(1) NOT NULL DEFAULT 0,
    elevator_count INT NOT NULL DEFAULT 0,
    elevator_location VARCHAR(255) DEFAULT '',
    escalator_count INT NOT NULL DEFAULT 0,
    restroom_location VARCHAR(255) DEFAULT '',
    has_restroom_in_paid TINYINT(1) NOT NULL DEFAULT 0,
    has_restroom_outside TINYINT(1) NOT NULL DEFAULT 0,
    has_mother_baby_room TINYINT(1) NOT NULL DEFAULT 0,
    has_third_bathroom TINYINT(1) NOT NULL DEFAULT 0,
    has_aed TINYINT(1) NOT NULL DEFAULT 0,
    has_service_center TINYINT(1) NOT NULL DEFAULT 0,
    facility_note TEXT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (station_id) REFERENCES stations(station_id) ON DELETE CASCADE,
    INDEX idx_station_facility_station (station_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 用户反馈表
CREATE TABLE feedbacks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    contact VARCHAR(255) DEFAULT NULL,
    status ENUM('pending', 'processing', 'resolved', 'closed') NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_feedback_status_created (status, created_at),
    INDEX idx_feedback_type (type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 出行提醒表
CREATE TABLE travel_alerts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    type ENUM('delay', 'control', 'accident', 'other') NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 出行提醒影响线路表（多对多）
CREATE TABLE travel_alert_routes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    alert_id INT NOT NULL,
    route VARCHAR(200) NOT NULL,
    FOREIGN KEY (alert_id) REFERENCES travel_alerts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 高铁车次表
CREATE TABLE trains (
    id INT AUTO_INCREMENT PRIMARY KEY,
    number VARCHAR(50) NOT NULL UNIQUE,
    start VARCHAR(200) NOT NULL,
    end VARCHAR(200) NOT NULL,
    departure VARCHAR(50) NOT NULL,
    arrival VARCHAR(50) NOT NULL,
    platform VARCHAR(50) NOT NULL,
    door_direction VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 高铁车次途经站点表
CREATE TABLE train_stations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    train_id INT NOT NULL,
    station_name VARCHAR(200) NOT NULL,
    station_order INT NOT NULL,
    FOREIGN KEY (train_id) REFERENCES trains(id) ON DELETE CASCADE,
    INDEX idx_train_order (train_id, station_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 高铁车厢表
CREATE TABLE train_carriages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    train_id INT NOT NULL,
    carriage_number VARCHAR(50) NOT NULL,
    carriage_type VARCHAR(100) DEFAULT NULL,
    distance VARCHAR(100) DEFAULT NULL,
    FOREIGN KEY (train_id) REFERENCES trains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 常用路线表
CREATE TABLE common_routes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(100) DEFAULT NULL,
    start VARCHAR(200) NOT NULL,
    end VARCHAR(200) NOT NULL,
    time VARCHAR(50) DEFAULT NULL,
    distance VARCHAR(50) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 常用路线分段表
CREATE TABLE common_route_segments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    route_id INT NOT NULL,
    segment_type VARCHAR(100) DEFAULT NULL,
    distance VARCHAR(50) DEFAULT NULL,
    time VARCHAR(50) DEFAULT NULL,
    FOREIGN KEY (route_id) REFERENCES common_routes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 用户偏好表
CREATE TABLE user_preferences (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(100) NOT NULL UNIQUE,
    theme_color VARCHAR(50) DEFAULT 'system',
    theme_mode VARCHAR(50) DEFAULT 'system',
    font_size VARCHAR(50) DEFAULT 'medium',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 用户能力设置表
CREATE TABLE user_abilities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(100) NOT NULL,
    ability_type VARCHAR(100) NOT NULL,
    ability_level INT DEFAULT 0,
    description TEXT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_ability (user_id, ability_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 用户行李设置表
CREATE TABLE user_luggage (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(100) NOT NULL,
    luggage_type VARCHAR(100) NOT NULL,
    weight VARCHAR(50) DEFAULT NULL,
    size VARCHAR(50) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_luggage (user_id, luggage_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
