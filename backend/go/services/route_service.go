package services

import (
	"fmt"
	"math"
	"strings"

	"smart-travel-backend/database"
	"smart-travel-backend/models"
)

type RouteSegment struct {
	Type        string `json:"type"`
	Line        string `json:"line"`
	Description string `json:"description"`
	Time        string `json:"time"`
	Distance    string `json:"distance,omitempty"`
	Stops       int    `json:"stops,omitempty"`
	Color       string `json:"color,omitempty"`
}

type PlannedRoute struct {
	RouteID        string         `json:"routeId"`
	Title          string         `json:"title"`
	TotalTime      int            `json:"totalTime"`
	Time           string         `json:"time"`
	Transfers      int            `json:"transfers"`
	Description    string         `json:"description"`
	Segments       []RouteSegment `json:"segments"`
	StartStationID string         `json:"startStationId,omitempty"`
	EndStationID   string         `json:"endStationId,omitempty"`
	FacilityReport string         `json:"facilityReport,omitempty"`
	Score          float64        `json:"score,omitempty"`
	AIAdvice       string         `json:"aiAdvice,omitempty"`
}

type RoutePlanResult struct {
	Success bool           `json:"success"`
	Error   string         `json:"error,omitempty"`
	Routes  []PlannedRoute `json:"routes"`
}

type RouteScore struct {
	Route  PlannedRoute
	Score  float64
	Reason string
}

func PlanRoute(startName, endName string) (RoutePlanResult, error) {
	return PlanRouteWithAI(startName, endName, nil)
}

func PlanRouteWithAI(startName, endName string, preferences map[string]interface{}) (RoutePlanResult, error) {
	startStation, err := findStation(startName)
	if err != nil {
		return RoutePlanResult{Success: false, Error: "未找到起点站点"}, nil
	}

	endStation, err := findStation(endName)
	if err != nil {
		return RoutePlanResult{Success: false, Error: "未找到终点站点"}, nil
	}

	routes, err := findRoutes(startStation, endStation)
	if err != nil {
		return RoutePlanResult{Success: false, Error: "路线规划失败", Routes: []PlannedRoute{}}, nil
	}

	if len(routes) == 0 {
		return RoutePlanResult{Success: true, Routes: []PlannedRoute{}}, nil
	}

	if preferences == nil {
		if len(routes) > 3 {
			routes = routes[:3]
		}
		finalizePlannedRoutes(routes)
		return RoutePlanResult{
			Success: true,
			Routes:  routes,
		}, nil
	}

	scores := scoreRoutesWithAI(routes, preferences)
	finalizePlannedRoutes(scores)

	return RoutePlanResult{
		Success: true,
		Routes:  scores,
	}, nil
}

func finalizePlannedRoutes(routes []PlannedRoute) {
	for i := range routes {
		if routes[i].RouteID == "" {
			routes[i].RouteID = fmt.Sprintf("route_%d", i+1)
		}
		if routes[i].AIAdvice == "" {
			routes[i].AIAdvice = strings.TrimPrefix(routes[i].Description, "AI 分析：")
			routes[i].AIAdvice = strings.TrimPrefix(routes[i].AIAdvice, "AI 推荐：")
		}
		if routes[i].Score == 0 {
			routes[i].Score = math.Max(60, 100-float64(routes[i].Transfers*8)-float64(routes[i].TotalTime)*0.6)
		}
	}
}

func isRouteEligible(route PlannedRoute, mobilityPrefs, luggagePrefs map[string]interface{}) bool {
	needElevator := getBool(mobilityPrefs, "needElevator")
	avoidStairs := getBool(mobilityPrefs, "avoidStairs")
	maxWalking := getInt(mobilityPrefs, "maxWalkingDistance")
	mobilityLevel := getString(mobilityPrefs, "mobilityLevel")

	if needElevator || avoidStairs {
		for _, seg := range route.Segments {
			if seg.Type == "walk" && seg.Distance != "" {
				dist := parseDistance(seg.Distance)
				if dist > maxWalking {
					return false
				}
			}
		}
	}

	if mobilityLevel == "wheelchair" || needElevator {
		if route.StartStationID != "" && !IsStationAccessible(route.StartStationID) {
			return false
		}
		if route.EndStationID != "" && !IsStationAccessible(route.EndStationID) {
			return false
		}
	}

	return true
}

func calculateAIScore(route PlannedRoute, travelPrefs, mobilityPrefs, luggagePrefs map[string]interface{}) (float64, string) {
	score := 100.0
	reason := ""

	preferFastest := getBool(travelPrefs, "preferFastestRoute")
	preferLessTransfers := getBool(travelPrefs, "preferLessTransfers")
	preferLessWalking := getBool(travelPrefs, "preferLessWalking")
	avoidCrowded := getBool(travelPrefs, "avoidCrowdedLines")
	routeType := getString(travelPrefs, "preferredRouteType")

	mobility := getString(mobilityPrefs, "mobilityLevel")
	needElevator := getBool(mobilityPrefs, "needElevator")
	hasLuggage := getBool(luggagePrefs, "hasLuggage")
	luggageSize := getString(luggagePrefs, "luggageSize")

	switch routeType {
	case "fastest":
		preferFastest = true
	case "least_transfer":
		preferLessTransfers = true
	case "least_walking":
		preferLessWalking = true
	}

	timeScore := 100.0
	if route.TotalTime > 0 {
		timeScore = math.Max(0, 100-float64(route.TotalTime)*0.8)
	}
	if preferFastest {
		score += timeScore * 1.5
		reason += fmt.Sprintf("用时%d分钟，", route.TotalTime)
	} else {
		score += timeScore * 0.8
		reason += fmt.Sprintf("用时%d分钟，", route.TotalTime)
	}

	transferScore := 100.0
	if route.Transfers == 0 {
		transferScore = 100
	} else {
		transferScore = math.Max(0, 100-float64(route.Transfers)*30)
	}
	if preferLessTransfers {
		score += transferScore * 1.5
		if route.Transfers == 0 {
			reason += "无需换乘，直达路线，"
		} else {
			reason += fmt.Sprintf("需%d次换乘，", route.Transfers)
		}
	} else {
		score += transferScore * 0.5
	}

	walkingScore := 100.0
	if preferLessWalking || mobility == "wheelchair" || mobility == "limited" {
		totalWalk := 0
		for _, seg := range route.Segments {
			if seg.Type == "walk" {
				totalWalk += parseDistance(seg.Distance)
			}
		}
		walkingScore = math.Max(0, 100-float64(totalWalk)*0.2)
		score += walkingScore * 1.2
		if totalWalk < 200 {
			reason += "步行距离短，"
		} else {
			reason += fmt.Sprintf("步行约%d米，", totalWalk)
		}
	}

	if avoidCrowded {
		if route.Transfers == 0 {
			score += 15
			reason += "直达避开拥挤换乘站，"
		}
	}

	if mobility == "wheelchair" || needElevator {
		startAccessible := route.StartStationID != "" && IsStationAccessible(route.StartStationID)
		endAccessible := route.EndStationID != "" && IsStationAccessible(route.EndStationID)
		startWheelchair := route.StartStationID != "" && IsWheelchairFriendly(route.StartStationID)
		endWheelchair := route.EndStationID != "" && IsWheelchairFriendly(route.EndStationID)

		if startAccessible && endAccessible {
			if route.Transfers == 0 {
				score += 30
				reason += "全程无障碍通道，"
			} else {
				score += 20
				reason += "起终点无障碍设施完备，"
			}
		} else if startAccessible || endAccessible {
			score += 10
			reason += "部分站点无障碍可用，"
		} else {
			score -= 40
			reason += "⚠️站点无障碍设施不完善，"
		}

		if startWheelchair && endWheelchair {
			score += 10
			reason += "轮椅友好，"
		}
	}

	startFacility := getFacilityByID(route.StartStationID)
	endFacility := getFacilityByID(route.EndStationID)
	if startFacility != nil && endFacility != nil {
		facilityNotes := []string{}
		if startFacility.HasMotherBabyRoom {
			facilityNotes = append(facilityNotes, fmt.Sprintf("%s有母婴室", startFacility.StationName))
		}
		if endFacility.HasMotherBabyRoom {
			facilityNotes = append(facilityNotes, fmt.Sprintf("%s有母婴室", endFacility.StationName))
		}
		if startFacility.HasThirdBathroom {
			facilityNotes = append(facilityNotes, fmt.Sprintf("%s有第三卫生间", startFacility.StationName))
		}
		if endFacility.HasThirdBathroom {
			facilityNotes = append(facilityNotes, fmt.Sprintf("%s有第三卫生间", endFacility.StationName))
		}
		if startFacility.HasAED || endFacility.HasAED {
			facilityNotes = append(facilityNotes, "配备AED急救设备")
			score += 5
			reason += "配备AED，"
		}
		if startFacility.HasServiceCenter || endFacility.HasServiceCenter {
			score += 3
		}
	}

	if hasLuggage {
		if route.Transfers == 0 {
			score += 10
			reason += "适合携带行李，"
		}
		if luggageSize == "large" {
			if route.Transfers > 1 {
				score -= 20
				reason += "大件行李建议少换乘，"
			}
		}
		if route.Transfers == 0 {
			if startFacility != nil && startFacility.ElevatorCount >= 3 && endFacility != nil && endFacility.ElevatorCount >= 3 {
				score += 8
				reason += "多部电梯便于行李通行，"
			}
		}
	}

	reason = "此路线" + reason + "综合评分最优。"

	return score, reason
}

func sortRoutesByScore(scored []RouteScore) {
	for i := 0; i < len(scored)-1; i++ {
		for j := i + 1; j < len(scored); j++ {
			if scored[i].Score < scored[j].Score {
				scored[i], scored[j] = scored[j], scored[i]
			}
		}
	}
}

func getMap(m map[string]interface{}, key string) map[string]interface{} {
	if m == nil {
		return nil
	}
	if val, ok := m[key].(map[string]interface{}); ok {
		return val
	}
	return nil
}

func getBool(m map[string]interface{}, key string) bool {
	if m == nil {
		return false
	}
	if val, ok := m[key].(bool); ok {
		return val
	}
	return false
}

func getBoolWithDefault(m map[string]interface{}, key string, defaultValue bool) bool {
	if m == nil {
		return defaultValue
	}
	if val, ok := m[key].(bool); ok {
		return val
	}
	return defaultValue
}

func getInt(m map[string]interface{}, key string) int {
	if m == nil {
		return 0
	}
	if val, ok := m[key].(float64); ok {
		return int(val)
	}
	if val, ok := m[key].(int); ok {
		return val
	}
	return 0
}

func getIntWithDefault(m map[string]interface{}, key string, defaultValue int) int {
	if m == nil {
		return defaultValue
	}
	if val, ok := m[key].(float64); ok {
		return int(val)
	}
	if val, ok := m[key].(int); ok {
		return val
	}
	return defaultValue
}

func getString(m map[string]interface{}, key string) string {
	if m == nil {
		return ""
	}
	if val, ok := m[key].(string); ok {
		return val
	}
	return ""
}

func getStringWithDefault(m map[string]interface{}, key string, defaultValue string) string {
	if m == nil {
		return defaultValue
	}
	if val, ok := m[key].(string); ok {
		return val
	}
	return defaultValue
}

func parseDistance(dist string) int {
	var meters int
	fmt.Sscanf(dist, "%dm", &meters)
	return meters
}

func findStation(name string) (models.Station, error) {
	fmt.Printf("[DEBUG-findStation] 查找站点: %s, DB是否为nil: %v\n", name, database.DB == nil)
	if database.DB != nil {
		var station models.Station
		err := database.DB.QueryRow(
			"SELECT * FROM stations WHERE station_name LIKE ? OR station_alias LIKE ? LIMIT 1",
			"%"+name+"%", "%"+name+"%",
		).Scan(
			&station.ID, &station.StationID, &station.StationName,
			&station.StationAlias, &station.City, &station.District,
			&station.StationType, &station.Description,
		)
		if err == nil {
			return station, nil
		}
		fmt.Printf("[DEBUG-findStation] 数据库未找到站点，降级使用模拟站点: %v\n", err)
	}

	// 模拟数据 - 当前首页简图覆盖的线路和换乘参考站
	stations := map[string]models.Station{
		// 2号线站点
		"浦东国际机场":  {ID: 1, StationID: "pudong_airport", StationName: "浦东国际机场", City: "上海", StationType: "地铁站"},
		"远东大道":    {ID: 2, StationID: "yuanshen", StationName: "远东大道", City: "上海", StationType: "地铁站"},
		"凌空路":     {ID: 3, StationID: "lingkong", StationName: "凌空路", City: "上海", StationType: "地铁站"},
		"华夏东路":    {ID: 4, StationID: "huaxia", StationName: "华夏东路", City: "上海", StationType: "地铁站"},
		"川沙":      {ID: 5, StationID: "chuansha", StationName: "川沙", City: "上海", StationType: "地铁站"},
		"华夏镇":     {ID: 6, StationID: "shenjiang", StationName: "华夏镇", City: "上海", StationType: "地铁站"},
		"创新中路":    {ID: 7, StationID: "shanghai_race_track", StationName: "创新中路", City: "上海", StationType: "地铁站"},
		"广兰路":     {ID: 8, StationID: "guanglan_road", StationName: "广兰路", City: "上海", StationType: "地铁站"},
		"唐镇":      {ID: 9, StationID: "tianzhu_road", StationName: "唐镇", City: "上海", StationType: "地铁站"},
		"创新路":     {ID: 10, StationID: "jinqiao_road", StationName: "创新路", City: "上海", StationType: "地铁站"},
		"金科路":     {ID: 11, StationID: "jinyang_road", StationName: "金科路", City: "上海", StationType: "地铁站"},
		"张江高科":    {ID: 12, StationID: "zhangjiang_high_tech", StationName: "张江高科", City: "上海", StationType: "地铁站"},
		"龙阳路":     {ID: 13, StationID: "longyang_road_2", StationName: "龙阳路", City: "上海", StationType: "地铁站"},
		"上海科技馆":   {ID: 14, StationID: "shanghai_science_tech", StationName: "上海科技馆", City: "上海", StationType: "地铁站"},
		"世纪大道":    {ID: 15, StationID: "Century_Avenue", StationName: "世纪大道", City: "上海", StationType: "地铁站"},
		"东昌路":     {ID: 16, StationID: "dongchang_road", StationName: "东昌路", City: "上海", StationType: "地铁站"},
		"陆家嘴":     {ID: 17, StationID: "lujiazui", StationName: "陆家嘴", City: "上海", StationType: "地铁站"},
		"东门路":     {ID: 18, StationID: "dongbei_road", StationName: "东门路", City: "上海", StationType: "地铁站"},
		"南京东路":    {ID: 19, StationID: "nanjing_east_road", StationName: "南京东路", City: "上海", StationType: "地铁站"},
		"人民广场":    {ID: 20, StationID: "renmin_square", StationName: "人民广场", City: "上海", StationType: "地铁站"},
		"石门一路":    {ID: 21, StationID: "shimen_road", StationName: "石门一路", City: "上海", StationType: "地铁站"},
		"静安寺":     {ID: 22, StationID: "jingan_temple", StationName: "静安寺", City: "上海", StationType: "地铁站"},
		"南京西路":    {ID: 23, StationID: "west_nan_jing_road", StationName: "南京西路", City: "上海", StationType: "地铁站"},
		"江苏路":     {ID: 25, StationID: "jiangsu_road", StationName: "江苏路", City: "上海", StationType: "地铁站"},
		"中山公园":    {ID: 26, StationID: "zhongshan_park", StationName: "中山公园", City: "上海", StationType: "地铁站"},
		"龙漕路":     {ID: 27, StationID: "longxu_road", StationName: "龙漕路", City: "上海", StationType: "地铁站"},
		"漕宝路":     {ID: 28, StationID: "caobao_road", StationName: "漕宝路", City: "上海", StationType: "地铁站"},
		"徐泾东":     {ID: 29, StationID: "xujingdong", StationName: "徐泾东", City: "上海", StationType: "地铁站"},
		"富锦路":     {ID: 107, StationID: "fujin_road", StationName: "富锦路", City: "上海", StationType: "地铁站"},
		"友谊西路":    {ID: 108, StationID: "west_youyi_road", StationName: "友谊西路", City: "上海", StationType: "地铁站"},
		"宝安公路":    {ID: 109, StationID: "baoan_highway", StationName: "宝安公路", City: "上海", StationType: "地铁站"},
		"共富新村":    {ID: 110, StationID: "gongfu_xincun", StationName: "共富新村", City: "上海", StationType: "地铁站"},
		"呼兰路":     {ID: 111, StationID: "hulan_road", StationName: "呼兰路", City: "上海", StationType: "地铁站"},
		"通河新村":    {ID: 112, StationID: "tonghe_xincun", StationName: "通河新村", City: "上海", StationType: "地铁站"},
		"共康路":     {ID: 113, StationID: "gongkang_road", StationName: "共康路", City: "上海", StationType: "地铁站"},
		"彭浦新村":    {ID: 114, StationID: "pengpu_xincun", StationName: "彭浦新村", City: "上海", StationType: "地铁站"},
		"汶水路":     {ID: 115, StationID: "wenshui_road", StationName: "汶水路", City: "上海", StationType: "地铁站"},
		"上海马戏城":   {ID: 116, StationID: "shanghai_circus_world", StationName: "上海马戏城", City: "上海", StationType: "地铁站"},
		"延长路":     {ID: 117, StationID: "yanchang_road", StationName: "延长路", City: "上海", StationType: "地铁站"},
		"中山北路":    {ID: 118, StationID: "north_zhongshan_road", StationName: "中山北路", City: "上海", StationType: "地铁站"},
		"汉中路":     {ID: 119, StationID: "hanzhong_road", StationName: "汉中路", City: "上海", StationType: "地铁站"},
		"新闸路":     {ID: 120, StationID: "xinzha_road", StationName: "新闸路", City: "上海", StationType: "地铁站"},
		"衡山路":     {ID: 121, StationID: "hengshan_road", StationName: "衡山路", City: "上海", StationType: "地铁站"},
		"上海体育馆":   {ID: 122, StationID: "shanghai_indoor_stadium", StationName: "上海体育馆", City: "上海", StationType: "地铁站"},
		"锦江乐园":    {ID: 123, StationID: "jinjiang_park", StationName: "锦江乐园", City: "上海", StationType: "地铁站"},
		"莲花路":     {ID: 124, StationID: "lianhua_road", StationName: "莲花路", City: "上海", StationType: "地铁站"},
		"外环路":     {ID: 125, StationID: "waihuanlu", StationName: "外环路", City: "上海", StationType: "地铁站"},
		"莘庄":      {ID: 126, StationID: "xinzhuang", StationName: "莘庄", City: "上海", StationType: "地铁站"},
		"虹桥火车站":   {ID: 30, StationID: "hongqiao_railway_2", StationName: "虹桥火车站", City: "上海", StationType: "地铁站"},
		"虹桥2号航站楼": {ID: 31, StationID: "hongqiao_t2_2", StationName: "虹桥2号航站楼", City: "上海", StationType: "地铁站"},
		"淞虹路":     {ID: 32, StationID: "songhong_road", StationName: "淞虹路", City: "上海", StationType: "地铁站"},
		"北新泾":     {ID: 33, StationID: "beixinjing", StationName: "北新泾", City: "上海", StationType: "地铁站"},
		"威宁路":     {ID: 34, StationID: "weining_road", StationName: "威宁路", City: "上海", StationType: "地铁站"},
		"娄山关路":    {ID: 35, StationID: "loushanguan_road", StationName: "娄山关路", City: "上海", StationType: "地铁站"},

		// 10号线站点
		"上海虹桥火车站":  {ID: 36, StationID: "hongqiao_railway_10", StationName: "上海虹桥火车站", City: "上海", StationType: "地铁站"},
		"虹桥1号航站楼":  {ID: 37, StationID: "hongqiao_t1_10", StationName: "虹桥1号航站楼", City: "上海", StationType: "地铁站"},
		"上海动物园":    {ID: 38, StationID: "shanghai_zoo", StationName: "上海动物园", City: "上海", StationType: "地铁站"},
		"龙溪路":      {ID: 39, StationID: "longxi_road", StationName: "龙溪路", City: "上海", StationType: "地铁站"},
		"水城路":      {ID: 40, StationID: "shuicheng_road", StationName: "水城路", City: "上海", StationType: "地铁站"},
		"伊犁路":      {ID: 41, StationID: "yili_road", StationName: "伊犁路", City: "上海", StationType: "地铁站"},
		"宋园路":      {ID: 42, StationID: "songyuan_road", StationName: "宋园路", City: "上海", StationType: "地铁站"},
		"虹桥路":      {ID: 43, StationID: "hongqiao_road", StationName: "虹桥路", City: "上海", StationType: "地铁站"},
		"交通大学":     {ID: 44, StationID: "jiaotong_university", StationName: "交通大学", City: "上海", StationType: "地铁站"},
		"上海图书馆":    {ID: 45, StationID: "shanghai_library", StationName: "上海图书馆", City: "上海", StationType: "地铁站"},
		"陕西南路":     {ID: 46, StationID: "shaanxi_south_road", StationName: "陕西南路", City: "上海", StationType: "地铁站"},
		"一大会址·新天地": {ID: 47, StationID: "xin_tian_di", StationName: "一大会址·新天地", City: "上海", StationType: "地铁站"},
		"老西门":      {ID: 48, StationID: "lao_xi_men", StationName: "老西门", City: "上海", StationType: "地铁站"},
		"豫园":       {ID: 49, StationID: "yu_yuan", StationName: "豫园", City: "上海", StationType: "地铁站"},
		"天潼路":      {ID: 50, StationID: "tian_tong_road", StationName: "天潼路", City: "上海", StationType: "地铁站"},
		"四川北路":     {ID: 51, StationID: "north_sichuan_road", StationName: "四川北路", City: "上海", StationType: "地铁站"},
		"海伦路":      {ID: 52, StationID: "hai_lun_road", StationName: "海伦路", City: "上海", StationType: "地铁站"},
		"四平路":      {ID: 53, StationID: "si_ping_road", StationName: "四平路", City: "上海", StationType: "地铁站"},
		"同济大学":     {ID: 54, StationID: "tong_ji_university", StationName: "同济大学", City: "上海", StationType: "地铁站"},
		"国权路":      {ID: 55, StationID: "guoquan_road", StationName: "国权路", City: "上海", StationType: "地铁站"},
		"五角场":      {ID: 56, StationID: "wujiaochang", StationName: "五角场", City: "上海", StationType: "地铁站"},
		"江湾体育场":    {ID: 57, StationID: "jiangwan_stadium", StationName: "江湾体育场", City: "上海", StationType: "地铁站"},
		"三门路":      {ID: 58, StationID: "sanmen_road", StationName: "三门路", City: "上海", StationType: "地铁站"},
		"殷高东路":     {ID: 59, StationID: "yingao_east_road", StationName: "殷高东路", City: "上海", StationType: "地铁站"},
		"新江湾城":     {ID: 60, StationID: "xin_jiang_wan_city", StationName: "新江湾城", City: "上海", StationType: "地铁站"},
		"国帆路":      {ID: 91, StationID: "guofan_road", StationName: "国帆路", City: "上海", StationType: "地铁站"},
		"双江路":      {ID: 92, StationID: "shuangjiang_road", StationName: "双江路", City: "上海", StationType: "地铁站"},
		"高桥西":      {ID: 93, StationID: "gaoqiao_west", StationName: "高桥西", City: "上海", StationType: "地铁站"},
		"高桥":       {ID: 94, StationID: "gaoqiao", StationName: "高桥", City: "上海", StationType: "地铁站"},
		"港城路":      {ID: 95, StationID: "gangcheng_road", StationName: "港城路", City: "上海", StationType: "地铁站"},
		"基隆路":      {ID: 96, StationID: "jilong_road", StationName: "基隆路", City: "上海", StationType: "地铁站"},
		"抚顺路":      {ID: 61, StationID: "fushun_road", StationName: "抚顺路", City: "上海", StationType: "地铁站"},
		"复旦大学":     {ID: 62, StationID: "fudan_university", StationName: "复旦大学", City: "上海", StationType: "地铁站"},

		// 11号线站点
		"花桥":     {ID: 62, StationID: "hua_qiao", StationName: "花桥", City: "上海", StationType: "地铁站"},
		"光明路":    {ID: 63, StationID: "jiading_new_town", StationName: "光明路", City: "上海", StationType: "地铁站"},
		"兆丰路":    {ID: 64, StationID: "bao_an_road", StationName: "兆丰路", City: "上海", StationType: "地铁站"},
		"安亭":     {ID: 65, StationID: "anting", StationName: "安亭", City: "上海", StationType: "地铁站"},
		"上海赛车场":  {ID: 66, StationID: "che_ding_zhen", StationName: "上海赛车场", City: "上海", StationType: "地铁站"},
		"嘉定新城":   {ID: 67, StationID: "jiading_new_city", StationName: "嘉定新城", City: "上海", StationType: "地铁站"},
		"白银路":    {ID: 68, StationID: "jiading_old_town", StationName: "白银路", City: "上海", StationType: "地铁站"},
		"嘉定北":    {ID: 69, StationID: "jiading_beilu", StationName: "嘉定北", City: "上海", StationType: "地铁站"},
		"南翔":     {ID: 70, StationID: "nan_xiang", StationName: "南翔", City: "上海", StationType: "地铁站"},
		"马陆":     {ID: 71, StationID: "ma_lu", StationName: "马陆", City: "上海", StationType: "地铁站"},
		"桃浦新村":   {ID: 72, StationID: "jiang_su_road_11", StationName: "桃浦新村", City: "上海", StationType: "地铁站"},
		"武威路":    {ID: 73, StationID: "wan_li_road", StationName: "武威路", City: "上海", StationType: "地铁站"},
		"祁连山路":   {ID: 74, StationID: "qilian_mountain_road", StationName: "祁连山路", City: "上海", StationType: "地铁站"},
		"曹杨路":    {ID: 75, StationID: "caoyang_road", StationName: "曹杨路", City: "上海", StationType: "地铁站"},
		"隆德路":    {ID: 76, StationID: "long_de_road", StationName: "隆德路", City: "上海", StationType: "地铁站"},
		"徐家汇":    {ID: 77, StationID: "xu_jia_hui", StationName: "徐家汇", City: "上海", StationType: "地铁站"},
		"上海游泳馆":  {ID: 78, StationID: "shang_hai_sports", StationName: "上海游泳馆", City: "上海", StationType: "地铁站"},
		"肇嘉浜路":   {ID: 79, StationID: "zhi_pu_road", StationName: "肇嘉浜路", City: "上海", StationType: "地铁站"},
		"宜山路":    {ID: 80, StationID: "yuyao_road", StationName: "宜山路", City: "上海", StationType: "地铁站"},
		"龙华":     {ID: 81, StationID: "long_hua", StationName: "龙华", City: "上海", StationType: "地铁站"},
		"龙华中路":   {ID: 82, StationID: "long_hua_middle", StationName: "龙华中路", City: "上海", StationType: "地铁站"},
		"龙耀路":    {ID: 83, StationID: "lu_jia_bang_road", StationName: "龙耀路", City: "上海", StationType: "地铁站"},
		"云锦路":    {ID: 84, StationID: "huating_road", StationName: "云锦路", City: "上海", StationType: "地铁站"},
		"龙腾大道":   {ID: 85, StationID: "long_arcs", StationName: "龙腾大道", City: "上海", StationType: "地铁站"},
		"东方体育中心": {ID: 86, StationID: "pujiang_zhen", StationName: "东方体育中心", City: "上海", StationType: "地铁站"},

		// 其他常用站点
		"淮海中路":    {ID: 87, StationID: "huaihai_mid_road", StationName: "淮海中路", City: "上海", StationType: "地铁站"},
		"新天地":     {ID: 97, StationID: "xintiandi", StationName: "新天地", City: "上海", StationType: "地铁站"},
		"马当路":     {ID: 98, StationID: "madang_road", StationName: "马当路", City: "上海", StationType: "地铁站"},
		"延安西路":    {ID: 99, StationID: "yanan_west_road", StationName: "延安西路", City: "上海", StationType: "地铁站"},
		"常熟路":     {ID: 100, StationID: "changshu_road", StationName: "常熟路", City: "上海", StationType: "地铁站"},
		"黄陂南路":    {ID: 101, StationID: "huangpi_south_road", StationName: "黄陂南路", City: "上海", StationType: "地铁站"},
		"嘉善路":     {ID: 102, StationID: "jiashan_road", StationName: "嘉善路", City: "上海", StationType: "地铁站"},
		"大世界":     {ID: 103, StationID: "dashijie", StationName: "大世界", City: "上海", StationType: "地铁站"},
		"外高桥保税区北": {ID: 104, StationID: "waigaoqiao_ftz_north", StationName: "外高桥保税区北", City: "上海", StationType: "地铁站"},
		"外高桥保税区南": {ID: 105, StationID: "waigaoqiao_ftz_south", StationName: "外高桥保税区南", City: "上海", StationType: "地铁站"},
		"诸光路":     {ID: 106, StationID: "zhuguang_road", StationName: "诸光路", City: "上海", StationType: "地铁站"},
		"上海南站":    {ID: 88, StationID: "shanghai_south_railway_station", StationName: "上海南站", City: "上海", StationType: "地铁站"},
		"上海火车站":   {ID: 89, StationID: "shanghai_railway_station", StationName: "上海火车站", City: "上海", StationType: "地铁站"},
		"漕河泾开发区":  {ID: 90, StationID: "caohexi_kfq", StationName: "漕河泾开发区", City: "上海", StationType: "地铁站"},
	}

	fmt.Printf("[DEBUG-findStation] 模拟模式，stations map长度: %d, 查找name: '%s'\n", len(stations), name)
	if station, ok := stations[name]; ok {
		fmt.Printf("[DEBUG-findStation] 精确匹配找到: %s\n", station.StationName)
		return station, nil
	}

	// 如果没找到精确匹配，尝试模糊匹配
	for stationName, station := range stations {
		if strings.Contains(stationName, name) || strings.Contains(name, stationName) {
			return station, nil
		}
	}

	if station, ok := metroNetworkStationByName(name); ok {
		return station, nil
	}

	return models.Station{}, fmt.Errorf("未找到站点: %s", name)
}

func findRoutes(start, end models.Station) ([]PlannedRoute, error) {
	var allRoutes []PlannedRoute

	startLines, err := getLineStations(start.StationID)
	if err != nil {
		return nil, err
	}

	endLines, err := getLineStations(end.StationID)
	if err != nil {
		return nil, err
	}

	lineDetails := make(map[string]models.MetroLine)
	var lineIDs []string
	for _, ls := range startLines {
		lineIDs = append(lineIDs, ls.LineID)
	}
	for _, ls := range endLines {
		found := false
		for _, id := range lineIDs {
			if id == ls.LineID {
				found = true
				break
			}
		}
		if !found {
			lineIDs = append(lineIDs, ls.LineID)
		}
	}

	for _, lineID := range lineIDs {
		var line models.MetroLine
		if database.DB != nil {
			err := database.DB.QueryRow(
				"SELECT * FROM metro_lines WHERE line_id = ? LIMIT 1",
				lineID,
			).Scan(
				&line.ID, &line.LineID, &line.LineName, &line.City,
				&line.ColorName, &line.ColorHex, &line.Description,
			)
			if err == nil && line.LineID != "" {
				lineDetails[line.LineID] = line
				continue
			}
			fmt.Printf("[DEBUG-findRoutes] 数据库无线路详情，降级使用模拟线路: %s\n", lineID)
		}

		if networkLine, ok := metroNetworkLine(lineID); ok {
			lineDetails[lineID] = networkLine
			continue
		}

		// 模拟线路数据
		var green = "绿色"
		var red = "红色"
		var purple = "紫色"
		var brown = "棕色"
		var teal = "蓝绿色"
		var gold = "金色"
		var pink = "粉色"
		var magenta = "品红色"
		var unknown = "未知"

		var shanghai = "上海"
		var defaultDesc = "上海地铁" + lineID + "号线"

		switch lineID {
		case "1":
			line = models.MetroLine{ID: 0, LineID: "1", LineName: "1号线", City: shanghai, ColorName: &red, ColorHex: stringPtr("#E4002B"), Description: &defaultDesc}
		case "2":
			line = models.MetroLine{ID: 0, LineID: "2", LineName: "2号线", City: shanghai, ColorName: &green, ColorHex: stringPtr("#8CC63F"), Description: &defaultDesc}
		case "3":
			line = models.MetroLine{ID: 0, LineID: "3", LineName: "3号线", City: shanghai, ColorName: &gold, ColorHex: stringPtr("#FFD100"), Description: &defaultDesc}
		case "4":
			line = models.MetroLine{ID: 0, LineID: "4", LineName: "4号线", City: shanghai, ColorName: &purple, ColorHex: stringPtr("#4B2E83"), Description: &defaultDesc}
		case "6":
			line = models.MetroLine{ID: 0, LineID: "6", LineName: "6号线", City: shanghai, ColorName: &magenta, ColorHex: stringPtr("#BE2D79"), Description: &defaultDesc}
		case "10":
			line = models.MetroLine{ID: 0, LineID: "10", LineName: "10号线", City: shanghai, ColorName: &purple, ColorHex: stringPtr("#C5A3FF"), Description: &defaultDesc}
		case "11":
			line = models.MetroLine{ID: 0, LineID: "11", LineName: "11号线", City: shanghai, ColorName: &brown, ColorHex: stringPtr("#7A3E2F"), Description: &defaultDesc}
		case "12":
			line = models.MetroLine{ID: 0, LineID: "12", LineName: "12号线", City: shanghai, ColorName: &teal, ColorHex: stringPtr("#00843D"), Description: &defaultDesc}
		case "13":
			line = models.MetroLine{ID: 0, LineID: "13", LineName: "13号线", City: shanghai, ColorName: &pink, ColorHex: stringPtr("#F49AC1"), Description: &defaultDesc}
		case "14":
			line = models.MetroLine{ID: 0, LineID: "14", LineName: "14号线", City: shanghai, ColorName: &gold, ColorHex: stringPtr("#A6A01D"), Description: &defaultDesc}
		case "17":
			line = models.MetroLine{ID: 0, LineID: "17", LineName: "17号线", City: shanghai, ColorName: &pink, ColorHex: stringPtr("#C490C0"), Description: &defaultDesc}
		case "18":
			line = models.MetroLine{ID: 0, LineID: "18", LineName: "18号线", City: shanghai, ColorName: &unknown, ColorHex: stringPtr("#00A3AD"), Description: &defaultDesc}
		default:
			line = models.MetroLine{
				ID:          0,
				LineID:      lineID,
				LineName:    lineID + "号线",
				City:        shanghai,
				ColorName:   &unknown,
				ColorHex:    stringPtr("#CCCCCC"),
				Description: &defaultDesc,
			}
		}
		lineDetails[line.LineID] = line
	}

	for _, startLS := range startLines {
		for _, endLS := range endLines {
			startLine := lineDetails[startLS.LineID]
			endLine := lineDetails[endLS.LineID]

			if startLS.LineID == endLS.LineID {
				if route := findDirectRoute(start, end, startLS, endLS, startLine); route != nil {
					allRoutes = append(allRoutes, *route)
				}
			} else {
				if routes := findTransferRoutes(start, end, startLS, endLS, startLine, endLine); routes != nil {
					allRoutes = append(allRoutes, routes...)
				}
			}
		}
	}

	if networkRoute := findMetroNetworkRoute(start, end); networkRoute != nil {
		seen := false
		networkSignature := routeSignature(*networkRoute)
		for _, route := range allRoutes {
			if routeSignature(route) == networkSignature {
				seen = true
				break
			}
		}
		if !seen {
			allRoutes = append(allRoutes, *networkRoute)
		}
	}

	for i := 0; i < len(allRoutes)-1; i++ {
		for j := i + 1; j < len(allRoutes); j++ {
			if allRoutes[i].TotalTime > allRoutes[j].TotalTime {
				allRoutes[i], allRoutes[j] = allRoutes[j], allRoutes[i]
			}
		}
	}

	if len(allRoutes) > 3 {
		allRoutes = allRoutes[:3]
	}

	return allRoutes, nil
}

func getLineStations(stationID string) ([]models.LineStation, error) {
	if database.DB != nil {
		rows, err := database.DB.Query(
			"SELECT * FROM line_stations WHERE station_id = ?",
			stationID,
		)
		if err != nil {
			return nil, err
		}
		defer rows.Close()

		var stations []models.LineStation
		for rows.Next() {
			var ls models.LineStation
			rows.Scan(
				&ls.ID, &ls.LineID, &ls.StationID, &ls.Direction,
				&ls.StationOrder, &ls.IsTransfer, &ls.PlatformTip,
			)
			stations = append(stations, ls)
		}
		if len(stations) > 0 {
			return stations, nil
		}
		fmt.Printf("[DEBUG-getLineStations] 数据库无线路站点记录，降级使用模拟线路: %s\n", stationID)
	}

	// 模拟数据 - 根据站点名称确定所属线路
	// 先通过 stationID 反查站点名称（因为 getLineStations 接收的是 stationID）
	stationIDToName := map[string]string{
		"pudong_airport": "浦东国际机场", "yuanshen": "远东大道", "lingkong": "凌空路", "huaxia": "华夏东路",
		"chuansha": "川沙", "shenjiang": "华夏镇", "shanghai_race_track": "创新中路", "guanglan_road": "广兰路",
		"tianzhu_road": "唐镇", "jinqiao_road": "创新路", "jinyang_road": "金科路", "zhangjiang_high_tech": "张江高科",
		"longyang_road_2": "龙阳路", "shanghai_science_tech": "上海科技馆", "Century_Avenue": "世纪大道",
		"dongchang_road": "东昌路", "lujiazui": "陆家嘴", "dongbei_road": "东门路", "nanjing_east_road": "南京东路",
		"renmin_square": "人民广场", "shimen_road": "石门一路", "jingan_temple": "静安寺", "west_nan_jing_road": "南京西路",
		"jiangsu_road": "江苏路", "zhongshan_park": "中山公园", "longxu_road": "龙漕路", "caobao_road": "漕宝路",
		"xujingdong": "徐泾东", "hongqiao_railway_2": "虹桥火车站", "hongqiao_t2_2": "虹桥2号航站楼",
		"songhong_road": "淞虹路", "beixinjing": "北新泾", "weining_road": "威宁路", "loushanguan_road": "娄山关路",
		"hongqiao_railway_10": "上海虹桥火车站", "hongqiao_t1_10": "虹桥1号航站楼", "shanghai_zoo": "上海动物园",
		"longxi_road": "龙溪路", "shuicheng_road": "水城路", "yili_road": "伊犁路", "songyuan_road": "宋园路",
		"hongqiao_road": "虹桥路", "jiaotong_university": "交通大学", "shanghai_library": "上海图书馆",
		"shaanxi_south_road": "陕西南路", "xin_tian_di": "一大会址·新天地", "lao_xi_men": "老西门",
		"yu_yuan": "豫园", "tian_tong_road": "天潼路", "north_sichuan_road": "四川北路", "hai_lun_road": "海伦路",
		"si_ping_road": "四平路", "tong_ji_university": "同济大学", "guoquan_road": "国权路",
		"wujiaochang": "五角场", "jiangwan_stadium": "江湾体育场", "sanmen_road": "三门路",
		"yingao_east_road": "殷高东路", "xin_jiang_wan_city": "新江湾城",
		"guofan_road": "国帆路", "shuangjiang_road": "双江路", "gaoqiao_west": "高桥西", "gaoqiao": "高桥",
		"gangcheng_road": "港城路", "jilong_road": "基隆路",
		"fushun_road": "抚顺路", "fudan_university": "复旦大学",
		"hua_qiao": "花桥", "jiading_new_town": "光明路", "bao_an_road": "兆丰路", "anting": "安亭",
		"che_ding_zhen": "上海赛车场", "jiading_new_city": "嘉定新城", "jiading_old_town": "白银路",
		"jiading_beilu": "嘉定北", "nan_xiang": "南翔", "ma_lu": "马陆", "jiang_su_road_11": "桃浦新村",
		"wan_li_road": "武威路", "qilian_mountain_road": "祁连山路", "caoyang_road": "曹杨路",
		"long_de_road": "隆德路", "xu_jia_hui": "徐家汇", "shang_hai_sports": "上海游泳馆",
		"zhi_pu_road": "肇嘉浜路", "yuyao_road": "宜山路", "long_hua": "龙华", "long_hua_middle": "龙华中路",
		"lu_jia_bang_road": "龙耀路", "huating_road": "云锦路", "long_arcs": "龙腾大道", "pujiang_zhen": "东方体育中心",
		"huaihai_mid_road": "淮海中路", "shanghai_south_railway_station": "上海南站",
		"xintiandi": "新天地", "madang_road": "马当路", "yanan_west_road": "延安西路",
		"changshu_road": "常熟路", "huangpi_south_road": "黄陂南路", "jiashan_road": "嘉善路",
		"dashijie": "大世界", "waigaoqiao_ftz_north": "外高桥保税区北", "waigaoqiao_ftz_south": "外高桥保税区南",
		"zhuguang_road":            "诸光路",
		"shanghai_railway_station": "上海火车站", "caohexi_kfq": "漕河泾开发区",
		"fujin_road": "富锦路", "west_youyi_road": "友谊西路", "baoan_highway": "宝安公路",
		"gongfu_xincun": "共富新村", "hulan_road": "呼兰路", "tonghe_xincun": "通河新村",
		"gongkang_road": "共康路", "pengpu_xincun": "彭浦新村", "wenshui_road": "汶水路",
		"shanghai_circus_world": "上海马戏城", "yanchang_road": "延长路", "north_zhongshan_road": "中山北路",
		"hanzhong_road": "汉中路", "xinzha_road": "新闸路", "hengshan_road": "衡山路",
		"shanghai_indoor_stadium": "上海体育馆", "jinjiang_park": "锦江乐园", "lianhua_road": "莲花路",
		"waihuanlu": "外环路", "xinzhuang": "莘庄",
	}
	stationName := stationID
	if name, ok := stationIDToName[stationID]; ok {
		stationName = name
	}
	if networkStations := metroNetworkLineStations(stationID, stationName); len(networkStations) > 0 {
		return networkStations, nil
	}

	// 2号线站点映射
	line2Stations := map[string]int{
		"浦东国际机场": 1, "远东大道": 2, "凌空路": 3, "华夏东路": 4, "川沙": 5,
		"华夏镇": 6, "创新中路": 7, "广兰路": 8, "唐镇": 9, "创新路": 10,
		"金科路": 11, "张江高科": 12, "龙阳路": 13, "上海科技馆": 14, "世纪大道": 15,
		"东昌路": 16, "陆家嘴": 17, "东门路": 18, "南京东路": 19, "人民广场": 20,
		"石门一路": 21, "静安寺": 22, "南京西路": 23, "江苏路": 25, "中山公园": 26,
		"龙漕路": 27, "漕宝路": 28, "徐泾东": 29, "虹桥火车站": 30, "虹桥2号航站楼": 31,
		"淞虹路": 32, "北新泾": 33, "威宁路": 34, "娄山关路": 35,
	}

	// 10号线站点映射
	line10Stations := map[string]int{
		"上海虹桥火车站": 1, "虹桥火车站": 1, "虹桥1号航站楼": 2, "虹桥2号航站楼": 2, "上海动物园": 3, "龙溪路": 4, "水城路": 5,
		"伊犁路": 6, "宋园路": 7, "虹桥路": 8, "交通大学": 9, "上海图书馆": 10,
		"陕西南路": 11, "一大会址·新天地": 12, "新天地": 12, "老西门": 13, "豫园": 14, "天潼路": 15,
		"四川北路": 16, "海伦路": 17, "四平路": 18, "同济大学": 19, "国权路": 20,
		"五角场": 21, "江湾体育场": 22, "三门路": 23, "殷高东路": 24, "新江湾城": 25,
		"国帆路": 26, "双江路": 27, "高桥西": 28, "高桥": 29, "港城路": 30, "基隆路": 31,
	}

	line1Stations := map[string]int{
		"富锦路": 1, "友谊西路": 2, "宝安公路": 3, "共富新村": 4, "呼兰路": 5,
		"通河新村": 6, "共康路": 7, "彭浦新村": 8, "汶水路": 9, "上海马戏城": 10,
		"延长路": 11, "中山北路": 12, "上海火车站": 13, "汉中路": 14, "新闸路": 15,
		"人民广场": 16, "黄陂南路": 17, "陕西南路": 18, "常熟路": 19, "衡山路": 20,
		"徐家汇": 21, "上海体育馆": 22, "漕宝路": 23, "上海南站": 24, "锦江乐园": 25,
		"莲花路": 26, "外环路": 27, "莘庄": 28,
	}
	line3Stations := map[string]int{"延安西路": 1, "虹桥路": 2, "宜山路": 3}
	line4Stations := map[string]int{"延安西路": 1, "虹桥路": 2, "宜山路": 3, "海伦路": 4}
	line6Stations := map[string]int{"外高桥保税区北": 1, "港城路": 2, "外高桥保税区南": 3}

	// 11号线站点映射
	line11Stations := map[string]int{
		"花桥": 1, "光明路": 2, "兆丰路": 3, "安亭": 4, "上海赛车场": 5,
		"嘉定新城": 6, "白银路": 7, "嘉定北": 8, "南翔": 9, "马陆": 10,
		"桃浦新村": 11, "武威路": 12, "祁连山路": 13, "曹杨路": 14, "隆德路": 15,
		"徐家汇": 16, "上海游泳馆": 17, "肇嘉浜路": 18, "宜山路": 19, "龙华": 20,
		"龙华中路": 21, "龙耀路": 22, "云锦路": 23, "龙腾大道": 24, "东方体育中心": 25,
	}

	line18Stations := map[string]int{
		"抚顺路": 1, "国权路": 2, "复旦大学": 3,
	}

	line12Stations := map[string]int{"南京西路": 1, "陕西南路": 2, "嘉善路": 3, "天潼路": 4}
	line13Stations := map[string]int{"淮海中路": 1, "新天地": 2, "一大会址·新天地": 2, "马当路": 3}
	line14Stations := map[string]int{"大世界": 1, "豫园": 2, "陆家嘴": 3}
	line17Stations := map[string]int{"虹桥火车站": 1, "诸光路": 2, "虹桥2号航站楼": 3}

	var result []models.LineStation

	appendLineStation := func(lineID string, order int) {
		result = append(result, models.LineStation{
			ID:           0,
			LineID:       lineID,
			StationID:    stationID,
			Direction:    "both",
			StationOrder: order,
			IsTransfer:   false,
			PlatformTip:  nil,
		})
	}

	if order, exists := line1Stations[stationName]; exists {
		appendLineStation("1", order)
	}

	// 检查站点是否属于2号线
	if order, exists := line2Stations[stationName]; exists {
		appendLineStation("2", order)
	}

	if order, exists := line3Stations[stationName]; exists {
		appendLineStation("3", order)
	}

	if order, exists := line4Stations[stationName]; exists {
		appendLineStation("4", order)
	}

	if order, exists := line6Stations[stationName]; exists {
		appendLineStation("6", order)
	}

	// 检查站点是否属于10号线
	if order, exists := line10Stations[stationName]; exists {
		appendLineStation("10", order)
	}

	// 检查站点是否属于11号线
	if order, exists := line11Stations[stationName]; exists {
		appendLineStation("11", order)
	}

	if order, exists := line12Stations[stationName]; exists {
		appendLineStation("12", order)
	}

	if order, exists := line13Stations[stationName]; exists {
		appendLineStation("13", order)
	}

	if order, exists := line14Stations[stationName]; exists {
		appendLineStation("14", order)
	}

	if order, exists := line17Stations[stationName]; exists {
		appendLineStation("17", order)
	}

	if order, exists := line18Stations[stationName]; exists {
		appendLineStation("18", order)
	}

	return result, nil
}

func findDirectRoute(start, end models.Station, startLS, endLS models.LineStation, line models.MetroLine) *PlannedRoute {
	stopsCount := int(math.Abs(float64(endLS.StationOrder - startLS.StationOrder)))

	var rule models.TransferRule
	var err error

	if database.DB != nil {
		err = database.DB.QueryRow(
			"SELECT * FROM transfer_rules WHERE origin_station_id = ? AND line_id = ? AND target_station_id = ? AND direction = ? LIMIT 1",
			start.StationID, startLS.LineID, end.StationID, startLS.Direction,
		).Scan(
			&rule.ID, &rule.RuleID, &rule.OriginStationID, &rule.LineID,
			&rule.TargetStationID, &rule.Direction, &rule.StopsCount,
			&rule.EstimatedMinutes, &rule.CarriageSuggestion,
			&rule.TransferTip, &rule.DataLevel,
		)
	} else {
		err = fmt.Errorf("database not connected")
	}

	finalTime := stopsCount
	if err == nil {
		finalTime = rule.EstimatedMinutes
	} else {
		finalTime = int(math.Round(float64(stopsCount) * 1.5))
	}

	colorHex := ""
	if line.ColorHex != nil {
		colorHex = *line.ColorHex
	}

	return &PlannedRoute{
		Title:          "直达路线",
		TotalTime:      finalTime,
		Time:           formatTime(finalTime),
		Transfers:      0,
		StartStationID: start.StationID,
		EndStationID:   end.StationID,
		Description: "AI 分析：" + start.StationName + "与" + end.StationName +
			"均在" + line.LineName + "上，无需换乘即可直达。全程约" +
			formatTime(finalTime) + "，是最省时省力的方案。",
		Segments: []RouteSegment{
			{Type: "walk", Line: "步行", Description: "从" + start.StationName + "到" + start.StationName + "站", Time: "3分钟", Distance: "200m"},
			{Type: "subway", Line: line.LineName, Description: start.StationName + "站 → " + end.StationName + "站", Time: formatTime(finalTime), Stops: stopsCount, Color: colorHex},
			{Type: "walk", Line: "步行", Description: "从" + end.StationName + "地铁站到达目的地", Time: "3分钟", Distance: "150m"},
		},
	}
}

func findTransferRoutes(start, end models.Station, startLS, endLS models.LineStation, startLine, endLine models.MetroLine) []PlannedRoute {
	var routes []PlannedRoute

	transferStations, err := findCommonTransferStations(startLS.LineID, endLS.LineID)
	if err != nil {
		return nil
	}

	for _, transferID := range transferStations {
		if route := buildTransferRoute(start, end, startLS, endLS, transferID, startLine, endLine); route != nil {
			routes = append(routes, *route)
		}
	}

	return routes
}

func findCommonTransferStations(lineID1, lineID2 string) ([]string, error) {
	if database.DB != nil {
		var stations []string

		rows1, err := database.DB.Query(
			"SELECT DISTINCT station_id FROM line_stations WHERE line_id = ? AND is_transfer = 1",
			lineID1,
		)
		if err != nil {
			return nil, err
		}
		defer rows1.Close()

		var stationSet1 = make(map[string]bool)
		for rows1.Next() {
			var sid string
			rows1.Scan(&sid)
			stationSet1[sid] = true
		}

		rows2, err := database.DB.Query(
			"SELECT DISTINCT station_id FROM line_stations WHERE line_id = ? AND is_transfer = 1",
			lineID2,
		)
		if err != nil {
			return nil, err
		}
		defer rows2.Close()

		for rows2.Next() {
			var sid string
			rows2.Scan(&sid)
			if stationSet1[sid] {
				stations = append(stations, sid)
			}
		}

		if len(stations) > 0 {
			return stations, nil
		}
		fmt.Printf("[DEBUG-findCommonTransferStations] 数据库无换乘站记录，降级使用模拟换乘: %s-%s\n", lineID1, lineID2)
	}

	if stations := metroNetworkCommonTransferStations(lineID1, lineID2); len(stations) > 0 {
		return stations, nil
	}

	// 模拟换乘站数据
	transferStations := map[string]map[string][]string{
		"2": map[string][]string{
			"10": {"虹桥火车站"}, // 2号线和10号线在虹桥火车站换乘
			"11": {"江苏路"},   // 2号线和11号线在江苏路换乘
		},
		"1": map[string][]string{
			"10": {"陕西南路"},
			"12": {"陕西南路"},
		},
		"3": map[string][]string{
			"10": {"虹桥路"},
			"4":  {"虹桥路", "延安西路", "宜山路"},
		},
		"4": map[string][]string{
			"10": {"虹桥路", "海伦路"},
			"3":  {"虹桥路", "延安西路", "宜山路"},
		},
		"6": map[string][]string{
			"10": {"港城路"},
		},
		"10": map[string][]string{
			"1":  {"陕西南路"},
			"2":  {"虹桥火车站", "南京东路"},
			"3":  {"虹桥路"},
			"4":  {"虹桥路", "海伦路"},
			"6":  {"港城路"},
			"11": {"交通大学"}, // 10号线和11号线在交通大学换乘
			"12": {"陕西南路", "天潼路"},
			"13": {"新天地"},
			"14": {"豫园"},
			"17": {"虹桥火车站"},
			"18": {"国权路"},
		},
		"11": map[string][]string{
			"2":  {"江苏路"},
			"10": {"交通大学"},
		},
		"12": map[string][]string{
			"1":  {"陕西南路"},
			"10": {"陕西南路", "天潼路"},
		},
		"13": map[string][]string{
			"10": {"新天地"},
		},
		"14": map[string][]string{
			"10": {"豫园"},
		},
		"17": map[string][]string{
			"10": {"虹桥火车站"},
		},
		"18": map[string][]string{
			"10": {"国权路"},
		},
	}

	if lineTransfers, exists := transferStations[lineID1]; exists {
		if commonStations, exists := lineTransfers[lineID2]; exists {
			return commonStations, nil
		}
	}

	return []string{}, nil
}

func buildTransferRoute(start, end models.Station, startLS, endLS models.LineStation, transferID string, startLine, endLine models.MetroLine) *PlannedRoute {
	var transferStation models.Station
	var err error

	if database.DB != nil {
		err = database.DB.QueryRow(
			"SELECT * FROM stations WHERE station_id = ? LIMIT 1",
			transferID,
		).Scan(
			&transferStation.ID, &transferStation.StationID, &transferStation.StationName,
			&transferStation.StationAlias, &transferStation.City, &transferStation.District,
			&transferStation.StationType, &transferStation.Description,
		)
		if err != nil {
			transferStation = mockTransferStation(transferID)
		}
	} else {
		// 使用模拟数据
		transferStation = mockTransferStation(transferID)
	}

	var ls1 models.LineStation
	var ls2 models.LineStation

	if database.DB != nil {
		err = database.DB.QueryRow(
			"SELECT * FROM line_stations WHERE line_id = ? AND station_id = ? AND direction = ? LIMIT 1",
			startLS.LineID, transferID, startLS.Direction,
		).Scan(
			&ls1.ID, &ls1.LineID, &ls1.StationID, &ls1.Direction,
			&ls1.StationOrder, &ls1.IsTransfer, &ls1.PlatformTip,
		)
		if err != nil {
			if mock, ok := mockLineStationFor(startLS.LineID, transferID); ok {
				ls1 = mock
			} else {
				return nil
			}
		}

		err = database.DB.QueryRow(
			"SELECT * FROM line_stations WHERE line_id = ? AND station_id = ? LIMIT 1",
			endLS.LineID, transferID,
		).Scan(
			&ls2.ID, &ls2.LineID, &ls2.StationID, &ls2.Direction,
			&ls2.StationOrder, &ls2.IsTransfer, &ls2.PlatformTip,
		)
		if err != nil {
			if mock, ok := mockLineStationFor(endLS.LineID, transferID); ok {
				ls2 = mock
			} else {
				return nil
			}
		}
	} else {
		// 使用模拟数据 - 根据换乘站确定顺序
		if firstOrder, ok := metroNetworkOrder(startLS.LineID, transferID); ok {
			if secondOrder, ok := metroNetworkOrder(endLS.LineID, transferID); ok {
				ls1 = models.LineStation{
					ID:           0,
					LineID:       startLS.LineID,
					StationID:    transferID,
					Direction:    "both",
					StationOrder: firstOrder,
					IsTransfer:   true,
					PlatformTip:  nil,
				}
				ls2 = models.LineStation{
					ID:           0,
					LineID:       endLS.LineID,
					StationID:    transferID,
					Direction:    "both",
					StationOrder: secondOrder,
					IsTransfer:   true,
					PlatformTip:  nil,
				}
				goto transferOrdersReady
			}
		}

		lineStations := map[string]map[string]int{
			"1": map[string]int{
				"富锦路": 1, "友谊西路": 2, "宝安公路": 3, "共富新村": 4, "呼兰路": 5,
				"通河新村": 6, "共康路": 7, "彭浦新村": 8, "汶水路": 9, "上海马戏城": 10,
				"延长路": 11, "中山北路": 12, "上海火车站": 13, "汉中路": 14, "新闸路": 15,
				"人民广场": 16, "黄陂南路": 17, "陕西南路": 18, "常熟路": 19, "衡山路": 20,
				"徐家汇": 21, "上海体育馆": 22, "漕宝路": 23, "上海南站": 24, "锦江乐园": 25,
				"莲花路": 26, "外环路": 27, "莘庄": 28,
			},
			"2": map[string]int{
				"浦东国际机场": 1, "远东大道": 2, "凌空路": 3, "华夏东路": 4, "川沙": 5,
				"华夏镇": 6, "创新中路": 7, "广兰路": 8, "唐镇": 9, "创新路": 10,
				"金科路": 11, "张江高科": 12, "龙阳路": 13, "上海科技馆": 14, "世纪大道": 15,
				"东昌路": 16, "陆家嘴": 17, "东门路": 18, "南京东路": 19, "人民广场": 20,
				"石门一路": 21, "静安寺": 22, "南京西路": 23, "江苏路": 25, "中山公园": 26,
				"龙漕路": 27, "漕宝路": 28, "徐泾东": 29, "虹桥火车站": 30, "虹桥2号航站楼": 31,
				"淞虹路": 32, "北新泾": 33, "威宁路": 34, "娄山关路": 35,
			},
			"10": map[string]int{
				"上海虹桥火车站": 1, "虹桥火车站": 1, "虹桥1号航站楼": 2, "上海动物园": 3, "龙溪路": 4, "水城路": 5,
				"伊犁路": 6, "宋园路": 7, "虹桥路": 8, "交通大学": 9, "上海图书馆": 10,
				"陕西南路": 11, "一大会址·新天地": 12, "新天地": 12, "老西门": 13, "豫园": 14, "天潼路": 15,
				"四川北路": 16, "海伦路": 17, "四平路": 18, "同济大学": 19, "国权路": 20,
				"五角场": 21, "江湾体育场": 22, "三门路": 23, "殷高东路": 24, "新江湾城": 25,
				"国帆路": 26, "双江路": 27, "高桥西": 28, "高桥": 29, "港城路": 30, "基隆路": 31,
			},
			"3": map[string]int{
				"延安西路": 1, "虹桥路": 2, "宜山路": 3,
			},
			"4": map[string]int{
				"延安西路": 1, "虹桥路": 2, "宜山路": 3, "海伦路": 4,
			},
			"6": map[string]int{
				"外高桥保税区北": 1, "港城路": 2, "外高桥保税区南": 3,
			},
			"11": map[string]int{
				"花桥": 1, "光明路": 2, "兆丰路": 3, "安亭": 4, "上海赛车场": 5,
				"嘉定新城": 6, "白银路": 7, "嘉定北": 8, "南翔": 9, "马陆": 10,
				"桃浦新村": 11, "武威路": 12, "祁连山路": 13, "曹杨路": 14, "江苏路": 15,
				"隆德路": 16, "徐家汇": 17, "交通大学": 18, "上海游泳馆": 19, "肇嘉浜路": 20,
				"宜山路": 21, "龙华": 22, "龙华中路": 23, "龙耀路": 24, "云锦路": 25, "龙腾大道": 26, "东方体育中心": 27,
			},
			"12": map[string]int{
				"南京西路": 1, "陕西南路": 2, "嘉善路": 3, "天潼路": 4,
			},
			"13": map[string]int{
				"淮海中路": 1, "新天地": 2, "一大会址·新天地": 2, "马当路": 3,
			},
			"14": map[string]int{
				"大世界": 1, "豫园": 2, "陆家嘴": 3,
			},
			"17": map[string]int{
				"虹桥火车站": 1, "诸光路": 2, "虹桥2号航站楼": 3,
			},
			"18": map[string]int{
				"抚顺路": 1, "国权路": 2, "复旦大学": 3,
			},
		}

		ls1 = models.LineStation{
			ID:           0,
			LineID:       startLS.LineID,
			StationID:    transferID,
			Direction:    "both",
			StationOrder: lineStations[startLS.LineID][transferID],
			IsTransfer:   true,
			PlatformTip:  nil,
		}

		ls2 = models.LineStation{
			ID:           0,
			LineID:       endLS.LineID,
			StationID:    transferID,
			Direction:    "both",
			StationOrder: lineStations[endLS.LineID][transferID],
			IsTransfer:   true,
			PlatformTip:  nil,
		}
	}

transferOrdersReady:
	firstLegStops := int(math.Abs(float64(ls1.StationOrder - startLS.StationOrder)))
	secondLegStops := int(math.Abs(float64(endLS.StationOrder - ls2.StationOrder)))

	firstLegTime := int(math.Round(float64(firstLegStops) * 1.5))
	secondLegTime := int(math.Round(float64(secondLegStops) * 1.5))
	transferTime := 5
	totalTime := firstLegTime + transferTime + secondLegTime

	startColor := ""
	if startLine.ColorHex != nil {
		startColor = *startLine.ColorHex
	}
	endColor := ""
	if endLine.ColorHex != nil {
		endColor = *endLine.ColorHex
	}

	return &PlannedRoute{
		Title:          "换乘路线",
		TotalTime:      totalTime,
		Time:           formatTime(totalTime),
		Transfers:      1,
		StartStationID: start.StationID,
		EndStationID:   end.StationID,
		Description: "AI 分析：在" + transferStation.StationName + "换乘，虽然需要一次换乘，但可以到达目的地。全程约" +
			formatTime(totalTime) + "。",
		Segments: []RouteSegment{
			{Type: "walk", Line: "步行", Description: "从" + start.StationName + "到" + start.StationName + "站", Time: "3分钟", Distance: "200m"},
			{Type: "subway", Line: startLine.LineName, Description: start.StationName + "站 → " + transferStation.StationName + "站", Time: formatTime(firstLegTime), Stops: firstLegStops, Color: startColor},
			{Type: "walk", Line: "站内换乘", Description: transferStation.StationName + "站换乘" + endLine.LineName, Time: "5分钟", Distance: "100m"},
			{Type: "subway", Line: endLine.LineName, Description: transferStation.StationName + "站 → " + end.StationName + "站", Time: formatTime(secondLegTime), Stops: secondLegStops, Color: endColor},
			{Type: "walk", Line: "步行", Description: "从" + end.StationName + "地铁站到达目的地", Time: "3分钟", Distance: "150m"},
		},
	}
}

func mockTransferStation(transferID string) models.Station {
	return models.Station{
		ID:          0,
		StationID:   transferID,
		StationName: transferID,
		City:        "上海",
		StationType: "地铁站",
	}
}

func mockLineStationFor(lineID string, stationName string) (models.LineStation, bool) {
	if order, ok := metroNetworkOrder(lineID, stationName); ok {
		return models.LineStation{
			ID:           0,
			LineID:       lineID,
			StationID:    stationName,
			Direction:    "both",
			StationOrder: order,
			IsTransfer:   metroNetworkIsTransferStation(metroNetworkStationName(stationName, stationName)),
			PlatformTip:  nil,
		}, true
	}

	lineStations := map[string]map[string]int{
		"1": {
			"富锦路": 1, "友谊西路": 2, "宝安公路": 3, "共富新村": 4, "呼兰路": 5,
			"通河新村": 6, "共康路": 7, "彭浦新村": 8, "汶水路": 9, "上海马戏城": 10,
			"延长路": 11, "中山北路": 12, "上海火车站": 13, "汉中路": 14, "新闸路": 15,
			"人民广场": 16, "黄陂南路": 17, "陕西南路": 18, "常熟路": 19, "衡山路": 20,
			"徐家汇": 21, "上海体育馆": 22, "漕宝路": 23, "上海南站": 24, "锦江乐园": 25,
			"莲花路": 26, "外环路": 27, "莘庄": 28,
		},
		"2": {
			"浦东国际机场": 1, "远东大道": 2, "凌空路": 3, "华夏东路": 4, "川沙": 5,
			"华夏镇": 6, "创新中路": 7, "广兰路": 8, "唐镇": 9, "创新路": 10,
			"金科路": 11, "张江高科": 12, "龙阳路": 13, "上海科技馆": 14, "世纪大道": 15,
			"东昌路": 16, "陆家嘴": 17, "东门路": 18, "南京东路": 19, "人民广场": 20,
			"石门一路": 21, "静安寺": 22, "南京西路": 23, "江苏路": 25, "中山公园": 26,
			"龙漕路": 27, "漕宝路": 28, "徐泾东": 29, "虹桥火车站": 30, "虹桥2号航站楼": 31,
			"淞虹路": 32, "北新泾": 33, "威宁路": 34, "娄山关路": 35,
		},
		"10": {
			"上海虹桥火车站": 1, "虹桥火车站": 1, "虹桥1号航站楼": 2, "上海动物园": 3, "龙溪路": 4, "水城路": 5,
			"伊犁路": 6, "宋园路": 7, "虹桥路": 8, "交通大学": 9, "上海图书馆": 10,
			"陕西南路": 11, "一大会址·新天地": 12, "新天地": 12, "老西门": 13, "豫园": 14, "天潼路": 15,
			"四川北路": 16, "海伦路": 17, "四平路": 18, "同济大学": 19, "国权路": 20,
			"五角场": 21, "江湾体育场": 22, "三门路": 23, "殷高东路": 24, "新江湾城": 25,
			"国帆路": 26, "双江路": 27, "高桥西": 28, "高桥": 29, "港城路": 30, "基隆路": 31,
		},
		"3": {
			"延安西路": 1, "虹桥路": 2, "宜山路": 3,
		},
		"4": {
			"延安西路": 1, "虹桥路": 2, "宜山路": 3, "海伦路": 4,
		},
		"6": {
			"外高桥保税区北": 1, "港城路": 2, "外高桥保税区南": 3,
		},
		"11": {
			"花桥": 1, "光明路": 2, "兆丰路": 3, "安亭": 4, "上海赛车场": 5,
			"嘉定新城": 6, "白银路": 7, "嘉定北": 8, "南翔": 9, "马陆": 10,
			"桃浦新村": 11, "武威路": 12, "祁连山路": 13, "曹杨路": 14, "江苏路": 15,
			"隆德路": 16, "徐家汇": 17, "交通大学": 18, "上海游泳馆": 19, "肇嘉浜路": 20,
			"宜山路": 21, "龙华": 22, "龙华中路": 23, "龙耀路": 24, "云锦路": 25, "龙腾大道": 26, "东方体育中心": 27,
		},
		"12": {
			"南京西路": 1, "陕西南路": 2, "嘉善路": 3, "天潼路": 4,
		},
		"13": {
			"淮海中路": 1, "新天地": 2, "一大会址·新天地": 2, "马当路": 3,
		},
		"14": {
			"大世界": 1, "豫园": 2, "陆家嘴": 3,
		},
		"17": {
			"虹桥火车站": 1, "诸光路": 2, "虹桥2号航站楼": 3,
		},
		"18": {
			"抚顺路": 1, "国权路": 2, "复旦大学": 3,
		},
	}
	order, ok := lineStations[lineID][stationName]
	if !ok {
		return models.LineStation{}, false
	}
	return models.LineStation{
		ID:           0,
		LineID:       lineID,
		StationID:    stationName,
		Direction:    "both",
		StationOrder: order,
		IsTransfer:   true,
		PlatformTip:  nil,
	}, true
}

func formatTime(minutes int) string {
	return fmt.Sprintf("%d分钟", minutes)
}

func stringPtr(s string) *string {
	return &s
}
