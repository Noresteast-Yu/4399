USE smart_travel;

-- 同济大学站是当前完整演示站。这里补齐数据库侧设施摘要，
-- 详细导航拓扑仍由版本化 JSON 维护，照片由对象存储维护。
INSERT INTO station_facilities (
    station_id,
    has_elevator,
    has_escalator,
    has_wheelchair_ramp,
    has_wide_gate,
    has_accessible_restroom,
    has_blind_path,
    elevator_count,
    elevator_location,
    escalator_count,
    restroom_location,
    has_restroom_in_paid,
    has_restroom_outside,
    has_mother_baby_room,
    has_third_bathroom,
    has_aed,
    has_service_center,
    facility_note
)
SELECT
    'tongji_university',
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    '站厅至站台无障碍电梯',
    4,
    '4号口地下附近，非付费区',
    0,
    1,
    0,
    0,
    1,
    1,
    '演示数据；详细位置与通行关系以站内拓扑文件为准'
FROM stations
WHERE station_id = 'tongji_university'
ON DUPLICATE KEY UPDATE
    elevator_location = VALUES(elevator_location),
    restroom_location = VALUES(restroom_location),
    has_restroom_in_paid = VALUES(has_restroom_in_paid),
    has_restroom_outside = VALUES(has_restroom_outside),
    has_aed = VALUES(has_aed),
    has_service_center = VALUES(has_service_center),
    facility_note = VALUES(facility_note);

-- 数据校验接口要求 travel_alerts 至少有一条记录。
-- 使用明确的演示标题作为自然幂等键，不会重复插入。
INSERT INTO travel_alerts (type, title, message)
SELECT
    'other',
    '演示环境运行正常',
    '当前为课程项目演示数据，不代表上海地铁实时运营公告。'
WHERE NOT EXISTS (
    SELECT 1
    FROM travel_alerts
    WHERE title = '演示环境运行正常'
);

INSERT IGNORE INTO schema_migrations (version, description)
VALUES ('005', 'Maintain verified demo reference data');
