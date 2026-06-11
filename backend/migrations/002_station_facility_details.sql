USE smart_travel;

-- 每列单独修改，现有迁移器可逐列跳过 MySQL 1060（字段已存在）错误。
-- 这样即使数据库只完成了部分升级，也可以安全补齐剩余字段。
ALTER TABLE station_facilities
    ADD COLUMN elevator_location VARCHAR(255) DEFAULT '' AFTER elevator_count;

ALTER TABLE station_facilities
    ADD COLUMN restroom_location VARCHAR(255) DEFAULT '' AFTER escalator_count;

ALTER TABLE station_facilities
    ADD COLUMN has_restroom_in_paid TINYINT(1) NOT NULL DEFAULT 0 AFTER restroom_location;

ALTER TABLE station_facilities
    ADD COLUMN has_restroom_outside TINYINT(1) NOT NULL DEFAULT 0 AFTER has_restroom_in_paid;

ALTER TABLE station_facilities
    ADD COLUMN has_mother_baby_room TINYINT(1) NOT NULL DEFAULT 0 AFTER has_restroom_outside;

ALTER TABLE station_facilities
    ADD COLUMN has_third_bathroom TINYINT(1) NOT NULL DEFAULT 0 AFTER has_mother_baby_room;

ALTER TABLE station_facilities
    ADD COLUMN has_aed TINYINT(1) NOT NULL DEFAULT 0 AFTER has_third_bathroom;

ALTER TABLE station_facilities
    ADD COLUMN has_service_center TINYINT(1) NOT NULL DEFAULT 0 AFTER has_aed;

INSERT IGNORE INTO schema_migrations (version, description)
VALUES ('002', 'Add detailed station facility fields');
