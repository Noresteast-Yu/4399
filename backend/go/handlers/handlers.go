package handlers

import (
	"fmt"
	"net/http"

	"smart-travel-backend/database"
	"smart-travel-backend/models"
	"smart-travel-backend/services"

	"github.com/gin-gonic/gin"
)

func PlanRoute(c *gin.Context) {
	var req struct {
		Start       string                 `json:"start" binding:"required"`
		End         string                 `json:"end" binding:"required"`
		Preferences map[string]interface{} `json:"preferences"`
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
			"SELECT * FROM stations WHERE station_id = ? LIMIT 1",
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
		c.JSON(http.StatusOK, []gin.H{})
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

func GetCommonRoutes(c *gin.Context) {
	userID := c.Param("userId")
	_ = userID

	if database.DB == nil {
		c.JSON(http.StatusOK, []gin.H{})
		return
	}

	rows, err := database.DB.Query("SELECT id, start, end FROM common_routes ORDER BY id DESC")
	if err != nil {
		c.JSON(http.StatusOK, []gin.H{})
		return
	}
	defer rows.Close()

	routes := []gin.H{}
	for rows.Next() {
		var id int
		var start, end string
		if err := rows.Scan(&id, &start, &end); err != nil {
			continue
		}
		routes = append(routes, gin.H{
			"id":    id,
			"start": start,
			"end":   end,
			"title": start + " -> " + end,
		})
	}

	c.JSON(http.StatusOK, routes)
}
func AddCommonRoute(c *gin.Context) {
	var req struct {
		UserID string `json:"userId"`
		Start  string `json:"start" binding:"required"`
		End    string `json:"end" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "请提供起点和终点"})
		return
	}

	if database.DB == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"success": false, "error": "数据库未连接"})
		return
	}

	result, err := database.DB.Exec(
		"INSERT INTO common_routes (user_id, start, end) VALUES (?, ?, ?)",
		req.UserID, req.Start, req.End,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": "添加失败"})
		return
	}

	id, _ := result.LastInsertId()
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    gin.H{"id": id, "start": req.Start, "end": req.End, "title": req.Start + " -> " + req.End},
	})
}
func DeleteCommonRoute(c *gin.Context) {
	id := c.Param("id")

	_, err := database.DB.Exec("DELETE FROM common_routes WHERE id = ?", id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": "删除失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true, "data": "删除成功"})
}

func GetTrainInfo(c *gin.Context) {
	trainNumber := c.Param("trainNumber")
	_ = trainNumber

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    gin.H{"trainNumber": trainNumber, "info": "高铁信息查询功能待实现"},
	})
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

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"trainNumber": req.TrainNumber,
			"destination": req.Destination,
			"guide":       "换乘引导功能待实现",
		},
	})
}

func StartTransfer(c *gin.Context) {
	var req struct {
		From          string `json:"from" binding:"required"`
		To            string `json:"to" binding:"required"`
		RemainingTime int    `json:"remainingTime"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "请提供完整信息"})
		return
	}

	if req.RemainingTime == 0 {
		req.RemainingTime = 300
	}

	sessionID := "session_" + req.From + "_" + req.To

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"sessionId":     sessionID,
			"from":          req.From,
			"to":            req.To,
			"remainingTime": req.RemainingTime,
		},
	})
}

func GetTransferUpdate(c *gin.Context) {
	sessionID := c.Param("sessionId")
	_ = sessionID

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"sessionId":     sessionID,
			"remainingTime": 0,
			"status":        "completed",
		},
	})
}

func GetTravelAlerts(c *gin.Context) {
	alertType := c.Param("type")

	if database.DB == nil {
		c.JSON(http.StatusOK, []gin.H{})
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
		c.JSON(http.StatusOK, []gin.H{})
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

	c.JSON(http.StatusOK, alerts)
}
func HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status": "ok",
		"mode":   "database",
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
