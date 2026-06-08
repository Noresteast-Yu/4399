package handlers

import (
	"fmt"
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
			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error":   "站点不存在",
			})
			return
		}
	} else {
		station, err = services.FindStationByID(stationID)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{
				"success": false,
				"error":   "站点不存在",
			})
			return
		}
	}

	facility, _ := services.GetStationFacilityInfo(stationID)

	lines := services.GetStationLineNames(stationID)

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

type stationExitResponse struct {
	ID           string `json:"id"`
	Name         string `json:"name"`
	Label        string `json:"label"`
	Detail       string `json:"detail"`
	NearbyPlace  string `json:"nearbyPlace"`
	GuideTip     string `json:"guideTip"`
	IsAccessible bool   `json:"isAccessible"`
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
	default:
		return stationExitChoices([][3]string{
			{"1", "1号口", "默认出站口"},
			{"2", "2号口", "备用出站口"},
		})
	}
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
		c.JSON(http.StatusOK, defaultMetroLines())
		return
	}

	rows, err := database.DB.Query("SELECT line_id, line_name, color_hex FROM metro_lines")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"error":   "查询失败",
		})
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
		c.JSON(http.StatusOK, []gin.H{})
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

func ValidateData(c *gin.Context) {
	if database.DB == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"success": false,
			"data": gin.H{
				"ok":     false,
				"errors": []string{"database is not connected"},
				"counts": gin.H{},
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
		c.JSON(http.StatusOK, gin.H{"success": true, "data": []gin.H{}})
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

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    gin.H{"trainNumber": trainNumber, "info": "高铁信息查询功能待实现", "source": "mock"},
	})
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

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"trainNumber": req.TrainNumber,
			"destination": req.Destination,
			"guide":       "换乘引导功能待实现",
			"source":      "mock",
		},
	})
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
