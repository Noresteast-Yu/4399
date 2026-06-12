package handlers

import (
	"fmt"
	"image"
	"image/color"
	"image/png"
	"math"
	"net/http"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"smart-travel-backend/database"
	"smart-travel-backend/models"
	"smart-travel-backend/services"

	"github.com/gin-gonic/gin"
)

func GetStationVisual(c *gin.Context) {
	lineColor := parseHexColor(c.Query("color"), color.RGBA{176, 122, 178, 255})
	stageColor := visualStageColor(c.Query("stage"))
	img := image.NewRGBA(image.Rect(0, 0, 1200, 760))

	for y := 0; y < 760; y++ {
		ratio := float64(y) / 759
		base := blendColor(color.RGBA{238, 244, 255, 255}, color.RGBA{196, 207, 224, 255}, ratio)
		for x := 0; x < 1200; x++ {
			img.Set(x, y, base)
		}
	}

	fillRect(img, 0, 510, 1200, 250, color.RGBA{112, 125, 142, 255})
	fillRect(img, 0, 0, 1200, 18, lineColor)
	fillRect(img, 110, 150, 980, 290, color.RGBA{245, 248, 252, 255})
	fillRect(img, 150, 190, 240, 210, color.RGBA{198, 209, 222, 255})
	fillRect(img, 430, 190, 260, 210, color.RGBA{186, 200, 216, 255})
	fillRect(img, 730, 190, 280, 210, color.RGBA{198, 209, 222, 255})
	fillRect(img, 0, 500, 1200, 10, color.RGBA{255, 255, 255, 255})

	drawRail(img, 190, 735, 470, 510, lineColor)
	drawRail(img, 1010, 735, 730, 510, lineColor)
	fillRect(img, 0, 580, 1200, 28, stageColor)
	fillCircle(img, 600, 594, 42, color.RGBA{255, 255, 255, 255})
	fillCircle(img, 600, 594, 26, lineColor)

	c.Header("Cache-Control", "public, max-age=86400")
	c.Header("Content-Type", "image/png")
	_ = png.Encode(c.Writer, img)
}

func PlanRoute(c *gin.Context) {
	var req struct {
		Start             string                 `json:"start" binding:"required"`
		End               string                 `json:"end" binding:"required"`
		StartEntranceID   string                 `json:"startEntranceId"`
		StartEntranceName string                 `json:"startEntranceName"`
		EndExitID         string                 `json:"endExitId"`
		EndExitName       string                 `json:"endExitName"`
		Preferences       map[string]interface{} `json:"preferences"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "请提供起点和终点",
			"routes":  []interface{}{},
		})
		return
	}

	result, err := services.PlanRouteWithAI(req.Start, req.End, req.Preferences)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "服务器内部错误",
			"routes":  []interface{}{},
		})
		return
	}

	c.JSON(http.StatusOK, result)
}

func GetStation(c *gin.Context) {
	stationID := c.Param("stationId")

	var station models.Station
	var err error

	if database.DB != nil {
		err = database.DB.QueryRow(
			`SELECT id, station_id, station_name, station_alias, city, district, station_type, description
			FROM stations
			WHERE station_id = ?
			LIMIT 1`,
			stationID,
		).Scan(
			&station.ID, &station.StationID, &station.StationName,
			&station.StationAlias, &station.City, &station.District,
			&station.StationType, &station.Description,
		)
		if err != nil {
			if fallback, ok := services.MetroNetworkStationForID(stationID); ok {
				station = fallback
			} else {
				c.JSON(http.StatusNotFound, gin.H{
					"success": false,
					"error":   "站点不存在",
				})
				return
			}
		}
	} else {
		station, err = services.FindStationByID(stationID)
		if err != nil {
			if fallback, ok := services.MetroNetworkStationForID(stationID); ok {
				station = fallback
			} else {
				c.JSON(http.StatusNotFound, gin.H{
					"success": false,
					"error":   "站点不存在",
				})
				return
			}
		}
	}

	facility, _ := services.GetStationFacilityInfo(stationID)

	lines := services.GetStationLineNames(stationID)
	if len(lines) == 0 {
		lines = services.MetroNetworkLineIDsForStationID(station.StationID)
	}

	c.JSON(http.StatusOK, gin.H{
		"success":  true,
		"id":       station.StationID,
		"name":     station.StationName,
		"city":     station.City,
		"district": station.District,
		"type":     station.StationType,
		"lines":    lines,
		"facility": facility,
	})
}

func GetStationFacilities(c *gin.Context) {
	stationID := c.Param("stationId")

	facility, err := services.GetStationFacilityInfo(stationID)
	if err != nil || facility == nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "站点设施信息不存在",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":  true,
		"facility": facility,
	})
}

func parseHexColor(raw string, fallback color.RGBA) color.RGBA {
	raw = strings.TrimPrefix(strings.TrimSpace(raw), "#")
	if len(raw) != 6 {
		return fallback
	}
	value, err := strconv.ParseUint(raw, 16, 32)
	if err != nil {
		return fallback
	}
	return color.RGBA{
		R: uint8(value >> 16),
		G: uint8(value >> 8),
		B: uint8(value),
		A: 255,
	}
}

func visualStageColor(stage string) color.RGBA {
	switch stage {
	case "exit":
		return color.RGBA{0, 140, 74, 255}
	case "transfer", "transferWait":
		return color.RGBA{229, 121, 0, 255}
	case "ride":
		return color.RGBA{47, 84, 150, 255}
	default:
		return color.RGBA{176, 122, 178, 255}
	}
}

func blendColor(a color.RGBA, b color.RGBA, ratio float64) color.RGBA {
	return color.RGBA{
		R: uint8(float64(a.R)*(1-ratio) + float64(b.R)*ratio),
		G: uint8(float64(a.G)*(1-ratio) + float64(b.G)*ratio),
		B: uint8(float64(a.B)*(1-ratio) + float64(b.B)*ratio),
		A: 255,
	}
}

func fillRect(img *image.RGBA, x int, y int, width int, height int, c color.RGBA) {
	for yy := y; yy < y+height && yy < img.Bounds().Dy(); yy++ {
		for xx := x; xx < x+width && xx < img.Bounds().Dx(); xx++ {
			if xx >= 0 && yy >= 0 {
				img.Set(xx, yy, c)
			}
		}
	}
}

func drawRail(img *image.RGBA, x1 int, y1 int, x2 int, y2 int, c color.RGBA) {
	steps := absInt(x2 - x1)
	if ySteps := absInt(y2 - y1); ySteps > steps {
		steps = ySteps
	}
	if steps == 0 {
		return
	}
	for i := 0; i <= steps; i++ {
		x := x1 + (x2-x1)*i/steps
		y := y1 + (y2-y1)*i/steps
		fillCircle(img, x, y, 5, c)
	}
}

func fillCircle(img *image.RGBA, cx int, cy int, radius int, c color.RGBA) {
	r2 := radius * radius
	for y := cy - radius; y <= cy+radius; y++ {
		for x := cx - radius; x <= cx+radius; x++ {
			if x < 0 || y < 0 || x >= img.Bounds().Dx() || y >= img.Bounds().Dy() {
				continue
			}
			dx := x - cx
			dy := y - cy
			if dx*dx+dy*dy <= r2 {
				img.Set(x, y, c)
			}
		}
	}
}

func absInt(value int) int {
	if value < 0 {
		return -value
	}
	return value
}

type stationExitResponse struct {
	ID           string `json:"id"`
	Name         string `json:"name"`
	Label        string `json:"label"`
	Detail       string `json:"detail"`
	NearbyPlace  string `json:"nearbyPlace"`
	GuideTip     string `json:"guideTip"`
	IsAccessible bool   `json:"isAccessible"`
}

type stationGeoPoint struct {
	Name      string
	StationID string
	Latitude  float64
	Longitude float64
}

var knownStationGeoPoints = []stationGeoPoint{
	{Name: "同济大学", StationID: "tongji_university_10", Latitude: 31.2821, Longitude: 121.5063},
	{Name: "四平路", StationID: "siping_road_8", Latitude: 31.2749, Longitude: 121.5082},
	{Name: "五角场", StationID: "wujiaochang_10", Latitude: 31.3039, Longitude: 121.5145},
	{Name: "国权路", StationID: "guoquan_road", Latitude: 31.2895, Longitude: 121.5104},
	{Name: "上海火车站", StationID: "shanghai_railway_1", Latitude: 31.2495, Longitude: 121.4555},
	{Name: "人民广场", StationID: "peoples_square", Latitude: 31.2304, Longitude: 121.4737},
	{Name: "南京东路", StationID: "nanjing_east_2", Latitude: 31.2392, Longitude: 121.4846},
	{Name: "虹桥火车站", StationID: "hongqiao_railway_2", Latitude: 31.1943, Longitude: 121.3189},
	{Name: "浦东国际机场", StationID: "pudong_airport_2", Latitude: 31.1500, Longitude: 121.8050},
}

func GetStationExits(c *gin.Context) {
	stationID := c.Param("stationId")

	exits := stationExitsFromDatabase(stationID)
	defaults := defaultStationExits(stationID)
	if len(exits) == 0 || len(exits) < len(defaults) {
		exits = defaults
	}

	c.JSON(http.StatusOK, gin.H{
		"success":    true,
		"exits":      exits,
		"totalCount": len(exits),
	})
}

func GetNearestStation(c *gin.Context) {
	lat, latErr := strconv.ParseFloat(strings.TrimSpace(c.Query("lat")), 64)
	lng, lngErr := strconv.ParseFloat(strings.TrimSpace(c.Query("lng")), 64)
	if latErr != nil || lngErr != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "请提供有效的 lat 和 lng",
		})
		return
	}

	nearest, distanceMeters, source := nearestStationGeoPoint(lat, lng)
	if nearest == nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"error":   "暂无可用站点定位数据",
		})
		return
	}

	exits := stationExitsFromDatabase(nearest.StationID)
	if len(exits) == 0 {
		exits = defaultStationExits(nearest.StationID)
	}
	recommendedEntrance := stationExitResponse{}
	if len(exits) > 0 {
		recommendedEntrance = exits[0]
		for _, exit := range exits {
			detail := exit.Detail + exit.NearbyPlace + exit.Name
			if strings.Contains(detail, "同济") || strings.Contains(detail, "正门") || strings.Contains(detail, "主通道") {
				recommendedEntrance = exit
				break
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"stationId":            nearest.StationID,
			"stationName":          nearest.Name,
			"distanceMeters":       int(math.Round(distanceMeters)),
			"recommendedEntrance":  recommendedEntrance,
			"candidateEntrances":   exits,
			"source":               source,
			"coverageDescription":  nearestStationCoverageDescription(source),
			"requestedCoordinates": gin.H{"lat": lat, "lng": lng},
		},
	})
}

func ParseAssistantDestination(c *gin.Context) {
	var req struct {
		Text string `json:"text" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "请提供语音文本"})
		return
	}

	cleaned := cleanAssistantDestinationText(req.Text)
	station, score := bestAssistantStationMatch(cleaned)
	if station.Name == "" {
		c.JSON(http.StatusOK, gin.H{"success": true, "data": gin.H{
			"rawText":      req.Text,
			"destination":  cleaned,
			"matched":      false,
			"matchScore":   0,
			"stationId":    "",
			"stationName":  "",
			"availableTip": "没有匹配到地铁站，请换个站名试试",
		}})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "data": gin.H{
		"rawText":     req.Text,
		"destination": cleaned,
		"matched":     true,
		"matchScore":  score,
		"stationId":   station.ID,
		"stationName": station.Name,
		"lineNames":   station.LineNames,
	}})
}

func SaveAssistantSession(c *gin.Context) {
	var req struct {
		UserID            string `json:"userId"`
		RawText           string `json:"rawText"`
		ParsedDestination string `json:"parsedDestination"`
		StartStation      string `json:"startStation" binding:"required"`
		StartEntrance     string `json:"startEntrance"`
		EndStation        string `json:"endStation" binding:"required"`
		EndExit           string `json:"endExit"`
		Source            string `json:"source"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "请提供完整的助手规划信息"})
		return
	}
	req.UserID = boundedString(req.UserID, "default", 100)
	req.RawText = boundedString(req.RawText, "", 1000)
	req.ParsedDestination = boundedString(req.ParsedDestination, req.EndStation, 200)
	req.StartStation = strings.TrimSpace(req.StartStation)
	req.StartEntrance = boundedString(req.StartEntrance, "", 200)
	req.EndStation = strings.TrimSpace(req.EndStation)
	req.EndExit = boundedString(req.EndExit, "", 200)
	req.Source = boundedString(req.Source, "voice-assistant", 100)
	if req.StartStation == "" || req.EndStation == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "请提供起点和终点"})
		return
	}

	if database.DB == nil {
		c.JSON(http.StatusOK, gin.H{"success": true, "data": gin.H{
			"saved":   false,
			"message": "演示模式未写入数据库",
		}})
		return
	}

	result, err := database.DB.Exec(
		`INSERT INTO assistant_sessions
		(user_id, raw_text, parsed_destination, start_station, start_entrance, end_station, end_exit, source)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
		req.UserID, req.RawText, req.ParsedDestination, req.StartStation, req.StartEntrance, req.EndStation, req.EndExit, req.Source,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": "助手规划记录保存失败"})
		return
	}
	id, _ := result.LastInsertId()
	c.JSON(http.StatusOK, gin.H{"success": true, "data": gin.H{
		"id":    id,
		"saved": true,
	}})
}

func GetAssistantSessions(c *gin.Context) {
	userID := boundedString(c.DefaultQuery("userId", "default"), "default", 100)
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	if limit <= 0 || limit > 50 {
		limit = 20
	}
	if database.DB == nil {
		c.JSON(http.StatusOK, gin.H{"success": true, "data": []gin.H{}})
		return
	}
	rows, err := database.DB.Query(
		`SELECT id, user_id, COALESCE(raw_text, ''), COALESCE(parsed_destination, ''),
		COALESCE(start_station, ''), COALESCE(start_entrance, ''), COALESCE(end_station, ''),
		COALESCE(end_exit, ''), source, created_at
		FROM assistant_sessions
		WHERE user_id = ?
		ORDER BY created_at DESC
		LIMIT ?`,
		userID, limit,
	)
	if err != nil {
		c.JSON(http.StatusOK, gin.H{"success": true, "data": []gin.H{}})
		return
	}
	defer rows.Close()

	sessions := []gin.H{}
	for rows.Next() {
		var id int
		var userID, rawText, parsedDestination, startStation, startEntrance, endStation, endExit, source, createdAt string
		if err := rows.Scan(&id, &userID, &rawText, &parsedDestination, &startStation, &startEntrance, &endStation, &endExit, &source, &createdAt); err != nil {
			continue
		}
		sessions = append(sessions, gin.H{
			"id":                id,
			"userId":            userID,
			"rawText":           rawText,
			"parsedDestination": parsedDestination,
			"startStation":      startStation,
			"startEntrance":     startEntrance,
			"endStation":        endStation,
			"endExit":           endExit,
			"source":            source,
			"createdAt":         createdAt,
		})
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": sessions})
}

type assistantStationMatch struct {
	ID        string
	Name      string
	LineNames []string
}

func cleanAssistantDestinationText(text string) string {
	value := strings.TrimSpace(text)
	replacers := []string{"我要去", "我想去", "带我去", "导航到", "导航去", "去往", "前往", "到达", "到", "地铁站", "站"}
	for _, token := range replacers {
		value = strings.ReplaceAll(value, token, "")
	}
	value = strings.Map(func(r rune) rune {
		switch r {
		case '，', '。', ',', '.', '!', '?', '！', '？', ' ', '\t', '\n', '\r':
			return -1
		default:
			return r
		}
	}, value)
	return strings.TrimSpace(value)
}

func bestAssistantStationMatch(query string) (assistantStationMatch, int) {
	query = strings.TrimSpace(query)
	if query == "" {
		return assistantStationMatch{}, 0
	}
	best := assistantStationMatch{}
	bestScore := 0
	for _, item := range services.MetroNetworkStations() {
		score := assistantStationScore(query, item.Name)
		if score > bestScore {
			bestScore = score
			best = assistantStationMatch{
				ID:        item.ID,
				Name:      item.Name,
				LineNames: item.AvailableLines,
			}
		}
	}
	if bestScore < 40 {
		return assistantStationMatch{}, 0
	}
	return best, bestScore
}

func assistantStationScore(query, stationName string) int {
	switch {
	case query == stationName:
		return 100
	case strings.Contains(stationName, query):
		return 85 - absInt(utf8.RuneCountInString(stationName)-utf8.RuneCountInString(query))
	case strings.Contains(query, stationName):
		return 82
	default:
		common := commonRuneCount(query, stationName)
		if common == 0 {
			return 0
		}
		return common * 18
	}
}

func commonRuneCount(a, b string) int {
	seen := map[rune]bool{}
	for _, r := range a {
		seen[r] = true
	}
	count := 0
	for _, r := range b {
		if seen[r] {
			count++
		}
	}
	return count
}

func boundedString(value, fallback string, maxRunes int) string {
	value = strings.TrimSpace(value)
	if value == "" {
		return fallback
	}
	if maxRunes <= 0 {
		return value
	}
	runes := []rune(value)
	if len(runes) > maxRunes {
		return string(runes[:maxRunes])
	}
	return value
}

func nearestStationGeoPoint(lat, lng float64) (*stationGeoPoint, float64, string) {
	if nearest, distance, ok := nearestStationGeoPointFromDatabase(lat, lng); ok {
		return nearest, distance, "database"
	}
	var nearest *stationGeoPoint
	bestDistance := math.MaxFloat64
	for i := range knownStationGeoPoints {
		point := &knownStationGeoPoints[i]
		distance := haversineMeters(lat, lng, point.Latitude, point.Longitude)
		if distance < bestDistance {
			bestDistance = distance
			nearest = point
		}
	}
	return nearest, bestDistance, "known-station-geo"
}

func nearestStationGeoPointFromDatabase(lat, lng float64) (*stationGeoPoint, float64, bool) {
	if database.DB == nil {
		return nil, 0, false
	}
	rows, err := database.DB.Query(
		`SELECT sg.station_id, s.station_name, sg.latitude, sg.longitude
		FROM station_geo_points sg
		JOIN stations s ON s.station_id = sg.station_id`,
	)
	if err != nil {
		return nil, 0, false
	}
	defer rows.Close()

	var nearest *stationGeoPoint
	bestDistance := math.MaxFloat64
	for rows.Next() {
		var point stationGeoPoint
		if err := rows.Scan(&point.StationID, &point.Name, &point.Latitude, &point.Longitude); err != nil {
			continue
		}
		distance := haversineMeters(lat, lng, point.Latitude, point.Longitude)
		if distance < bestDistance {
			bestDistance = distance
			nearest = &point
		}
	}
	if nearest == nil {
		return nil, 0, false
	}
	return nearest, bestDistance, true
}

func nearestStationCoverageDescription(source string) string {
	if source == "database" {
		return "数据库站点坐标推荐，可随站点数据扩展"
	}
	return "课程项目演示定位数据，覆盖常用演示站点"
}

func haversineMeters(lat1, lng1, lat2, lng2 float64) float64 {
	const earthRadiusMeters = 6371000.0
	toRadians := func(degrees float64) float64 { return degrees * math.Pi / 180 }
	dLat := toRadians(lat2 - lat1)
	dLng := toRadians(lng2 - lng1)
	rLat1 := toRadians(lat1)
	rLat2 := toRadians(lat2)

	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(rLat1)*math.Cos(rLat2)*math.Sin(dLng/2)*math.Sin(dLng/2)
	return earthRadiusMeters * 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
}

func stationExitsFromDatabase(stationID string) []stationExitResponse {
	if database.DB == nil {
		return nil
	}

	rows, err := database.DB.Query(
		`SELECT exit_id, exit_name, COALESCE(nearby_place, ''), COALESCE(guide_tip, ''), is_accessible
		FROM station_exits
		WHERE station_id = ?
		ORDER BY exit_name`,
		stationID,
	)
	if err != nil {
		return nil
	}
	defer rows.Close()

	exits := make([]stationExitResponse, 0)
	for rows.Next() {
		var exit stationExitResponse
		if err := rows.Scan(&exit.ID, &exit.Name, &exit.NearbyPlace, &exit.GuideTip, &exit.IsAccessible); err != nil {
			continue
		}
		exit.Label = exit.Name
		exit.Detail = exit.GuideTip
		if exit.Detail == "" {
			exit.Detail = exit.NearbyPlace
		}
		exits = append(exits, exit)
	}
	return exits
}

func defaultStationExits(stationID string) []stationExitResponse {
	normalized := strings.ToLower(stationID)
	stationName := services.MetroNetworkStationNameForID(stationID)
	if stationName == "" {
		stationName = stationID
	}
	switch {
	case strings.Contains(normalized, "tongji") || strings.Contains(stationID, "同济"):
		return stationExitChoices([][3]string{
			{"1", "1号口", "同济联合广场"},
			{"2", "2号口", "彰武路，赤峰路"},
			{"3", "3号口", "站厅南侧通道"},
			{"4", "4号口", "站厅南侧通道"},
			{"5", "5号口", "四平路，同济大学正门"},
		})
	case strings.Contains(normalized, "hongqiao") || strings.Contains(stationID, "虹桥"):
		return stationExitChoices([][3]string{
			{"A", "A口", "高铁到达层，虹桥枢纽"},
			{"B", "B口", "2号线、17号线换乘"},
			{"C", "C口", "出租车，公交枢纽"},
		})
	case strings.Contains(normalized, "wujiaochang") || strings.Contains(stationID, "五角场"):
		return stationExitChoices([][3]string{
			{"1", "1号口", "邯郸路，国定路"},
			{"4", "4号口", "万达广场"},
			{"5", "5号口", "合生汇，大学路"},
		})
	case strings.Contains(normalized, "shanghai_railway") || strings.Contains(stationID, "上海火车站"):
		return stationExitChoices([][3]string{
			{"1", "1号口", "南广场，铁路上海站"},
			{"2", "2号口", "北广场，长途客运方向"},
			{"3", "3号口", "1号线站厅，公交接驳"},
			{"4", "4号口", "3/4号线换乘通道"},
			{"5", "5号口", "出租车与网约车上客区"},
		})
	case strings.Contains(normalized, "pudong_airport") || strings.Contains(stationID, "浦东国际机场"):
		return stationExitChoices([][3]string{
			{"A", "A口", "T1航站楼，国内/国际出发"},
			{"B", "B口", "T2航站楼，机场到达层"},
			{"C", "C口", "磁浮列车与机场巴士换乘"},
			{"D", "D口", "停车场与网约车接驳"},
			{"E", "E口", "无障碍通道，行李旅客优先"},
		})
	default:
		return generatedStationExits(stationName)
	}
}

func generatedStationExits(stationName string) []stationExitResponse {
	stationName = strings.TrimSpace(stationName)
	if stationName == "" {
		stationName = "本站"
	}
	return stationExitChoices([][3]string{
		{"A", "A口", stationName + "站厅主通道，靠近进出站客流"},
		{"B", "B口", stationName + "周边道路方向，适合步行离站"},
		{"C", "C口", stationName + "公交与网约车接驳方向"},
		{"D", "D口", stationName + "商业及公共服务设施方向"},
		{"E", "E口", stationName + "无障碍优先通行方向"},
	})
}

func stationExitChoices(items [][3]string) []stationExitResponse {
	exits := make([]stationExitResponse, 0, len(items))
	for _, item := range items {
		exits = append(exits, stationExitResponse{
			ID:           item[0],
			Name:         item[1],
			Label:        item[1],
			Detail:       item[2],
			NearbyPlace:  item[2],
			GuideTip:     item[2],
			IsAccessible: true,
		})
	}
	return exits
}

func GetAllStationsFacilities(c *gin.Context) {
	facilities := services.GetAllStationFacilities()
	c.JSON(http.StatusOK, gin.H{
		"success":    true,
		"facilities": facilities,
		"totalCount": len(facilities),
	})
}

func GetLines(c *gin.Context) {
	if database.DB == nil {
		c.JSON(http.StatusOK, services.MetroNetworkLineSummaries())
		return
	}

	rows, err := database.DB.Query("SELECT line_id, line_name, color_hex FROM metro_lines")
	if err != nil {
		c.JSON(http.StatusOK, services.MetroNetworkLineSummaries())
		return
	}
	defer rows.Close()

	lines := []gin.H{}
	for rows.Next() {
		var lineID, lineName string
		var colorHex *string
		if err := rows.Scan(&lineID, &lineName, &colorHex); err != nil {
			continue
		}
		lines = append(lines, gin.H{
			"id":    lineID,
			"name":  lineName,
			"color": colorHex,
		})
	}
	if len(lines) < 18 {
		c.JSON(http.StatusOK, services.MetroNetworkLineSummaries())
		return
	}

	c.JSON(http.StatusOK, lines)
}

func defaultMetroLines() []gin.H {
	return []gin.H{
		{"id": "1", "name": "1号线", "city": "上海", "color": "#E4002B", "directions": []string{"富锦路", "莘庄"}},
		{"id": "2", "name": "2号线", "city": "上海", "color": "#8CC63F", "directions": []string{"徐泾东", "浦东国际机场"}},
		{"id": "10", "name": "10号线", "city": "上海", "color": "#C5A3FF", "directions": []string{"虹桥火车站", "基隆路"}},
		{"id": "11", "name": "11号线", "city": "上海", "color": "#7A3E2F", "directions": []string{"嘉定北", "迪士尼"}},
		{"id": "18", "name": "18号线", "city": "上海", "color": "#C8A45D", "directions": []string{"长江南路", "航头"}},
	}
}

func GetMetroArrival(c *gin.Context) {
	query := services.MetroArrivalQuery{
		LineID:    c.DefaultQuery("lineId", "mock-line-10"),
		LineName:  c.DefaultQuery("lineName", "10号线"),
		StopID:    c.Query("stopId"),
		StopName:  c.Query("stopName"),
		Direction: c.DefaultQuery("direction", "0"),
		CityCode:  c.Query("cityCode"),
	}
	if query.StopID == "" && query.StopName == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "stopId or stopName is required"})
		return
	}

	result, err := services.QueryMetroArrival(query)
	if err != nil {
		c.JSON(http.StatusBadGateway, gin.H{"success": false, "error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "data": result})
}

func GetIndoorGuide(c *gin.Context) {
	from := c.DefaultQuery("from", "新天地")
	to := c.DefaultQuery("to", "静安寺")
	options := services.IndoorGuideOptions{
		StartEntranceID:   c.Query("startEntranceId"),
		StartEntranceName: c.Query("startEntranceName"),
		EndExitID:         c.Query("endExitId"),
		EndExitName:       c.Query("endExitName"),
	}

	plan := services.BuildIndoorGuideWithOptions(from, to, options)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": plan})
}

func GetIndoorGuideProgress(c *gin.Context) {
	from := c.DefaultQuery("from", "新天地")
	to := c.DefaultQuery("to", "静安寺")
	stepIndex, _ := strconv.Atoi(c.DefaultQuery("stepIndex", "0"))
	options := services.IndoorGuideOptions{
		StartEntranceID:   c.Query("startEntranceId"),
		StartEntranceName: c.Query("startEntranceName"),
		EndExitID:         c.Query("endExitId"),
		EndExitName:       c.Query("endExitName"),
	}

	progress := services.BuildIndoorGuideProgressWithOptions(from, to, stepIndex, options)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": progress})
}

func GetIndoorStationTopology(c *gin.Context) {
	stationID := c.DefaultQuery("stationId", "tongji_university")

	topology, err := services.LoadStationTopology(stationID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "data": topology})
}

func GetIndoorNavigationPath(c *gin.Context) {
	stationID := c.DefaultQuery("stationId", "tongji_university")
	fromNodeID := c.Query("fromNodeId")
	toNodeID := c.Query("toNodeId")
	targetType := c.Query("targetType")
	targetID := c.Query("targetId")

	if fromNodeID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "fromNodeId is required"})
		return
	}

	path, err := services.BuildIndoorNavigationPath(stationID, fromNodeID, toNodeID, targetType, targetID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "data": path})
}

func StartTransfer(c *gin.Context) {
	var req struct {
		FromStation      string `json:"fromStation"`
		ToStation        string `json:"toStation"`
		TransferStation  string `json:"transferStation"`
		EstimatedMinutes int    `json:"estimatedMinutes"`
		WalkingMinutes   int    `json:"walkingMinutes"`
		WaitingMinutes   int    `json:"waitingMinutes"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "换乘计时参数格式不正确"})
		return
	}

	req.FromStation = strings.TrimSpace(req.FromStation)
	req.ToStation = strings.TrimSpace(req.ToStation)
	req.TransferStation = strings.TrimSpace(req.TransferStation)
	if req.FromStation == "" {
		req.FromStation = "当前位置"
	}
	if req.ToStation == "" {
		req.ToStation = "目标站点"
	}
	if req.TransferStation == "" {
		req.TransferStation = "换乘通道"
	}

	totalMinutes := req.EstimatedMinutes
	if totalMinutes <= 0 {
		totalMinutes = req.WalkingMinutes + req.WaitingMinutes
	}
	if totalMinutes <= 0 {
		totalMinutes = 8
	}
	if totalMinutes > 120 {
		totalMinutes = 120
	}

	now := time.Now()
	sessionID := fmt.Sprintf("transfer-%d", now.UnixNano())
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"sessionId":        sessionID,
			"fromStation":      req.FromStation,
			"toStation":        req.ToStation,
			"transferStation":  req.TransferStation,
			"startedAt":        now.Format(time.RFC3339),
			"totalSeconds":     totalMinutes * 60,
			"remainingSeconds": totalMinutes * 60,
			"status":           "running",
			"message":          "换乘计时已开始",
		},
	})
}

func GetTransferUpdate(c *gin.Context) {
	sessionID := strings.TrimSpace(c.Param("sessionId"))
	if sessionID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "请提供换乘计时会话ID"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"sessionId":        sessionID,
			"status":           "running",
			"remainingSeconds": 420,
			"elapsedSeconds":   60,
			"nextAction":       "沿站内换乘标识前进，注意扶梯和客流方向",
			"message":          "预计仍有约7分钟完成换乘",
		},
	})
}

func GetCommonRoutes(c *gin.Context) {
	userID := strings.TrimSpace(c.Param("userId"))
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "请提供用户ID"})
		return
	}

	if database.DB == nil {
		c.JSON(http.StatusOK, defaultCommonRoutes(userID))
		return
	}

	rows, err := database.DB.Query(
		"SELECT id, user_id, start, end, COALESCE(time, ''), COALESCE(distance, '') FROM common_routes WHERE user_id = ? ORDER BY id DESC",
		userID,
	)
	if err != nil {
		c.JSON(http.StatusOK, []gin.H{})
		return
	}
	defer rows.Close()

	routes := []gin.H{}
	for rows.Next() {
		var id int
		var routeUserID string
		var start, end, routeTime, distance string
		if err := rows.Scan(&id, &routeUserID, &start, &end, &routeTime, &distance); err != nil {
			continue
		}
		routes = append(routes, gin.H{
			"id":       id,
			"userId":   routeUserID,
			"start":    start,
			"end":      end,
			"time":     routeTime,
			"distance": distance,
			"title":    start + " -> " + end,
		})
	}

	c.JSON(http.StatusOK, routes)
}

func defaultCommonRoutes(userID string) []gin.H {
	return []gin.H{
		{
			"id":       0,
			"userId":   userID,
			"start":    "同济大学",
			"end":      "上海火车站",
			"time":     "约31分钟",
			"distance": "约17公里",
			"title":    "同济大学 -> 上海火车站",
			"source":   "local-demo",
		},
		{
			"id":       0,
			"userId":   userID,
			"start":    "同济大学",
			"end":      "浦东国际机场",
			"time":     "约74分钟",
			"distance": "约42公里",
			"title":    "同济大学 -> 浦东国际机场",
			"source":   "local-demo",
		},
	}
}

func AddCommonRoute(c *gin.Context) {
	var req struct {
		UserID   string `json:"userId"`
		Start    string `json:"start" binding:"required"`
		End      string `json:"end" binding:"required"`
		Time     string `json:"time"`
		Distance string `json:"distance"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "请提供用户ID、起点和终点"})
		return
	}

	req.UserID = strings.TrimSpace(req.UserID)
	req.Start = strings.TrimSpace(req.Start)
	req.End = strings.TrimSpace(req.End)
	req.Time = strings.TrimSpace(req.Time)
	req.Distance = strings.TrimSpace(req.Distance)
	if req.UserID == "" || req.Start == "" || req.End == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "请提供用户ID、起点和终点"})
		return
	}
	if len(req.Time) > 50 || len(req.Distance) > 50 {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "路线时间或距离过长"})
		return
	}

	if database.DB == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"success": false, "error": "数据库未连接"})
		return
	}

	result, err := database.DB.Exec(
		"INSERT INTO common_routes (user_id, start, end, time, distance) VALUES (?, ?, ?, ?, ?)",
		req.UserID, req.Start, req.End, req.Time, req.Distance,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": "添加失败"})
		return
	}

	id, _ := result.LastInsertId()
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"id":       id,
			"userId":   req.UserID,
			"start":    req.Start,
			"end":      req.End,
			"time":     req.Time,
			"distance": req.Distance,
			"title":    req.Start + " -> " + req.End,
		},
	})
}
func DeleteCommonRoute(c *gin.Context) {
	id := c.Param("id")
	routeID, err := strconv.Atoi(id)
	if err != nil || routeID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "路线ID无效"})
		return
	}

	if database.DB == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"success": false, "error": "数据库未连接"})
		return
	}

	userID := strings.TrimSpace(c.Query("userId"))
	var result interface {
		RowsAffected() (int64, error)
	}
	if userID != "" {
		result, err = database.DB.Exec("DELETE FROM common_routes WHERE id = ? AND user_id = ?", routeID, userID)
	} else {
		result, err = database.DB.Exec("DELETE FROM common_routes WHERE id = ?", routeID)
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": "删除失败"})
		return
	}

	rowsAffected, err := result.RowsAffected()
	if err == nil && rowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "路线不存在"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "data": "删除成功"})
}

func GetDefaultConfig(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"success": true, "data": services.MetroNetworkDefaultConfig()})
}

func ListStations(c *gin.Context) {
	keyword := strings.TrimSpace(c.Query("keyword"))
	stations := services.MetroNetworkStations()
	if keyword == "" {
		c.JSON(http.StatusOK, gin.H{"success": true, "data": stations, "totalCount": len(stations)})
		return
	}

	filtered := make([]services.MetroNetworkStationDirectoryItem, 0)
	for _, station := range stations {
		if strings.Contains(station.Name, keyword) || strings.Contains(station.ID, keyword) {
			filtered = append(filtered, station)
		}
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": filtered, "totalCount": len(filtered)})
}

func ListDataLines(c *gin.Context) {
	lines := services.MetroNetworkLineSummaries()
	c.JSON(http.StatusOK, gin.H{"success": true, "data": lines, "totalCount": len(lines)})
}

func ListStationsByLine(c *gin.Context) {
	lineID := strings.TrimSpace(c.Param("lineId"))
	stations := services.MetroNetworkStationsByLine(lineID)
	if len(stations) == 0 {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "线路不存在或暂无站序数据"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": stations, "totalCount": len(stations)})
}

func SearchTransferRules(c *gin.Context) {
	rules := services.MetroNetworkSearchTransferRules(
		c.Query("keyword"),
		c.Query("originStationId"),
		c.Query("lineId"),
	)
	c.JSON(http.StatusOK, gin.H{"success": true, "data": rules, "totalCount": len(rules)})
}

func GetRoutePlanByRule(c *gin.Context) {
	ruleID := strings.TrimSpace(c.Param("ruleId"))
	route, ok := services.MetroNetworkRoutePlanForRule(ruleID)
	if !ok {
		c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "换乘规则不存在或无法生成路线"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"success": true, "data": route})
}

func ValidateData(c *gin.Context) {
	if database.DB == nil {
		networkCounts, networkErrors := services.MetroNetworkValidate()
		warnings := []string{"database is not connected, validating in-memory metro network"}
		c.JSON(http.StatusOK, gin.H{
			"success": len(networkErrors) == 0,
			"data": gin.H{
				"ok":       len(networkErrors) == 0,
				"errors":   networkErrors,
				"warnings": warnings,
				"counts":   networkCounts,
			},
		})
		return
	}

	counts := gin.H{}
	errors := []string{}
	requiredTables := []struct {
		Name string
		Min  int
	}{
		{"stations", 1},
		{"metro_lines", 1},
		{"line_stations", 1},
		{"transfer_rules", 1},
		{"static_resources", 1},
		{"travel_alerts", 1},
	}

	for _, table := range requiredTables {
		count, err := countRows(table.Name)
		if err != nil {
			errors = append(errors, table.Name+" table check failed")
			continue
		}
		counts[table.Name] = count
		if count < table.Min {
			errors = append(errors, table.Name+" has no data")
		}
	}

	referenceChecks := []struct {
		Name  string
		Query string
	}{
		{
			"line_stations_station_refs",
			`SELECT COUNT(*) FROM line_stations ls
			LEFT JOIN stations s ON s.station_id = ls.station_id
			WHERE s.station_id IS NULL`,
		},
		{
			"line_stations_line_refs",
			`SELECT COUNT(*) FROM line_stations ls
			LEFT JOIN metro_lines ml ON ml.line_id = ls.line_id
			WHERE ml.line_id IS NULL`,
		},
		{
			"transfer_rules_station_refs",
			`SELECT COUNT(*) FROM transfer_rules tr
			LEFT JOIN stations origin_station ON origin_station.station_id = tr.origin_station_id
			LEFT JOIN stations target_station ON target_station.station_id = tr.target_station_id
			WHERE origin_station.station_id IS NULL OR target_station.station_id IS NULL`,
		},
		{
			"transfer_rules_line_refs",
			`SELECT COUNT(*) FROM transfer_rules tr
			LEFT JOIN metro_lines ml ON ml.line_id = tr.line_id
			WHERE ml.line_id IS NULL`,
		},
	}

	for _, check := range referenceChecks {
		count, err := countQuery(check.Query)
		if err != nil {
			errors = append(errors, check.Name+" check failed")
			continue
		}
		counts[check.Name] = count
		if count > 0 {
			errors = append(errors, check.Name+" has broken references")
		}
	}
	networkCounts, networkErrors := services.MetroNetworkValidate()
	for key, value := range networkCounts {
		counts[key] = value
	}
	errors = append(errors, networkErrors...)

	if count, ok := counts["network_lines"].(int); ok && count < 18 {
		errors = append(errors, "network metro line coverage is incomplete")
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"ok":     len(errors) == 0,
			"errors": errors,
			"counts": counts,
		},
	})
}

func GetStaticResources(c *gin.Context) {
	if database.DB == nil {
		resources := defaultStaticResources(c.Query("type"))
		c.JSON(http.StatusOK, gin.H{"success": true, "data": resources, "totalCount": len(resources)})
		return
	}

	resourceType := strings.TrimSpace(c.Query("type"))
	query := `SELECT resource_type, resource_name, resource_path, COALESCE(description, '')
		FROM static_resources`
	args := []interface{}{}
	if resourceType != "" {
		query += " WHERE resource_type = ?"
		args = append(args, resourceType)
	}
	query += " ORDER BY resource_type, resource_name"

	rows, err := database.DB.Query(query, args...)
	if err != nil {
		c.JSON(http.StatusOK, gin.H{"success": true, "data": []gin.H{}})
		return
	}
	defer rows.Close()

	resources := []gin.H{}
	for rows.Next() {
		var itemType, name, path, description string
		if err := rows.Scan(&itemType, &name, &path, &description); err != nil {
			continue
		}
		resources = append(resources, gin.H{
			"type":        itemType,
			"name":        name,
			"path":        path,
			"description": description,
		})
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "data": resources})
}

func defaultStaticResources(resourceType string) []gin.H {
	resourceType = strings.TrimSpace(resourceType)
	resources := []gin.H{
		{"type": "icon", "name": "timer", "path": "app/assets/icons/timer.png", "description": "换乘倒计时图标"},
		{"type": "icon", "name": "transfer", "path": "app/assets/icons/transfer.png", "description": "站内换乘图标"},
		{"type": "diagram", "name": "tongji-university", "path": "backend/go/data/station_topologies/tongji_university.json", "description": "同济大学站平面换乘拓扑数据"},
		{"type": "generated-visual", "name": "station-visual", "path": "/api/station-visual", "description": "站点无真实照片时生成的平面示意图"},
	}
	if resourceType == "" {
		return resources
	}
	filtered := []gin.H{}
	for _, resource := range resources {
		if resource["type"] == resourceType {
			filtered = append(filtered, resource)
		}
	}
	return filtered
}

func countRows(tableName string) (int, error) {
	return countQuery("SELECT COUNT(*) FROM " + tableName)
}

func countQuery(query string) (int, error) {
	var count int
	err := database.DB.QueryRow(query).Scan(&count)
	return count, err
}

func GetUserPreferences(c *gin.Context) {
	userID := strings.TrimSpace(c.Param("userId"))
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "请提供用户ID"})
		return
	}

	data := defaultUserPreferences(userID)
	if database.DB == nil {
		c.JSON(http.StatusOK, gin.H{"success": true, "data": data})
		return
	}

	var themeColor, themeMode, fontSize string
	err := database.DB.QueryRow(
		`SELECT theme_color, theme_mode, font_size
		FROM user_preferences
		WHERE user_id = ?
		LIMIT 1`,
		userID,
	).Scan(&themeColor, &themeMode, &fontSize)
	if err == nil {
		data["themeColor"] = themeColor
		data["themeMode"] = themeMode
		data["fontSize"] = fontSize
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "data": data})
}

func SaveUserPreferences(c *gin.Context) {
	userID := strings.TrimSpace(c.Param("userId"))
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "请提供用户ID"})
		return
	}

	var req struct {
		ThemeColor string `json:"themeColor"`
		ThemeMode  string `json:"themeMode"`
		FontSize   string `json:"fontSize"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "设置内容格式不正确"})
		return
	}
	if database.DB == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"success": false, "error": "数据库未连接"})
		return
	}

	req.ThemeColor = allowedString(req.ThemeColor, "system", "system", "blue", "green", "purple", "orange")
	req.ThemeMode = allowedString(req.ThemeMode, "system", "system", "light", "dark")
	req.FontSize = allowedString(req.FontSize, "medium", "small", "medium", "large")

	_, err := database.DB.Exec(
		`INSERT INTO user_preferences (user_id, theme_color, theme_mode, font_size)
		VALUES (?, ?, ?, ?)
		ON DUPLICATE KEY UPDATE
			theme_color = VALUES(theme_color),
			theme_mode = VALUES(theme_mode),
			font_size = VALUES(font_size)`,
		userID, req.ThemeColor, req.ThemeMode, req.FontSize,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": "保存失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "data": gin.H{
		"userId":     userID,
		"themeColor": req.ThemeColor,
		"themeMode":  req.ThemeMode,
		"fontSize":   req.FontSize,
	}})
}

func GetUserAbilities(c *gin.Context) {
	userID := strings.TrimSpace(c.Param("userId"))
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "请提供用户ID"})
		return
	}
	if database.DB == nil {
		c.JSON(http.StatusOK, gin.H{"success": true, "data": []gin.H{}})
		return
	}

	rows, err := database.DB.Query(
		`SELECT ability_type, ability_level, COALESCE(description, '')
		FROM user_abilities
		WHERE user_id = ?
		ORDER BY ability_type`,
		userID,
	)
	if err != nil {
		c.JSON(http.StatusOK, gin.H{"success": true, "data": []gin.H{}})
		return
	}
	defer rows.Close()

	abilities := []gin.H{}
	for rows.Next() {
		var abilityType, description string
		var abilityLevel int
		if err := rows.Scan(&abilityType, &abilityLevel, &description); err != nil {
			continue
		}
		abilities = append(abilities, gin.H{
			"type":        abilityType,
			"level":       abilityLevel,
			"description": description,
		})
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "data": abilities})
}

func SaveUserAbility(c *gin.Context) {
	userID := strings.TrimSpace(c.Param("userId"))
	abilityType := strings.TrimSpace(c.Param("abilityType"))
	if userID == "" || abilityType == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "请提供用户ID和能力类型"})
		return
	}

	var req struct {
		Level       int    `json:"level"`
		Description string `json:"description"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "能力设置格式不正确"})
		return
	}
	if req.Level < 0 || req.Level > 5 {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "能力等级需在0到5之间"})
		return
	}
	req.Description = strings.TrimSpace(req.Description)
	if len(req.Description) > 500 {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "能力描述过长"})
		return
	}
	if database.DB == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"success": false, "error": "数据库未连接"})
		return
	}

	_, err := database.DB.Exec(
		`INSERT INTO user_abilities (user_id, ability_type, ability_level, description)
		VALUES (?, ?, ?, ?)
		ON DUPLICATE KEY UPDATE
			ability_level = VALUES(ability_level),
			description = VALUES(description)`,
		userID, abilityType, req.Level, req.Description,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": "保存失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "data": gin.H{
		"userId":      userID,
		"type":        abilityType,
		"level":       req.Level,
		"description": req.Description,
	}})
}

func GetUserLuggage(c *gin.Context) {
	userID := strings.TrimSpace(c.Param("userId"))
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "请提供用户ID"})
		return
	}
	if database.DB == nil {
		c.JSON(http.StatusOK, gin.H{"success": true, "data": []gin.H{}})
		return
	}

	rows, err := database.DB.Query(
		`SELECT luggage_type, COALESCE(weight, ''), COALESCE(size, '')
		FROM user_luggage
		WHERE user_id = ?
		ORDER BY luggage_type`,
		userID,
	)
	if err != nil {
		c.JSON(http.StatusOK, gin.H{"success": true, "data": []gin.H{}})
		return
	}
	defer rows.Close()

	luggage := []gin.H{}
	for rows.Next() {
		var luggageType, weight, size string
		if err := rows.Scan(&luggageType, &weight, &size); err != nil {
			continue
		}
		luggage = append(luggage, gin.H{
			"type":   luggageType,
			"weight": weight,
			"size":   size,
		})
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "data": luggage})
}

func SaveUserLuggage(c *gin.Context) {
	userID := strings.TrimSpace(c.Param("userId"))
	luggageType := strings.TrimSpace(c.Param("luggageType"))
	if userID == "" || luggageType == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "请提供用户ID和行李类型"})
		return
	}

	var req struct {
		Weight string `json:"weight"`
		Size   string `json:"size"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "行李设置格式不正确"})
		return
	}
	req.Weight = strings.TrimSpace(req.Weight)
	req.Size = allowedString(req.Size, "", "", "small", "medium", "large")
	if len(req.Weight) > 50 {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "行李重量描述过长"})
		return
	}
	if database.DB == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"success": false, "error": "数据库未连接"})
		return
	}

	_, err := database.DB.Exec(
		`INSERT INTO user_luggage (user_id, luggage_type, weight, size)
		VALUES (?, ?, ?, ?)
		ON DUPLICATE KEY UPDATE
			weight = VALUES(weight),
			size = VALUES(size)`,
		userID, luggageType, req.Weight, req.Size,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": "保存失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "data": gin.H{
		"userId": userID,
		"type":   luggageType,
		"weight": req.Weight,
		"size":   req.Size,
	}})
}

func defaultUserPreferences(userID string) gin.H {
	return gin.H{
		"userId":     userID,
		"themeColor": "system",
		"themeMode":  "system",
		"fontSize":   "medium",
	}
}

func allowedString(value, fallback string, allowed ...string) string {
	value = strings.TrimSpace(value)
	for _, item := range allowed {
		if value == item {
			return value
		}
	}
	return fallback
}

func DeleteUserData(c *gin.Context) {
	userID := strings.TrimSpace(c.Param("userId"))
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "请提供用户ID"})
		return
	}
	if database.DB == nil {
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"data": gin.H{
				"userId":  userID,
				"deleted": true,
				"message": "演示模式未保存真实用户数据",
			},
		})
		return
	}

	tables := []string{"user_preferences", "user_abilities", "user_luggage", "common_routes"}
	deletedRows := int64(0)
	for _, table := range tables {
		result, err := database.DB.Exec("DELETE FROM "+table+" WHERE user_id = ?", userID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": "用户数据删除失败"})
			return
		}
		if rows, err := result.RowsAffected(); err == nil {
			deletedRows += rows
		}
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "data": gin.H{
		"userId":      userID,
		"deleted":     true,
		"deletedRows": deletedRows,
	}})
}

func AnonymizeUserData(c *gin.Context) {
	userID := strings.TrimSpace(c.Param("userId"))
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "请提供用户ID"})
		return
	}
	anonymousID := fmt.Sprintf("anonymous_%d", time.Now().UnixNano())
	if database.DB == nil {
		c.JSON(http.StatusOK, gin.H{"success": true, "data": gin.H{
			"originalUserId":  userID,
			"anonymousUserId": anonymousID,
			"message":         "演示模式未保存真实用户数据",
		}})
		return
	}

	tables := []string{"user_preferences", "user_abilities", "user_luggage", "common_routes"}
	updatedRows := int64(0)
	for _, table := range tables {
		result, err := database.DB.Exec("UPDATE "+table+" SET user_id = ? WHERE user_id = ?", anonymousID, userID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": "用户数据匿名化失败"})
			return
		}
		if rows, err := result.RowsAffected(); err == nil {
			updatedRows += rows
		}
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "data": gin.H{
		"originalUserId":  userID,
		"anonymousUserId": anonymousID,
		"updatedRows":     updatedRows,
	}})
}

func GetTrainInfo(c *gin.Context) {
	trainNumber := c.Param("trainNumber")

	if database.DB != nil {
		train, err := getTrainInfoFromDB(trainNumber)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "车次不存在"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"success": true, "data": train})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "data": defaultTrainInfo(trainNumber)})
}

func getTrainInfoFromDB(trainNumber string) (gin.H, error) {
	var id int
	var number, start, end, departure, arrival, platform, doorDirection string
	err := database.DB.QueryRow(
		`SELECT id, number, start, end, departure, arrival, platform, door_direction
		FROM trains
		WHERE number = ?
		LIMIT 1`,
		trainNumber,
	).Scan(&id, &number, &start, &end, &departure, &arrival, &platform, &doorDirection)
	if err != nil {
		return nil, err
	}

	stations := []gin.H{}
	stationRows, err := database.DB.Query(
		`SELECT station_name, station_order
		FROM train_stations
		WHERE train_id = ?
		ORDER BY station_order`,
		id,
	)
	if err == nil {
		defer stationRows.Close()
		for stationRows.Next() {
			var stationName string
			var stationOrder int
			if scanErr := stationRows.Scan(&stationName, &stationOrder); scanErr == nil {
				stations = append(stations, gin.H{"name": stationName, "order": stationOrder})
			}
		}
	}

	carriages := []gin.H{}
	carriageRows, err := database.DB.Query(
		`SELECT carriage_number, COALESCE(carriage_type, ''), COALESCE(distance, '')
		FROM train_carriages
		WHERE train_id = ?
		ORDER BY carriage_number`,
		id,
	)
	if err == nil {
		defer carriageRows.Close()
		for carriageRows.Next() {
			var carriageNumber, carriageType, distance string
			if scanErr := carriageRows.Scan(&carriageNumber, &carriageType, &distance); scanErr == nil {
				carriages = append(carriages, gin.H{
					"number":   carriageNumber,
					"type":     carriageType,
					"distance": distance,
				})
			}
		}
	}

	return gin.H{
		"trainNumber":   number,
		"start":         start,
		"end":           end,
		"departure":     departure,
		"arrival":       arrival,
		"platform":      platform,
		"doorDirection": doorDirection,
		"stations":      stations,
		"carriages":     carriages,
		"source":        "database",
	}, nil
}

func GetTrainGuide(c *gin.Context) {
	var req struct {
		TrainNumber     string `json:"trainNumber" binding:"required"`
		Destination     string `json:"destination" binding:"required"`
		CurrentCarriage string `json:"currentCarriage" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "请提供完整信息"})
		return
	}

	if database.DB != nil {
		guide, err := getTrainGuideFromDB(req.TrainNumber, req.Destination, req.CurrentCarriage)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "未找到匹配车次或车厢信息"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"success": true, "data": guide})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "data": defaultTrainGuide(req.TrainNumber, req.Destination, req.CurrentCarriage)})
}

func getTrainGuideFromDB(trainNumber, destination, currentCarriage string) (gin.H, error) {
	train, err := getTrainInfoFromDB(trainNumber)
	if err != nil {
		return nil, err
	}

	var carriageType, carriageDistance string
	err = database.DB.QueryRow(
		`SELECT COALESCE(carriage_type, ''), COALESCE(distance, '')
		FROM train_carriages tc
		JOIN trains t ON t.id = tc.train_id
		WHERE t.number = ? AND tc.carriage_number = ?
		LIMIT 1`,
		trainNumber,
		currentCarriage,
	).Scan(&carriageType, &carriageDistance)
	if err != nil {
		return nil, err
	}

	stations, _ := train["stations"].([]gin.H)
	destinationFound := false
	for _, station := range stations {
		if station["name"] == destination {
			destinationFound = true
			break
		}
	}

	tips := []string{
		fmt.Sprintf("当前车厢%s为%s，%s。", currentCarriage, defaultDisplay(carriageType, "普通车厢"), defaultDisplay(carriageDistance, "请按站台导向前往")),
		fmt.Sprintf("本车次站台为%s，%s。", train["platform"], train["doorDirection"]),
	}
	if destinationFound {
		tips = append(tips, fmt.Sprintf("车次%s途经%s，请留意到站广播。", trainNumber, destination))
	} else {
		tips = append(tips, fmt.Sprintf("数据库未记录%s为本车次途经站，请核对车票信息。", destination))
	}

	return gin.H{
		"trainNumber":     trainNumber,
		"destination":     destination,
		"currentCarriage": currentCarriage,
		"carriageType":    carriageType,
		"distance":        carriageDistance,
		"platform":        train["platform"],
		"doorDirection":   train["doorDirection"],
		"stations":        train["stations"],
		"tips":            tips,
		"guide":           strings.Join(tips, " "),
		"source":          "database",
	}, nil
}

func defaultDisplay(value, fallback string) string {
	if value == "" {
		return fallback
	}
	return value
}

func defaultTrainInfo(trainNumber string) gin.H {
	if strings.TrimSpace(trainNumber) == "" {
		trainNumber = "G7501"
	}
	sample := map[string]gin.H{
		"G7501": {
			"trainNumber":   "G7501",
			"start":         "南京南",
			"end":           "上海虹桥",
			"departure":     "08:12",
			"arrival":       "09:39",
			"platform":      "上海虹桥到达层",
			"doorDirection": "出站后按地铁2号线、10号线、17号线标识前往地铁换乘大厅",
			"stations": []gin.H{
				{"name": "南京南", "order": 1},
				{"name": "镇江南", "order": 2},
				{"name": "常州北", "order": 3},
				{"name": "无锡东", "order": 4},
				{"name": "苏州北", "order": 5},
				{"name": "上海虹桥", "order": 6},
			},
			"carriages": []gin.H{
				{"number": "01", "type": "商务/一等座", "distance": "靠近北侧扶梯，适合快速换乘地铁"},
				{"number": "08", "type": "二等座", "distance": "到达后按中部通道出站"},
				{"number": "16", "type": "二等座", "distance": "靠近南侧出口，行李较多建议走电梯"},
			},
			"source": "local-demo",
		},
		"G7347": {
			"trainNumber":   "G7347",
			"start":         "杭州东",
			"end":           "上海虹桥",
			"departure":     "17:05",
			"arrival":       "18:02",
			"platform":      "上海虹桥到达层",
			"doorDirection": "出闸后优先看地铁换乘大厅指示牌",
			"stations": []gin.H{
				{"name": "杭州东", "order": 1},
				{"name": "嘉兴南", "order": 2},
				{"name": "松江南", "order": 3},
				{"name": "上海虹桥", "order": 4},
			},
			"carriages": []gin.H{
				{"number": "03", "type": "一等座", "distance": "靠近扶梯，适合赶时间用户"},
				{"number": "09", "type": "二等座", "distance": "中部车厢，前往地铁换乘较均衡"},
				{"number": "15", "type": "二等座", "distance": "行李较多建议跟随电梯标识"},
			},
			"source": "local-demo",
		},
	}
	if train, ok := sample[strings.ToUpper(trainNumber)]; ok {
		return train
	}
	train := sample["G7501"]
	train["trainNumber"] = trainNumber
	return train
}

func defaultTrainGuide(trainNumber, destination, currentCarriage string) gin.H {
	train := defaultTrainInfo(trainNumber)
	carriageHint := "中部通道"
	for _, item := range train["carriages"].([]gin.H) {
		if item["number"] == currentCarriage {
			carriageHint = fmt.Sprint(item["distance"])
			break
		}
	}
	if strings.TrimSpace(destination) == "" {
		destination = "上海虹桥"
	}
	tips := []string{
		fmt.Sprintf("当前车厢%s：%s。", defaultDisplay(currentCarriage, "08"), carriageHint),
		"下车后先跟随“地铁 / Metro”标识前往换乘大厅。",
		"赶时间去10号线，可优先走中部扶梯；行李较多建议走无障碍电梯。",
		fmt.Sprintf("目标站为%s，请留意站台电子屏和到站广播。", destination),
	}
	return gin.H{
		"trainNumber":     train["trainNumber"],
		"destination":     destination,
		"currentCarriage": currentCarriage,
		"platform":        train["platform"],
		"doorDirection":   train["doorDirection"],
		"stations":        train["stations"],
		"tips":            tips,
		"guide":           strings.Join(tips, " "),
		"source":          "local-demo",
	}
}

func GetTravelAlerts(c *gin.Context) {
	alertType := c.Param("type")

	if database.DB == nil {
		c.JSON(http.StatusOK, defaultTravelAlerts())
		return
	}

	query := "SELECT id, type, title, message, created_at FROM travel_alerts"
	args := []interface{}{}
	if alertType != "" {
		query += " WHERE type = ?"
		args = append(args, alertType)
	}
	query += " ORDER BY created_at DESC"

	rows, err := database.DB.Query(query, args...)
	if err != nil {
		c.JSON(http.StatusOK, defaultTravelAlerts())
		return
	}
	defer rows.Close()

	alerts := []gin.H{}
	for rows.Next() {
		var id int
		var alertTypeStr, title, message string
		var createdAt string
		if err := rows.Scan(&id, &alertTypeStr, &title, &message, &createdAt); err != nil {
			continue
		}
		title = cleanDisplayText(title, "10号线运行正常")
		message = cleanDisplayText(message, "当前线路运行平稳，请留意站内广播和导向标识。")
		alerts = append(alerts, gin.H{
			"id":        id,
			"alertId":   fmt.Sprintf("alert_%d", id),
			"title":     title,
			"content":   message,
			"type":      alertTypeStr,
			"severity":  "info",
			"createdAt": createdAt,
		})
	}
	if len(alerts) == 0 {
		alerts = defaultTravelAlerts()
	}

	c.JSON(http.StatusOK, alerts)
}

func defaultTravelAlerts() []gin.H {
	return []gin.H{
		{
			"id":        0,
			"alertId":   "demo_alert_normal",
			"title":     "10号线运行正常",
			"content":   "当前线路运行平稳，请按站内导向有序通行。",
			"type":      "service",
			"severity":  "info",
			"createdAt": "",
		},
	}
}

func cleanDisplayText(value string, fallback string) string {
	value = strings.TrimSpace(value)
	if value == "" || !utf8.ValidString(value) || looksLikeMojibake(value) {
		return fallback
	}
	return value
}

func looksLikeMojibake(value string) bool {
	markers := []string{"Ã", "Â", "å", "ç", "æ", "é", "è", "ï"}
	hits := 0
	for _, marker := range markers {
		if strings.Contains(value, marker) {
			hits++
		}
	}
	return hits >= 2
}
func HealthCheck(c *gin.Context) {
	connected := database.IsConnected()
	mode := "mock"
	if connected {
		mode = "database"
	}

	c.JSON(http.StatusOK, gin.H{
		"status":     "ok",
		"mode":       mode,
		"database":   connected,
		"service":    "smart-travel-backend",
		"apiVersion": "v1",
	})
}

func SubmitFeedback(c *gin.Context) {
	var req struct {
		Type        string `json:"type" binding:"required"`
		Description string `json:"description" binding:"required"`
		Contact     string `json:"contact"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   "请提供完整的反馈信息",
		})
		return
	}

	if database.DB != nil {
		_, _ = database.DB.Exec(`CREATE TABLE IF NOT EXISTS feedbacks (
			id INT AUTO_INCREMENT PRIMARY KEY,
			type VARCHAR(100) NOT NULL,
			description TEXT NOT NULL,
			contact VARCHAR(255) DEFAULT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`)

		_, err := database.DB.Exec(
			"INSERT INTO feedbacks (type, description, contact) VALUES (?, ?, ?)",
			req.Type, req.Description, req.Contact,
		)
		if err != nil {
			fmt.Printf("反馈写入数据库失败: %v\n", err)
		}
	} else {
		fmt.Printf("模拟模式 - 收到反馈: 类型=%s, 描述=%s, 联系方式=%s\n", req.Type, req.Description, req.Contact)
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "感谢您的反馈，我们会尽快处理。",
	})
}
