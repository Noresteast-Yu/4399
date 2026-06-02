USE smart_travel;

ALTER TABLE station_facilities
    ADD COLUMN elevator_location VARCHAR(255) DEFAULT '' AFTER elevator_count,
    ADD COLUMN restroom_location VARCHAR(255) DEFAULT '' AFTER escalator_count,
    ADD COLUMN has_restroom_in_paid TINYINT(1) NOT NULL DEFAULT 0 AFTER restroom_location,
    ADD COLUMN has_restroom_outside TINYINT(1) NOT NULL DEFAULT 0 AFTER has_restroom_in_paid,
    ADD COLUMN has_mother_baby_room TINYINT(1) NOT NULL DEFAULT 0 AFTER has_restroom_outside,
    ADD COLUMN has_third_bathroom TINYINT(1) NOT NULL DEFAULT 0 AFTER has_mother_baby_room,
    ADD COLUMN has_aed TINYINT(1) NOT NULL DEFAULT 0 AFTER has_third_bathroom,
    ADD COLUMN has_service_center TINYINT(1) NOT NULL DEFAULT 0 AFTER has_aed;

UPDATE station_facilities
SET
    elevator_location = CASE station_id
        WHEN 'shanghai_hongqiao_railway_station' THEN '到达层、换乘大厅、站台层均有无障碍电梯'
        WHEN 'hongqiao_terminal_2' THEN '航站楼连廊和站厅两侧'
        WHEN 'tongji_university' THEN '站厅至站台各1部，近校园方向出口'
        ELSE '站厅至站台各1部'
    END,
    restroom_location = CASE
        WHEN has_accessible_restroom = 1 THEN '站厅层近服务中心'
        ELSE '站厅层费区外'
    END,
    has_restroom_in_paid = has_accessible_restroom,
    has_restroom_outside = CASE WHEN has_accessible_restroom = 1 THEN 0 ELSE 1 END,
    has_mother_baby_room = CASE
        WHEN station_id IN ('shanghai_hongqiao_railway_station', 'hongqiao_terminal_2', 'shanghai_zoo', 'south_shaanxi_road', 'site_first_cpc_xintiandi', 'yuyuan', 'east_nanjing_road', 'tongji_university') THEN 1
        ELSE 0
    END,
    has_third_bathroom = has_accessible_restroom,
    has_aed = 1,
    has_service_center = 1;
