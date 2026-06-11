USE smart_travel;

-- 未录入不等于存在。将设施默认值调整为“未知/未确认”，
-- 防止新增站点在没有调查数据时被错误标记为设施齐全。
ALTER TABLE station_facilities
    MODIFY COLUMN has_elevator TINYINT(1) NOT NULL DEFAULT 0,
    MODIFY COLUMN has_escalator TINYINT(1) NOT NULL DEFAULT 0,
    MODIFY COLUMN has_wheelchair_ramp TINYINT(1) NOT NULL DEFAULT 0,
    MODIFY COLUMN has_wide_gate TINYINT(1) NOT NULL DEFAULT 0,
    MODIFY COLUMN has_accessible_restroom TINYINT(1) NOT NULL DEFAULT 0,
    MODIFY COLUMN has_blind_path TINYINT(1) NOT NULL DEFAULT 0,
    MODIFY COLUMN elevator_count INT NOT NULL DEFAULT 0,
    MODIFY COLUMN escalator_count INT NOT NULL DEFAULT 0;

INSERT IGNORE INTO schema_migrations (version, description)
VALUES ('006', 'Use safe defaults for unknown facility data');
