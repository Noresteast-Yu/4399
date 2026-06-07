package services

import (
	"bytes"
	"crypto/sha1"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"smart-travel-backend/config"
)

const shmaasArrivalPath = "/api/v1/bst/getMetroStopArriveDetails"

type MetroArrivalQuery struct {
	LineID    string
	LineName  string
	StopID    string
	StopName  string
	Direction string
	CityCode  string
}

type MetroArrivalResult struct {
	StationName          string `json:"stationName"`
	LineName             string `json:"lineName"`
	Direction            string `json:"direction"`
	Interval             string `json:"interval"`
	CurrentArriveMinutes int    `json:"currentArriveMinutes"`
	NextArriveMinutes    int    `json:"nextArriveMinutes"`
	StopCount            int    `json:"stopCount"`
	Comfort              int    `json:"comfort"`
	TrainID              string `json:"trainId,omitempty"`
	TrainLocation        string `json:"trainLocation,omitempty"`
	TrainNextStop        string `json:"trainNextStop,omitempty"`
	ActiveTrainCount     int    `json:"activeTrainCount,omitempty"`
	ServicePlan          string `json:"servicePlan,omitempty"`
	Source               string `json:"source"`
}

type shmaasEnvelope struct {
	RetCode string                 `json:"retCode"`
	RetMsg  string                 `json:"retMsg"`
	Data    map[string]interface{} `json:"data"`
}

var metroStopIDMap = map[string]string{
	"shanghai_hongqiao_railway_station": "mock-l10-hongqiao-railway",
	"hongqiao_railway_10":               "mock-l10-hongqiao-railway",
	"hongqiao_terminal_2":               "mock-l10-hongqiao-t2",
	"hongqiao_t2_10":                    "mock-l10-hongqiao-t2",
	"hangzhong_road":                    "mock-l10-hangzhong-road",
	"wujiaochang":                       "mock-l10-wujiaochang",
	"wujiaochang_10":                    "mock-l10-wujiaochang",
	"tongji_university":                 "mock-l10-tongji-university",
	"tong_ji_university":                "mock-l10-tongji-university",
	"tongji_university_10":              "mock-l10-tongji-university",
}

func QueryMetroArrival(query MetroArrivalQuery) (*MetroArrivalResult, error) {
	body := map[string]interface{}{
		"lineId":    normalizeMetroLineID(query.LineID),
		"lineName":  defaultString(query.LineName, "10号线"),
		"stopId":    normalizeMetroStopID(query.StopID),
		"stopName":  query.StopName,
		"direction": defaultString(query.Direction, "0"),
		"cityCode":  defaultString(query.CityCode, shmaasCityCode()),
	}

	env, err := callShmaas(shmaasArrivalPath, body)
	if err != nil {
		return mockMetroArrival(query, "local-demo"), nil
	}

	info, _ := env.Data["stopArriveInfo"].(map[string]interface{})
	if len(info) == 0 {
		return mockMetroArrival(query, "local-demo"), nil
	}
	return &MetroArrivalResult{
		StationName:          defaultString(stringValue(info["stopName"]), defaultString(query.StopName, "当前站点")),
		LineName:             stringValue(body["lineName"]),
		Direction:            defaultString(stringValue(info["upDown"]), directionLabel(query.Direction)),
		Interval:             defaultString(stringValue(env.Data["interval"]), "约4分钟"),
		CurrentArriveMinutes: intValue(info["currentBusArriveTime"]),
		NextArriveMinutes:    intValue(info["nextBusArriveTime"]),
		StopCount:            intValue(info["currentBusStopCount"]),
		Comfort:              intValue(info["currentBusComfort"]),
		TrainID:              stringValue(info["mockTrainId"]),
		TrainLocation:        stringValue(info["mockTrainLocation"]),
		TrainNextStop:        stringValue(info["mockTrainNextStop"]),
		ActiveTrainCount:     intValue(info["mockActiveTrainCount"]),
		ServicePlan:          stringValue(info["mockServicePlan"]),
		Source:               "shmaas-mock",
	}, nil
}

func mockMetroArrival(query MetroArrivalQuery, source string) *MetroArrivalResult {
	direction := defaultString(query.Direction, "0")
	base := 3
	if direction == "1" {
		base = 4
	}
	if strings.Contains(query.StopID, "wujiaochang") || strings.Contains(query.StopName, "五角场") {
		base++
	}

	stationName := defaultString(query.StopName, "当前站点")
	lineName := defaultString(query.LineName, "10号线")
	return &MetroArrivalResult{
		StationName:          stationName,
		LineName:             lineName,
		Direction:            directionLabel(direction),
		Interval:             "约4分钟",
		CurrentArriveMinutes: base,
		NextArriveMinutes:    base + 5,
		StopCount:            maxInt(1, base-1),
		Comfort:              72,
		TrainID:              "demo-train-" + direction,
		TrainLocation:        previousDemoStop(stationName),
		TrainNextStop:        stationName,
		ActiveTrainCount:     2,
		ServicePlan:          "演示数据，非官方实时运营信息",
		Source:               source,
	}
}

func directionLabel(direction string) string {
	if direction == "1" {
		return "反方向"
	}
	return "往基隆路"
}

func previousDemoStop(stationName string) string {
	switch stationName {
	case "五角场":
		return "江湾体育场"
	case "同济大学":
		return "四平路"
	case "虹桥火车站":
		return "始发站"
	default:
		return "上一站"
	}
}

func shmaasCityCode() string {
	if config.AppConfig == nil {
		return "mock-shanghai"
	}
	return config.AppConfig.ShmaasCityCode
}

func maxInt(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func callShmaas(endpoint string, body map[string]interface{}) (*shmaasEnvelope, error) {
	bodyJSON, err := json.Marshal(body)
	if err != nil {
		return nil, err
	}

	timestamp := shanghaiTimestamp(time.Now())
	salt := "mock-salt"
	host := "http://127.0.0.1:8787"
	merchantID := "mock-merchant"
	if config.AppConfig != nil {
		salt = config.AppConfig.ShmaasSalt
		host = strings.TrimRight(config.AppConfig.ShmaasHost, "/")
		merchantID = config.AppConfig.ShmaasMerchantID
	}
	sign := shmaasSign(string(bodyJSON), timestamp, salt)

	req, err := http.NewRequest(http.MethodPost, host+endpoint, bytes.NewReader(bodyJSON))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Sign", sign)
	req.Header.Set("X-SignAlgorithm", "1")
	req.Header.Set("X-Timestamp", timestamp)
	req.Header.Set("X-MerchantId", merchantID)

	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var env shmaasEnvelope
	if err := json.NewDecoder(resp.Body).Decode(&env); err != nil {
		return nil, err
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("shmaas http status %d", resp.StatusCode)
	}
	if env.RetCode != "" && env.RetCode != "000000" {
		return nil, fmt.Errorf("shmaas error %s: %s", env.RetCode, env.RetMsg)
	}
	if env.Data == nil {
		env.Data = map[string]interface{}{}
	}
	return &env, nil
}

func shmaasSign(bodyJSON string, timestamp string, salt string) string {
	sum := sha1.Sum([]byte(bodyJSON + timestamp + salt))
	return hex.EncodeToString(sum[:])
}

func shanghaiTimestamp(t time.Time) string {
	loc, err := time.LoadLocation("Asia/Shanghai")
	if err == nil {
		t = t.In(loc)
	}
	return t.Format("20060102150405")
}

func normalizeMetroLineID(lineID string) string {
	switch lineID {
	case "", "10", "shanghai_metro_line_10":
		return "mock-line-10"
	default:
		return lineID
	}
}

func normalizeMetroStopID(stopID string) string {
	if mapped, ok := metroStopIDMap[stopID]; ok {
		return mapped
	}
	return stopID
}

func defaultString(value string, fallback string) string {
	if value == "" {
		return fallback
	}
	return value
}

func stringValue(value interface{}) string {
	switch v := value.(type) {
	case string:
		return v
	case float64:
		return fmt.Sprintf("%.0f", v)
	case int:
		return fmt.Sprintf("%d", v)
	default:
		return ""
	}
}

func intValue(value interface{}) int {
	switch v := value.(type) {
	case int:
		return v
	case float64:
		return int(v)
	case string:
		var out int
		fmt.Sscanf(v, "%d", &out)
		return out
	default:
		return 0
	}
}
