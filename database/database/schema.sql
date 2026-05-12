-- 地铁跑酷换乘助手：基础交通数据 MySQL 建表脚本
-- 作用：创建车站、线路、线路站点顺序、换乘规则、出入口等基础表。
-- 说明：这部分是系统主干数据，用户画像和 AI 决策属于建立在它之上的扩展功能。

CREATE DATABASE IF NOT EXISTS metro_decision_assistant
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE metro_decision_assistant;
SET NAMES utf8mb4;

DROP TABLE IF EXISTS transfer_rules;
DROP TABLE IF EXISTS station_exits;
DROP TABLE IF EXISTS line_stations;
DROP TABLE IF EXISTS stations;
DROP TABLE IF EXISTS metro_lines;

-- 1. 站点基础表
CREATE TABLE stations (
  station_id VARCHAR(96) PRIMARY KEY COMMENT '站点唯一编号，供后端和移动端稳定引用',
  station_name VARCHAR(96) NOT NULL COMMENT '站点中文名',
  station_alias VARCHAR(96) DEFAULT NULL COMMENT '站点别名或旧称，例如新天地',
  city VARCHAR(32) NOT NULL DEFAULT '上海',
  district VARCHAR(32) DEFAULT NULL COMMENT '行政区，演示阶段可为空或粗略填写',
  station_type VARCHAR(64) NOT NULL DEFAULT '地铁站' COMMENT '例如高铁站/地铁站、地铁站、交通枢纽',
  description TEXT COMMENT '站点说明，课程演示数据可写简要说明',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_stations_city (city),
  INDEX idx_stations_name (station_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='站点基础表';

-- 2. 地铁线路基础表
CREATE TABLE metro_lines (
  line_id VARCHAR(96) PRIMARY KEY COMMENT '线路唯一编号',
  line_name VARCHAR(96) NOT NULL COMMENT '线路中文名',
  city VARCHAR(32) NOT NULL DEFAULT '上海',
  color_name VARCHAR(32) DEFAULT NULL COMMENT '线路颜色名称',
  color_hex VARCHAR(16) DEFAULT NULL COMMENT '线路颜色十六进制值，供前端展示使用',
  directions VARCHAR(255) DEFAULT NULL COMMENT '方向列表，演示阶段用逗号分隔',
  description TEXT COMMENT '线路说明',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_metro_lines_city (city),
  INDEX idx_metro_lines_name (line_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='地铁线路基础表';

-- 3. 线路站点顺序表
CREATE TABLE line_stations (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  line_id VARCHAR(96) NOT NULL,
  station_id VARCHAR(96) NOT NULL,
  direction VARCHAR(96) NOT NULL COMMENT '本条顺序对应的乘坐方向',
  station_order INT NOT NULL COMMENT '站点顺序，从该方向起点开始编号',
  is_transfer TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否换乘站',
  transfer_line_ids VARCHAR(255) DEFAULT NULL COMMENT '可换乘线路id，演示阶段用逗号分隔',
  platform_tip VARCHAR(255) DEFAULT NULL COMMENT '站台或上下车提示，课程演示用',
  CONSTRAINT fk_line_stations_line
    FOREIGN KEY (line_id) REFERENCES metro_lines(line_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_line_stations_station
    FOREIGN KEY (station_id) REFERENCES stations(station_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  UNIQUE KEY uk_line_station_direction_order (line_id, direction, station_order),
  UNIQUE KEY uk_line_station_direction_station (line_id, direction, station_id),
  INDEX idx_line_stations_line_direction (line_id, direction, station_order),
  INDEX idx_line_stations_station (station_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='线路站点顺序表';

-- 4. 换乘推荐规则表
CREATE TABLE transfer_rules (
  rule_id VARCHAR(96) PRIMARY KEY COMMENT '换乘规则唯一编号',
  origin_station_id VARCHAR(96) NOT NULL COMMENT '出发站id',
  line_id VARCHAR(96) NOT NULL COMMENT '乘坐线路id',
  target_station_id VARCHAR(96) NOT NULL COMMENT '目标站或换乘站id',
  direction VARCHAR(96) NOT NULL COMMENT '乘坐方向',
  stops_count INT NOT NULL COMMENT '从出发站经过几站到达目标站',
  estimated_minutes INT NOT NULL COMMENT '预计乘车时间，单位分钟，课程演示数据',
  transfer_line_ids VARCHAR(255) DEFAULT NULL COMMENT '到站后可换乘线路id，演示阶段用逗号分隔',
  carriage_suggestion VARCHAR(128) DEFAULT NULL COMMENT '推荐车厢',
  transfer_tip TEXT COMMENT '换乘或出站提示',
  tags VARCHAR(255) DEFAULT NULL COMMENT '规则标签，演示阶段用逗号分隔',
  data_level ENUM('demo', 'verified', 'manual') NOT NULL DEFAULT 'demo' COMMENT '数据级别：demo演示、verified已核对、manual人工维护',
  CONSTRAINT fk_transfer_rules_origin
    FOREIGN KEY (origin_station_id) REFERENCES stations(station_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_transfer_rules_line
    FOREIGN KEY (line_id) REFERENCES metro_lines(line_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_transfer_rules_target
    FOREIGN KEY (target_station_id) REFERENCES stations(station_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_transfer_rules_origin_line (origin_station_id, line_id),
  INDEX idx_transfer_rules_target (target_station_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='换乘推荐规则表';

-- 5. 站点出入口和站内导向表
CREATE TABLE station_exits (
  exit_id VARCHAR(96) PRIMARY KEY COMMENT '出入口或导向点编号',
  station_id VARCHAR(96) NOT NULL,
  exit_name VARCHAR(64) NOT NULL COMMENT '出入口名称或导向点名称',
  nearby_place VARCHAR(128) DEFAULT NULL COMMENT '附近地点',
  guide_tip TEXT COMMENT '出入口或站内导向说明，演示阶段可粗略填写',
  is_accessible TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否适合无障碍或携带行李用户',
  CONSTRAINT fk_station_exits_station
    FOREIGN KEY (station_id) REFERENCES stations(station_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_station_exits_station (station_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='站点出入口和站内导向表';
