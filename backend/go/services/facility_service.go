package services

import (
	"fmt"
	"smart-travel-backend/database"
	"smart-travel-backend/models"
)

type StationFacilityInfo struct {
	StationID             string   `json:"stationId"`
	StationName           string   `json:"stationName"`
	LineIDs               []string `json:"lineIds"`
	HasElevator           bool     `json:"hasElevator"`
	ElevatorCount         int      `json:"elevatorCount"`
	ElevatorLocation      string   `json:"elevatorLocation"`
	HasEscalator          bool     `json:"hasEscalator"`
	HasAccessibleRestroom bool     `json:"hasAccessibleRestroom"`
	RestroomLocation      string   `json:"restroomLocation"`
	HasRestroomInPaid     bool     `json:"hasRestroomInPaid"`
	HasRestroomOutside    bool     `json:"hasRestroomOutside"`
	HasMotherBabyRoom     bool     `json:"hasMotherBabyRoom"`
	HasThirdBathroom      bool     `json:"hasThirdBathroom"`
	HasWheelchairRamp     bool     `json:"hasWheelchairRamp"`
	HasWideGate           bool     `json:"hasWideGate"`
	HasBlindPath          bool     `json:"hasBlindPath"`
	HasAED                bool     `json:"hasAED"`
	HasServiceCenter      bool     `json:"hasServiceCenter"`
	FacilityNote          string   `json:"facilityNote"`
}

func GetStationFacilityInfo(stationID string) (*StationFacilityInfo, error) {
	if database.DB != nil {
		var facility models.StationFacility
		err := database.DB.QueryRow(
			"SELECT station_id, has_elevator, has_escalator, has_wheelchair_ramp, has_wide_gate, has_accessible_restroom, has_blind_path, elevator_count, escalator_count, facility_note FROM station_facilities WHERE station_id = ? LIMIT 1",
			stationID,
		).Scan(
			&facility.StationID, &facility.HasElevator, &facility.HasEscalator,
			&facility.HasWheelchairRamp, &facility.HasWideGate, &facility.HasAccessibleRestroom,
			&facility.HasBlindPath, &facility.ElevatorCount, &facility.EscalatorCount,
			&facility.FacilityNote,
		)
		if err != nil {
			if info := getFacilityByID(stationID); info != nil {
				return info, nil
			}
			if station, ok := MetroNetworkStationForID(stationID); ok {
				return genericNetworkFacility(station), nil
			}
			return nil, err
		}
		return convertFacility(&facility, ""), nil
	}

	info := getFacilityByID(stationID)
	if info == nil {
		if station, ok := MetroNetworkStationForID(stationID); ok {
			return genericNetworkFacility(station), nil
		}
		return nil, nil
	}
	return info, nil
}

func genericNetworkFacility(station models.Station) *StationFacilityInfo {
	return &StationFacilityInfo{
		StationID:             station.StationID,
		StationName:           station.StationName,
		LineIDs:               MetroNetworkLineIDsForStationID(station.StationID),
		HasElevator:           true,
		ElevatorCount:         1,
		ElevatorLocation:      "请以站内无障碍电梯导向为准",
		HasEscalator:          true,
		HasAccessibleRestroom: true,
		RestroomLocation:      "请以站内卫生间导向为准",
		HasRestroomInPaid:     false,
		HasRestroomOutside:    true,
		HasMotherBabyRoom:     false,
		HasThirdBathroom:      false,
		HasWheelchairRamp:     true,
		HasWideGate:           true,
		HasBlindPath:          true,
		HasAED:                true,
		HasServiceCenter:      true,
		FacilityNote:          "全网演示设施信息，具体位置请以站内导向为准",
	}
}

func convertFacility(f *models.StationFacility, name string) *StationFacilityInfo {
	return &StationFacilityInfo{
		StationID:             f.StationID,
		StationName:           name,
		HasElevator:           f.HasElevator,
		ElevatorCount:         f.ElevatorCount,
		HasEscalator:          f.HasEscalator,
		HasAccessibleRestroom: f.HasAccessibleRestroom,
		HasWheelchairRamp:     f.HasWheelchairRamp,
		HasWideGate:           f.HasWideGate,
		HasBlindPath:          f.HasBlindPath,
		FacilityNote:          f.FacilityNote,
	}
}

func IsStationAccessible(stationID string) bool {
	info := getFacilityByID(stationID)
	if info == nil {
		return false
	}
	return info.HasElevator && info.HasWheelchairRamp
}

func IsWheelchairFriendly(stationID string) bool {
	info := getFacilityByID(stationID)
	if info == nil {
		return false
	}
	return info.HasElevator && info.HasWheelchairRamp && info.HasAccessibleRestroom && info.HasWideGate
}

func getFacilityByID(stationID string) *StationFacilityInfo {
	facilities := map[string]*StationFacilityInfo{
		// 2号线站点设施
		"pudong_airport": {
			StationID: "pudong_airport", StationName: "浦东国际机场", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 4, ElevatorLocation: "站厅层至站台、地面至站厅各2部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: true, HasThirdBathroom: true,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "航空枢纽站，设施完善",
		},
		"yuanshen": {
			StationID: "yuanshen", StationName: "远东大道", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: false, RestroomLocation: "站厅层（费区外）",
			HasRestroomInPaid: false, HasRestroomOutside: true,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "",
		},
		"lingkong": {
			StationID: "lingkong", StationName: "凌空路", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: false, RestroomLocation: "站厅层（费区外）",
			HasRestroomInPaid: false, HasRestroomOutside: true,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "",
		},
		"huaxia": {
			StationID: "huaxia", StationName: "华夏东路", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: true,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "2025年新改造，新增第三卫生间",
		},
		"chuansha": {
			StationID: "chuansha", StationName: "川沙", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站厅层（费区外）",
			HasRestroomInPaid: false, HasRestroomOutside: true,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "",
		},
		"shenjiang": {
			StationID: "shenjiang", StationName: "华夏镇", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: false, RestroomLocation: "站厅层（费区外）",
			HasRestroomInPaid: false, HasRestroomOutside: true,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "",
		},
		"shanghai_race_track": {
			StationID: "shanghai_race_track", StationName: "创新中路", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: false, RestroomLocation: "站厅层（费区外）",
			HasRestroomInPaid: false, HasRestroomOutside: true,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "",
		},
		"guanglan_road": {
			StationID: "guanglan_road", StationName: "广兰路", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: true,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "2025年厕所升级改造，新增无障碍卫生间",
		},
		"tianzhu_road": {
			StationID: "tianzhu_road", StationName: "唐镇", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: false, RestroomLocation: "站厅层（费区外）",
			HasRestroomInPaid: false, HasRestroomOutside: true,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "",
		},
		"jinqiao_road": {
			StationID: "jinqiao_road", StationName: "创新路", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: false, RestroomLocation: "站厅层（费区外）",
			HasRestroomInPaid: false, HasRestroomOutside: true,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: false, HasServiceCenter: true, FacilityNote: "",
		},
		"jinyang_road": {
			StationID: "jinyang_road", StationName: "金科路", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: false, RestroomLocation: "站厅层（费区外）",
			HasRestroomInPaid: false, HasRestroomOutside: true,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: false, HasServiceCenter: true, FacilityNote: "",
		},
		"zhangjiang_high_tech": {
			StationID: "zhangjiang_high_tech", StationName: "张江高科", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站厅层（费区外）",
			HasRestroomInPaid: false, HasRestroomOutside: true,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "",
		},
		"longyang_road_2": {
			StationID: "longyang_road_2", StationName: "龙阳路", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 3, ElevatorLocation: "地面至站厅2部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站厅层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "多线换乘枢纽，设施较完善",
		},
		"shanghai_science_tech": {
			StationID: "shanghai_science_tech", StationName: "上海科技馆", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: true, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "靠近科技馆景区",
		},
		"Century_Avenue": {
			StationID: "Century_Avenue", StationName: "世纪大道", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 4, ElevatorLocation: "各出入口及换乘通道均有配置",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站厅层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: true, HasThirdBathroom: true,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "四线换乘枢纽，无障碍设施全面",
		},
		"dongchang_road": {
			StationID: "dongchang_road", StationName: "东昌路", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: false, RestroomLocation: "站厅层（费区外）",
			HasRestroomInPaid: false, HasRestroomOutside: true,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: false, HasServiceCenter: true, FacilityNote: "",
		},
		"lujiazui": {
			StationID: "lujiazui", StationName: "陆家嘴", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 3, ElevatorLocation: "地面至站厅2部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "核心CBD站点，客流量大",
		},
		"dongbei_road": {
			StationID: "dongbei_road", StationName: "东门路", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: false, RestroomLocation: "站厅层（费区外）",
			HasRestroomInPaid: false, HasRestroomOutside: true,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: false, HasServiceCenter: true, FacilityNote: "",
		},
		"nanjing_east_road": {
			StationID: "nanjing_east_road", StationName: "南京东路", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 3, ElevatorLocation: "地面至站厅2部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "南京路步行街旁，客流量极大",
		},
		"renmin_square": {
			StationID: "renmin_square", StationName: "人民广场", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 6, ElevatorLocation: "各出入口及换乘通道均有配置",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站厅层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: true, HasThirdBathroom: true,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "三线换乘枢纽，无障碍设施最全面",
		},
		"shimen_road": {
			StationID: "shimen_road", StationName: "石门一路", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: false, RestroomLocation: "站厅层（费区外）",
			HasRestroomInPaid: false, HasRestroomOutside: true,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: false, HasServiceCenter: true, FacilityNote: "",
		},
		"jingan_temple": {
			StationID: "jingan_temple", StationName: "静安寺", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 3, ElevatorLocation: "地面至站厅2部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "靠近静安寺商圈",
		},
		"west_nan_jing_road": {
			StationID: "west_nan_jing_road", StationName: "南京西路", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: false, RestroomLocation: "站厅层（费区外）",
			HasRestroomInPaid: false, HasRestroomOutside: true,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "",
		},
		"jiangsu_road": {
			StationID: "jiangsu_road", StationName: "江苏路", LineIDs: []string{"2", "11"},
			HasElevator: true, ElevatorCount: 4, ElevatorLocation: "B2层无障碍电梯已划至费区外，乘客可自主使用",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站厅层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "2024年无障碍电梯优化调整，盲道贯通",
		},
		"zhongshan_park": {
			StationID: "zhongshan_park", StationName: "中山公园", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 3, ElevatorLocation: "地面至站厅2部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站厅层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "",
		},
		"longxu_road": {
			StationID: "longxu_road", StationName: "龙漕路", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: false, RestroomLocation: "站厅层（费区外）",
			HasRestroomInPaid: false, HasRestroomOutside: true,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: false, HasServiceCenter: true, FacilityNote: "",
		},
		"caobao_road": {
			StationID: "caobao_road", StationName: "漕宝路", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: false, RestroomLocation: "站厅层（费区外）",
			HasRestroomInPaid: false, HasRestroomOutside: true,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: false, HasServiceCenter: true, FacilityNote: "",
		},
		"xujingdong": {
			StationID: "xujingdong", StationName: "徐泾东", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 3, ElevatorLocation: "地面至站厅2部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "靠近国家会展中心",
		},
		"hongqiao_railway_2": {
			StationID: "hongqiao_railway_2", StationName: "虹桥火车站", LineIDs: []string{"2", "10"},
			HasElevator: true, ElevatorCount: 6, ElevatorLocation: "各出入口及换乘通道均有配置",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站厅层（费区内）及站台层均有",
			HasRestroomInPaid: true, HasRestroomOutside: true,
			HasMotherBabyRoom: true, HasThirdBathroom: true,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "综合交通枢纽，设施最全",
		},
		"hongqiao_t2_2": {
			StationID: "hongqiao_t2_2", StationName: "虹桥2号航站楼", LineIDs: []string{"2", "10"},
			HasElevator: true, ElevatorCount: 4, ElevatorLocation: "各出入口及换乘通道均有配置",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: true, HasThirdBathroom: true,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "航空枢纽配套站",
		},
		"songhong_road": {
			StationID: "songhong_road", StationName: "淞虹路", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: false, RestroomLocation: "站厅层（费区外）",
			HasRestroomInPaid: false, HasRestroomOutside: true,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: false, HasServiceCenter: true, FacilityNote: "",
		},
		"beixinjing": {
			StationID: "beixinjing", StationName: "北新泾", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: false, RestroomLocation: "站厅层（费区外）",
			HasRestroomInPaid: false, HasRestroomOutside: true,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: false, HasServiceCenter: true, FacilityNote: "",
		},
		"weining_road": {
			StationID: "weining_road", StationName: "威宁路", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: false, RestroomLocation: "站厅层（费区外）",
			HasRestroomInPaid: false, HasRestroomOutside: true,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: false, HasServiceCenter: true, FacilityNote: "",
		},
		"loushanguan_road": {
			StationID: "loushanguan_road", StationName: "娄山关路", LineIDs: []string{"2"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: false, RestroomLocation: "站厅层（费区外）",
			HasRestroomInPaid: false, HasRestroomOutside: true,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: false, HasServiceCenter: true, FacilityNote: "",
		},

		// 10号线站点设施 (全为较新线路，设施普遍较好)
		"hongqiao_railway_10": {
			StationID: "hongqiao_railway_10", StationName: "上海虹桥火车站", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 6, ElevatorLocation: "各出入口及换乘通道均有配置",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站厅层（费区内）及站台层均有",
			HasRestroomInPaid: true, HasRestroomOutside: true,
			HasMotherBabyRoom: true, HasThirdBathroom: true,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "综合交通枢纽，设施最全",
		},
		"hongqiao_t1_10": {
			StationID: "hongqiao_t1_10", StationName: "虹桥1号航站楼", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 3, ElevatorLocation: "地面至站厅2部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: true, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "航空枢纽配套站",
		},
		"shanghai_zoo": {
			StationID: "shanghai_zoo", StationName: "上海动物园", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: true, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "10号线新站，设施完善",
		},
		"longxi_road": {
			StationID: "longxi_road", StationName: "龙溪路", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "10号线新站",
		},
		"shuicheng_road": {
			StationID: "shuicheng_road", StationName: "水城路", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "10号线新站",
		},
		"yili_road": {
			StationID: "yili_road", StationName: "伊犁路", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "10号线新站",
		},
		"songyuan_road": {
			StationID: "songyuan_road", StationName: "宋园路", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "10号线新站",
		},
		"hongqiao_road": {
			StationID: "hongqiao_road", StationName: "虹桥路", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "10号线新站",
		},
		"jiaotong_university": {
			StationID: "jiaotong_university", StationName: "交通大学", LineIDs: []string{"10", "11"},
			HasElevator: true, ElevatorCount: 4, ElevatorLocation: "各出入口及换乘通道均有配置",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: true, HasThirdBathroom: true,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "10/11号线换乘站，靠近高校，设施完善",
		},
		"shanghai_library": {
			StationID: "shanghai_library", StationName: "上海图书馆", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "10号线新站",
		},
		"shaanxi_south_road": {
			StationID: "shaanxi_south_road", StationName: "陕西南路", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 3, ElevatorLocation: "地面至站厅2部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "多线换乘站",
		},
		"xin_tian_di": {
			StationID: "xin_tian_di", StationName: "一大会址·新天地", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "靠近新天地商圈",
		},
		"lao_xi_men": {
			StationID: "lao_xi_men", StationName: "老西门", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "10号线新站",
		},
		"yu_yuan": {
			StationID: "yu_yuan", StationName: "豫园", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "豫园景区旁，客流量大",
		},
		"tian_tong_road": {
			StationID: "tian_tong_road", StationName: "天潼路", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "10号线新站",
		},
		"north_sichuan_road": {
			StationID: "north_sichuan_road", StationName: "四川北路", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "10号线新站",
		},
		"hai_lun_road": {
			StationID: "hai_lun_road", StationName: "海伦路", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "10号线新站",
		},
		"si_ping_road": {
			StationID: "si_ping_road", StationName: "四平路", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "10号线新站",
		},
		"tong_ji_university": {
			StationID: "tong_ji_university", StationName: "同济大学", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "靠近同济大学",
		},
		"jiang_wan_new_town": {
			StationID: "jiang_wan_new_town", StationName: "江湾新城", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "10号线新站",
		},
		"weng_jing": {
			StationID: "weng_jing", StationName: "殷高东路", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "10号线新站",
		},
		"xin_jiang_wan_city": {
			StationID: "xin_jiang_wan_city", StationName: "新江湾城", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "10号线终点站",
		},
		"shuang_jiang_road": {
			StationID: "shuang_jiang_road", StationName: "三门路", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "10号线新站",
		},
		"hang_hai_road": {
			StationID: "hang_hai_road", StationName: "殷行路", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "10号线新站",
		},
		"xinquan_road": {
			StationID: "xinquan_road", StationName: "新园路", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "10号线新站",
		},
		"shanghai_north_railway_station": {
			StationID: "shanghai_north_railway_station", StationName: "江湾镇", LineIDs: []string{"10"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "10号线新站",
		},

		// 11号线站点设施 (较新线路)
		"hua_qiao": {
			StationID: "hua_qiao", StationName: "花桥", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "11号线起点站",
		},
		"jiading_new_town": {
			StationID: "jiading_new_town", StationName: "光明路", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "11号线新站",
		},
		"bao_an_road": {
			StationID: "bao_an_road", StationName: "兆丰路", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "11号线新站",
		},
		"anting": {
			StationID: "anting", StationName: "安亭", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "11号线新站",
		},
		"che_ding_zhen": {
			StationID: "che_ding_zhen", StationName: "上海赛车场", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 3, ElevatorLocation: "地面至站厅2部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "F1赛车场配套站",
		},
		"jiading_new_city": {
			StationID: "jiading_new_city", StationName: "嘉定新城", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "11号线新站",
		},
		"jiading_old_town": {
			StationID: "jiading_old_town", StationName: "白银路", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "11号线新站",
		},
		"jiading_beilu": {
			StationID: "jiading_beilu", StationName: "嘉定北", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "11号线新站",
		},
		"nan_xiang": {
			StationID: "nan_xiang", StationName: "南翔", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "11号线新站",
		},
		"ma_lu": {
			StationID: "ma_lu", StationName: "马陆", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "11号线新站",
		},
		"jiang_su_road_11": {
			StationID: "jiang_su_road_11", StationName: "桃浦新村", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "11号线新站",
		},
		"wan_li_road": {
			StationID: "wan_li_road", StationName: "武威路", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "11号线新站",
		},
		"qilian_mountain_road": {
			StationID: "qilian_mountain_road", StationName: "祁连山路", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "11号线新站",
		},
		"caoyang_road": {
			StationID: "caoyang_road", StationName: "曹杨路", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "11号线新站",
		},
		"long_de_road": {
			StationID: "long_de_road", StationName: "隆德路", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "11号线新站",
		},
		"xu_jia_hui": {
			StationID: "xu_jia_hui", StationName: "徐家汇", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 4, ElevatorLocation: "各出入口及换乘通道均有配置",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站厅层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: true, HasThirdBathroom: true,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "多线换乘枢纽，商圈核心",
		},
		"shang_hai_sports": {
			StationID: "shang_hai_sports", StationName: "上海游泳馆", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "11号线新站",
		},
		"zhi_pu_road": {
			StationID: "zhi_pu_road", StationName: "肇嘉浜路", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "11号线新站",
		},
		"yuyao_road": {
			StationID: "yuyao_road", StationName: "宜山路", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 3, ElevatorLocation: "地面至站厅2部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "11号线新站",
		},
		"long_hua": {
			StationID: "long_hua", StationName: "龙华", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "靠近龙华寺景区",
		},
		"long_hua_middle": {
			StationID: "long_hua_middle", StationName: "龙华中路", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "11号线新站",
		},
		"lu_jia_bang_road": {
			StationID: "lu_jia_bang_road", StationName: "龙耀路", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "11号线新站",
		},
		"huating_road": {
			StationID: "huating_road", StationName: "云锦路", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "11号线新站",
		},
		"long_arcs": {
			StationID: "long_arcs", StationName: "龙腾大道", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "11号线新站",
		},
		"pujiang_zhen": {
			StationID: "pujiang_zhen", StationName: "东方体育中心", LineIDs: []string{"11"},
			HasElevator: true, ElevatorCount: 3, ElevatorLocation: "地面至站厅2部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "大型体育场馆配套站",
		},

		// 其他站点
		"huaihai_mid_road": {
			StationID: "huaihai_mid_road", StationName: "淮海中路", LineIDs: []string{"13"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "",
		},
		"shanghai_south_railway_station": {
			StationID: "shanghai_south_railway_station", StationName: "上海南站", LineIDs: []string{"1", "3", "15"},
			HasElevator: true, ElevatorCount: 5, ElevatorLocation: "各出入口及换乘通道均有配置",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站厅层（费区内）及站台层均有",
			HasRestroomInPaid: true, HasRestroomOutside: true,
			HasMotherBabyRoom: true, HasThirdBathroom: true,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "铁路枢纽配套站，设施完善",
		},
		"shanghai_railway_station": {
			StationID: "shanghai_railway_station", StationName: "上海火车站", LineIDs: []string{"1", "3", "4"},
			HasElevator: true, ElevatorCount: 5, ElevatorLocation: "各出入口及换乘通道均有配置",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站厅层（费区内）及站台层均有",
			HasRestroomInPaid: true, HasRestroomOutside: true,
			HasMotherBabyRoom: true, HasThirdBathroom: true,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "铁路枢纽配套站，设施完善",
		},
		"caohexi_kfq": {
			StationID: "caohexi_kfq", StationName: "漕河泾开发区", LineIDs: []string{"9"},
			HasElevator: true, ElevatorCount: 2, ElevatorLocation: "地面至站厅1部，站厅至站台1部",
			HasEscalator: true, HasAccessibleRestroom: true, RestroomLocation: "站台层（费区内）",
			HasRestroomInPaid: true, HasRestroomOutside: false,
			HasMotherBabyRoom: false, HasThirdBathroom: false,
			HasWheelchairRamp: true, HasWideGate: true, HasBlindPath: true,
			HasAED: true, HasServiceCenter: true, FacilityNote: "9号线车站",
		},
	}

	return facilities[stationID]
}

func FindStationByID(stationID string) (models.Station, error) {
	stations := map[string]models.Station{
		"pudong_airport":                 {ID: 1, StationID: "pudong_airport", StationName: "浦东国际机场", City: "上海", StationType: "地铁站"},
		"yuanshen":                       {ID: 2, StationID: "yuanshen", StationName: "远东大道", City: "上海", StationType: "地铁站"},
		"lingkong":                       {ID: 3, StationID: "lingkong", StationName: "凌空路", City: "上海", StationType: "地铁站"},
		"huaxia":                         {ID: 4, StationID: "huaxia", StationName: "华夏东路", City: "上海", StationType: "地铁站"},
		"chuansha":                       {ID: 5, StationID: "chuansha", StationName: "川沙", City: "上海", StationType: "地铁站"},
		"shenjiang":                      {ID: 6, StationID: "shenjiang", StationName: "华夏镇", City: "上海", StationType: "地铁站"},
		"shanghai_race_track":            {ID: 7, StationID: "shanghai_race_track", StationName: "创新中路", City: "上海", StationType: "地铁站"},
		"guanglan_road":                  {ID: 8, StationID: "guanglan_road", StationName: "广兰路", City: "上海", StationType: "地铁站"},
		"tianzhu_road":                   {ID: 9, StationID: "tianzhu_road", StationName: "唐镇", City: "上海", StationType: "地铁站"},
		"jinqiao_road":                   {ID: 10, StationID: "jinqiao_road", StationName: "创新路", City: "上海", StationType: "地铁站"},
		"jinyang_road":                   {ID: 11, StationID: "jinyang_road", StationName: "金科路", City: "上海", StationType: "地铁站"},
		"zhangjiang_high_tech":           {ID: 12, StationID: "zhangjiang_high_tech", StationName: "张江高科", City: "上海", StationType: "地铁站"},
		"longyang_road_2":                {ID: 13, StationID: "longyang_road_2", StationName: "龙阳路", City: "上海", StationType: "地铁站"},
		"shanghai_science_tech":          {ID: 14, StationID: "shanghai_science_tech", StationName: "上海科技馆", City: "上海", StationType: "地铁站"},
		"Century_Avenue":                 {ID: 15, StationID: "Century_Avenue", StationName: "世纪大道", City: "上海", StationType: "地铁站"},
		"dongchang_road":                 {ID: 16, StationID: "dongchang_road", StationName: "东昌路", City: "上海", StationType: "地铁站"},
		"lujiazui":                       {ID: 17, StationID: "lujiazui", StationName: "陆家嘴", City: "上海", StationType: "地铁站"},
		"dongbei_road":                   {ID: 18, StationID: "dongbei_road", StationName: "东门路", City: "上海", StationType: "地铁站"},
		"nanjing_east_road":              {ID: 19, StationID: "nanjing_east_road", StationName: "南京东路", City: "上海", StationType: "地铁站"},
		"renmin_square":                  {ID: 20, StationID: "renmin_square", StationName: "人民广场", City: "上海", StationType: "地铁站"},
		"shimen_road":                    {ID: 21, StationID: "shimen_road", StationName: "石门一路", City: "上海", StationType: "地铁站"},
		"jingan_temple":                  {ID: 22, StationID: "jingan_temple", StationName: "静安寺", City: "上海", StationType: "地铁站"},
		"west_nan_jing_road":             {ID: 23, StationID: "west_nan_jing_road", StationName: "南京西路", City: "上海", StationType: "地铁站"},
		"jiangsu_road":                   {ID: 25, StationID: "jiangsu_road", StationName: "江苏路", City: "上海", StationType: "地铁站"},
		"zhongshan_park":                 {ID: 26, StationID: "zhongshan_park", StationName: "中山公园", City: "上海", StationType: "地铁站"},
		"longxu_road":                    {ID: 27, StationID: "longxu_road", StationName: "龙漕路", City: "上海", StationType: "地铁站"},
		"caobao_road":                    {ID: 28, StationID: "caobao_road", StationName: "漕宝路", City: "上海", StationType: "地铁站"},
		"xujingdong":                     {ID: 29, StationID: "xujingdong", StationName: "徐泾东", City: "上海", StationType: "地铁站"},
		"hongqiao_railway_2":             {ID: 30, StationID: "hongqiao_railway_2", StationName: "虹桥火车站", City: "上海", StationType: "地铁站"},
		"hongqiao_t2_2":                  {ID: 31, StationID: "hongqiao_t2_2", StationName: "虹桥2号航站楼", City: "上海", StationType: "地铁站"},
		"songhong_road":                  {ID: 32, StationID: "songhong_road", StationName: "淞虹路", City: "上海", StationType: "地铁站"},
		"beixinjing":                     {ID: 33, StationID: "beixinjing", StationName: "北新泾", City: "上海", StationType: "地铁站"},
		"weining_road":                   {ID: 34, StationID: "weining_road", StationName: "威宁路", City: "上海", StationType: "地铁站"},
		"loushanguan_road":               {ID: 35, StationID: "loushanguan_road", StationName: "娄山关路", City: "上海", StationType: "地铁站"},
		"hongqiao_railway_10":            {ID: 36, StationID: "hongqiao_railway_10", StationName: "上海虹桥火车站", City: "上海", StationType: "地铁站"},
		"hongqiao_t1_10":                 {ID: 37, StationID: "hongqiao_t1_10", StationName: "虹桥1号航站楼", City: "上海", StationType: "地铁站"},
		"shanghai_zoo":                   {ID: 38, StationID: "shanghai_zoo", StationName: "上海动物园", City: "上海", StationType: "地铁站"},
		"longxi_road":                    {ID: 39, StationID: "longxi_road", StationName: "龙溪路", City: "上海", StationType: "地铁站"},
		"shuicheng_road":                 {ID: 40, StationID: "shuicheng_road", StationName: "水城路", City: "上海", StationType: "地铁站"},
		"yili_road":                      {ID: 41, StationID: "yili_road", StationName: "伊犁路", City: "上海", StationType: "地铁站"},
		"songyuan_road":                  {ID: 42, StationID: "songyuan_road", StationName: "宋园路", City: "上海", StationType: "地铁站"},
		"hongqiao_road":                  {ID: 43, StationID: "hongqiao_road", StationName: "虹桥路", City: "上海", StationType: "地铁站"},
		"jiaotong_university":            {ID: 44, StationID: "jiaotong_university", StationName: "交通大学", City: "上海", StationType: "地铁站"},
		"shanghai_library":               {ID: 45, StationID: "shanghai_library", StationName: "上海图书馆", City: "上海", StationType: "地铁站"},
		"shaanxi_south_road":             {ID: 46, StationID: "shaanxi_south_road", StationName: "陕西南路", City: "上海", StationType: "地铁站"},
		"xin_tian_di":                    {ID: 47, StationID: "xin_tian_di", StationName: "一大会址·新天地", City: "上海", StationType: "地铁站"},
		"lao_xi_men":                     {ID: 48, StationID: "lao_xi_men", StationName: "老西门", City: "上海", StationType: "地铁站"},
		"yu_yuan":                        {ID: 49, StationID: "yu_yuan", StationName: "豫园", City: "上海", StationType: "地铁站"},
		"tian_tong_road":                 {ID: 50, StationID: "tian_tong_road", StationName: "天潼路", City: "上海", StationType: "地铁站"},
		"north_sichuan_road":             {ID: 51, StationID: "north_sichuan_road", StationName: "四川北路", City: "上海", StationType: "地铁站"},
		"hai_lun_road":                   {ID: 52, StationID: "hai_lun_road", StationName: "海伦路", City: "上海", StationType: "地铁站"},
		"si_ping_road":                   {ID: 53, StationID: "si_ping_road", StationName: "四平路", City: "上海", StationType: "地铁站"},
		"tong_ji_university":             {ID: 54, StationID: "tong_ji_university", StationName: "同济大学", City: "上海", StationType: "地铁站"},
		"jiang_wan_new_town":             {ID: 55, StationID: "jiang_wan_new_town", StationName: "江湾新城", City: "上海", StationType: "地铁站"},
		"weng_jing":                      {ID: 56, StationID: "weng_jing", StationName: "殷高东路", City: "上海", StationType: "地铁站"},
		"xin_jiang_wan_city":             {ID: 57, StationID: "xin_jiang_wan_city", StationName: "新江湾城", City: "上海", StationType: "地铁站"},
		"shuang_jiang_road":              {ID: 58, StationID: "shuang_jiang_road", StationName: "三门路", City: "上海", StationType: "地铁站"},
		"hang_hai_road":                  {ID: 59, StationID: "hang_hai_road", StationName: "殷行路", City: "上海", StationType: "地铁站"},
		"xinquan_road":                   {ID: 60, StationID: "xinquan_road", StationName: "新园路", City: "上海", StationType: "地铁站"},
		"shanghai_north_railway_station": {ID: 61, StationID: "shanghai_north_railway_station", StationName: "江湾镇", City: "上海", StationType: "地铁站"},
		"hua_qiao":                       {ID: 62, StationID: "hua_qiao", StationName: "花桥", City: "上海", StationType: "地铁站"},
		"jiading_new_town":               {ID: 63, StationID: "jiading_new_town", StationName: "光明路", City: "上海", StationType: "地铁站"},
		"bao_an_road":                    {ID: 64, StationID: "bao_an_road", StationName: "兆丰路", City: "上海", StationType: "地铁站"},
		"anting":                         {ID: 65, StationID: "anting", StationName: "安亭", City: "上海", StationType: "地铁站"},
		"che_ding_zhen":                  {ID: 66, StationID: "che_ding_zhen", StationName: "上海赛车场", City: "上海", StationType: "地铁站"},
		"jiading_new_city":               {ID: 67, StationID: "jiading_new_city", StationName: "嘉定新城", City: "上海", StationType: "地铁站"},
		"jiading_old_town":               {ID: 68, StationID: "jiading_old_town", StationName: "白银路", City: "上海", StationType: "地铁站"},
		"jiading_beilu":                  {ID: 69, StationID: "jiading_beilu", StationName: "嘉定北", City: "上海", StationType: "地铁站"},
		"nan_xiang":                      {ID: 70, StationID: "nan_xiang", StationName: "南翔", City: "上海", StationType: "地铁站"},
		"ma_lu":                          {ID: 71, StationID: "ma_lu", StationName: "马陆", City: "上海", StationType: "地铁站"},
		"jiang_su_road_11":               {ID: 72, StationID: "jiang_su_road_11", StationName: "桃浦新村", City: "上海", StationType: "地铁站"},
		"wan_li_road":                    {ID: 73, StationID: "wan_li_road", StationName: "武威路", City: "上海", StationType: "地铁站"},
		"qilian_mountain_road":           {ID: 74, StationID: "qilian_mountain_road", StationName: "祁连山路", City: "上海", StationType: "地铁站"},
		"caoyang_road":                   {ID: 75, StationID: "caoyang_road", StationName: "曹杨路", City: "上海", StationType: "地铁站"},
		"long_de_road":                   {ID: 76, StationID: "long_de_road", StationName: "隆德路", City: "上海", StationType: "地铁站"},
		"xu_jia_hui":                     {ID: 77, StationID: "xu_jia_hui", StationName: "徐家汇", City: "上海", StationType: "地铁站"},
		"shang_hai_sports":               {ID: 78, StationID: "shang_hai_sports", StationName: "上海游泳馆", City: "上海", StationType: "地铁站"},
		"zhi_pu_road":                    {ID: 79, StationID: "zhi_pu_road", StationName: "肇嘉浜路", City: "上海", StationType: "地铁站"},
		"yuyao_road":                     {ID: 80, StationID: "yuyao_road", StationName: "宜山路", City: "上海", StationType: "地铁站"},
		"long_hua":                       {ID: 81, StationID: "long_hua", StationName: "龙华", City: "上海", StationType: "地铁站"},
		"long_hua_middle":                {ID: 82, StationID: "long_hua_middle", StationName: "龙华中路", City: "上海", StationType: "地铁站"},
		"lu_jia_bang_road":               {ID: 83, StationID: "lu_jia_bang_road", StationName: "龙耀路", City: "上海", StationType: "地铁站"},
		"huating_road":                   {ID: 84, StationID: "huating_road", StationName: "云锦路", City: "上海", StationType: "地铁站"},
		"long_arcs":                      {ID: 85, StationID: "long_arcs", StationName: "龙腾大道", City: "上海", StationType: "地铁站"},
		"pujiang_zhen":                   {ID: 86, StationID: "pujiang_zhen", StationName: "东方体育中心", City: "上海", StationType: "地铁站"},
		"huaihai_mid_road":               {ID: 87, StationID: "huaihai_mid_road", StationName: "淮海中路", City: "上海", StationType: "地铁站"},
		"shanghai_south_railway_station": {ID: 88, StationID: "shanghai_south_railway_station", StationName: "上海南站", City: "上海", StationType: "地铁站"},
		"shanghai_railway_station":       {ID: 89, StationID: "shanghai_railway_station", StationName: "上海火车站", City: "上海", StationType: "地铁站"},
		"caohexi_kfq":                    {ID: 90, StationID: "caohexi_kfq", StationName: "漕河泾开发区", City: "上海", StationType: "地铁站"},
	}
	if s, ok := stations[stationID]; ok {
		return s, nil
	}
	return models.Station{}, fmt.Errorf("未找到站点: %s", stationID)
}

func GetStationLineNames(stationID string) []string {
	info := getFacilityByID(stationID)
	if info == nil {
		return nil
	}
	return info.LineIDs
}

func GetAllStationFacilities() []*StationFacilityInfo {
	facilities := getFacilityByID("")
	_ = facilities
	var result []*StationFacilityInfo
	for _, v := range getAllFacilities() {
		result = append(result, v)
	}
	return result
}

func getAllFacilities() map[string]*StationFacilityInfo {
	info := getFacilityByID("renmin_square")
	if info != nil {
		return allFacilitiesMap
	}
	return nil
}

var allFacilitiesMap = buildAllFacilities()

func buildAllFacilities() map[string]*StationFacilityInfo {
	result := make(map[string]*StationFacilityInfo)
	ids := []string{
		"pudong_airport", "yuanshen", "lingkong", "huaxia", "chuansha",
		"shenjiang", "shanghai_race_track", "guanglan_road", "tianzhu_road", "jinqiao_road",
		"jinyang_road", "zhangjiang_high_tech", "longyang_road_2", "shanghai_science_tech", "Century_Avenue",
		"dongchang_road", "lujiazui", "dongbei_road", "nanjing_east_road", "renmin_square",
		"shimen_road", "jingan_temple", "west_nan_jing_road", "jiangsu_road", "zhongshan_park",
		"longxu_road", "caobao_road", "xujingdong", "hongqiao_railway_2", "hongqiao_t2_2",
		"songhong_road", "beixinjing", "weining_road", "loushanguan_road",
		"hongqiao_railway_10", "hongqiao_t1_10", "shanghai_zoo", "longxi_road", "shuicheng_road",
		"yili_road", "songyuan_road", "hongqiao_road", "jiaotong_university", "shanghai_library",
		"shaanxi_south_road", "xin_tian_di", "lao_xi_men", "yu_yuan", "tian_tong_road",
		"north_sichuan_road", "hai_lun_road", "si_ping_road", "tong_ji_university",
		"jiang_wan_new_town", "weng_jing", "xin_jiang_wan_city", "shuang_jiang_road",
		"hang_hai_road", "xinquan_road", "shanghai_north_railway_station",
		"hua_qiao", "jiading_new_town", "bao_an_road", "anting", "che_ding_zhen",
		"jiading_new_city", "jiading_old_town", "jiading_beilu", "nan_xiang", "ma_lu",
		"jiang_su_road_11", "wan_li_road", "qilian_mountain_road", "caoyang_road", "long_de_road",
		"xu_jia_hui", "shang_hai_sports", "zhi_pu_road", "yuyao_road", "long_hua",
		"long_hua_middle", "lu_jia_bang_road", "huating_road", "long_arcs", "pujiang_zhen",
		"huaihai_mid_road", "shanghai_south_railway_station", "shanghai_railway_station", "caohexi_kfq",
	}
	for _, id := range ids {
		if f := getFacilityByID(id); f != nil {
			result[id] = f
		}
	}
	return result
}
