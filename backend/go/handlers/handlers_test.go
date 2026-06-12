package handlers

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"testing"

	"smart-travel-backend/database"

	"github.com/gin-gonic/gin"
)

func TestPlanRouteRejectsMissingEnd(t *testing.T) {
	gin.SetMode(gin.TestMode)

	router := gin.New()
	router.POST("/api/route-plan/plan", PlanRoute)

	req := httptest.NewRequest(http.MethodPost, "/api/route-plan/plan", bytes.NewBufferString(`{"start":"虹桥火车站"}`))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusBadRequest, rec.Code, rec.Body.String())
	}
}

func TestDeleteCommonRouteWithoutDatabaseReturnsServiceUnavailable(t *testing.T) {
	gin.SetMode(gin.TestMode)
	database.DB = nil

	router := gin.New()
	router.DELETE("/api/common-routes/:id", DeleteCommonRoute)

	req := httptest.NewRequest(http.MethodDelete, "/api/common-routes/1", nil)
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusServiceUnavailable, rec.Code, rec.Body.String())
	}
}

func TestGetMetroArrivalFallsBackToLocalDemo(t *testing.T) {
	gin.SetMode(gin.TestMode)

	router := gin.New()
	router.GET("/api/metro/arrival", GetMetroArrival)

	req := httptest.NewRequest(http.MethodGet, "/api/metro/arrival?stopId=mock-l10-wujiaochang&stopName=五角场&lineName=10号线&direction=0", nil)
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusOK, rec.Code, rec.Body.String())
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(`"source":"local-demo"`)) {
		t.Fatalf("expected local demo fallback body, got %s", rec.Body.String())
	}
}

func TestGetLinesWithoutDatabaseReturnsDemoLines(t *testing.T) {
	gin.SetMode(gin.TestMode)
	database.DB = nil

	router := gin.New()
	router.GET("/api/subway-service/lines", GetLines)

	req := httptest.NewRequest(http.MethodGet, "/api/subway-service/lines", nil)
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusOK, rec.Code, rec.Body.String())
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(`"name":"10号线"`)) {
		t.Fatalf("expected demo metro lines, got %s", rec.Body.String())
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(`"name":"18号线"`)) ||
		!bytes.Contains(rec.Body.Bytes(), []byte(`"stations"`)) ||
		!bytes.Contains(rec.Body.Bytes(), []byte(`"firstTrain"`)) {
		t.Fatalf("expected full metro line summaries, got %s", rec.Body.String())
	}
}

func TestGetStationExitsWithoutDatabaseReturnsDemoExits(t *testing.T) {
	gin.SetMode(gin.TestMode)
	database.DB = nil

	router := gin.New()
	router.GET("/api/subway-service/station/:stationId/exits", GetStationExits)

	req := httptest.NewRequest(http.MethodGet, "/api/subway-service/station/tongji_university/exits", nil)
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusOK, rec.Code, rec.Body.String())
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(`"name":"5号口"`)) {
		t.Fatalf("expected tongji demo exits, got %s", rec.Body.String())
	}
}

func TestGetNearestStationWithoutDatabaseReturnsEntrance(t *testing.T) {
	gin.SetMode(gin.TestMode)
	database.DB = nil

	router := gin.New()
	router.GET("/api/location/nearest-station", GetNearestStation)

	req := httptest.NewRequest(http.MethodGet, "/api/location/nearest-station?lat=31.2821&lng=121.5063", nil)
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusOK, rec.Code, rec.Body.String())
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(`"stationName":"同济大学"`)) {
		t.Fatalf("expected tongji nearest station, got %s", rec.Body.String())
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(`"recommendedEntrance"`)) {
		t.Fatalf("expected recommended entrance, got %s", rec.Body.String())
	}
}

func TestParseAssistantDestinationMatchesStation(t *testing.T) {
	gin.SetMode(gin.TestMode)

	router := gin.New()
	router.POST("/api/assistant/parse-destination", ParseAssistantDestination)

	req := httptest.NewRequest(http.MethodPost, "/api/assistant/parse-destination", bytes.NewBufferString(`{"text":"帮我导航到浦东国际机场"}`))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusOK, rec.Code, rec.Body.String())
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(`"stationName":"浦东国际机场"`)) {
		t.Fatalf("expected pudong airport destination, got %s", rec.Body.String())
	}
}

func TestParseAssistantDestinationRejectsEmptyBody(t *testing.T) {
	gin.SetMode(gin.TestMode)

	router := gin.New()
	router.POST("/api/assistant/parse-destination", ParseAssistantDestination)

	req := httptest.NewRequest(http.MethodPost, "/api/assistant/parse-destination", bytes.NewBufferString(`{}`))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusBadRequest, rec.Code, rec.Body.String())
	}
}

func TestSaveAssistantSessionWithoutDatabaseReturnsOk(t *testing.T) {
	gin.SetMode(gin.TestMode)
	database.DB = nil

	router := gin.New()
	router.POST("/api/assistant/sessions", SaveAssistantSession)

	body := `{"startStation":"同济大学","startEntrance":"5号口","endStation":"浦东国际机场","endExit":"1号口","parsedDestination":"浦东国际机场"}`
	req := httptest.NewRequest(http.MethodPost, "/api/assistant/sessions", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusOK, rec.Code, rec.Body.String())
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(`"saved":false`)) {
		t.Fatalf("expected demo save response, got %s", rec.Body.String())
	}
}

func TestGetAssistantSessionsWithoutDatabaseReturnsEmptyList(t *testing.T) {
	gin.SetMode(gin.TestMode)
	database.DB = nil

	router := gin.New()
	router.GET("/api/assistant/sessions", GetAssistantSessions)

	req := httptest.NewRequest(http.MethodGet, "/api/assistant/sessions?userId=default", nil)
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusOK, rec.Code, rec.Body.String())
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(`"data":[]`)) {
		t.Fatalf("expected empty session list, got %s", rec.Body.String())
	}
}

func TestGetStationExitsGeneratesNetworkStationChoices(t *testing.T) {
	gin.SetMode(gin.TestMode)
	database.DB = nil

	router := gin.New()
	router.GET("/api/subway-service/station/:stationId/exits", GetStationExits)

	req := httptest.NewRequest(http.MethodGet, "/api/subway-service/station/shanghai_railway_1/exits", nil)
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", rec.Code)
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(`"totalCount":5`)) {
		t.Fatalf("expected generated exits, got %s", rec.Body.String())
	}
	if bytes.Contains(rec.Body.Bytes(), []byte("默认出站口")) {
		t.Fatalf("expected no default exit labels, got %s", rec.Body.String())
	}
}

func TestGetStationVisualReturnsPNG(t *testing.T) {
	gin.SetMode(gin.TestMode)

	router := gin.New()
	router.GET("/api/station-visual", GetStationVisual)

	req := httptest.NewRequest(http.MethodGet, "/api/station-visual?station=test&line=10号线&stage=ride&color=B07AB2", nil)
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", rec.Code)
	}
	if rec.Header().Get("Content-Type") != "image/png" {
		t.Fatalf("expected image/png content type, got %q", rec.Header().Get("Content-Type"))
	}
	body := rec.Body.Bytes()
	if len(body) < 8 || string(body[:8]) != "\x89PNG\r\n\x1a\n" {
		t.Fatalf("expected PNG body, got %d bytes", len(body))
	}
}

func TestStartTransferReturnsSession(t *testing.T) {
	gin.SetMode(gin.TestMode)

	router := gin.New()
	router.POST("/api/transfer-time/start", StartTransfer)

	req := httptest.NewRequest(
		http.MethodPost,
		"/api/transfer-time/start",
		bytes.NewBufferString(`{"fromStation":"同济大学","toStation":"浦东国际机场","estimatedMinutes":9}`),
	)
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusOK, rec.Code, rec.Body.String())
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(`"sessionId"`)) ||
		!bytes.Contains(rec.Body.Bytes(), []byte(`"remainingSeconds":540`)) {
		t.Fatalf("expected transfer timer session, got %s", rec.Body.String())
	}
}

func TestCleanDisplayTextReplacesMojibake(t *testing.T) {
	const fallback = "10号线运行正常"
	got := cleanDisplayText("10å·çº¿å£«é¦ç­è½¦", fallback)
	if got != fallback {
		t.Fatalf("expected fallback for mojibake, got %q", got)
	}

	normal := "10号线运行正常"
	got = cleanDisplayText(normal, fallback)
	if got != normal {
		t.Fatalf("expected normal Chinese text to be preserved, got %q", got)
	}
}

func TestAddCommonRouteRejectsMissingUserID(t *testing.T) {
	gin.SetMode(gin.TestMode)
	database.DB = nil

	router := gin.New()
	router.POST("/api/common-routes/add", AddCommonRoute)

	req := httptest.NewRequest(http.MethodPost, "/api/common-routes/add", bytes.NewBufferString(`{"start":"虹桥火车站","end":"人民广场"}`))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusBadRequest, rec.Code, rec.Body.String())
	}
}

func TestAddCommonRouteRejectsLongTimeOrDistance(t *testing.T) {
	gin.SetMode(gin.TestMode)
	database.DB = nil

	router := gin.New()
	router.POST("/api/common-routes/add", AddCommonRoute)

	req := httptest.NewRequest(
		http.MethodPost,
		"/api/common-routes/add",
		bytes.NewBufferString(`{"userId":"demo","start":"虹桥火车站","end":"人民广场","time":"123456789012345678901234567890123456789012345678901"}`),
	)
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusBadRequest, rec.Code, rec.Body.String())
	}
}

func TestDeleteCommonRouteRejectsInvalidID(t *testing.T) {
	gin.SetMode(gin.TestMode)
	database.DB = nil

	router := gin.New()
	router.DELETE("/api/common-routes/:id", DeleteCommonRoute)

	req := httptest.NewRequest(http.MethodDelete, "/api/common-routes/not-a-number", nil)
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusBadRequest, rec.Code, rec.Body.String())
	}
}

func TestValidateDataWithoutDatabaseValidatesInMemoryNetwork(t *testing.T) {
	gin.SetMode(gin.TestMode)
	database.DB = nil

	router := gin.New()
	router.GET("/api/data/validate", ValidateData)

	req := httptest.NewRequest(http.MethodGet, "/api/data/validate", nil)
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusOK, rec.Code, rec.Body.String())
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(`"network_lines":18`)) ||
		!bytes.Contains(rec.Body.Bytes(), []byte(`"ok":true`)) ||
		!bytes.Contains(rec.Body.Bytes(), []byte(`"warnings"`)) {
		t.Fatalf("expected in-memory network validation counts, got %s", rec.Body.String())
	}
}

func TestGetStationFallsBackToMetroNetworkStation(t *testing.T) {
	gin.SetMode(gin.TestMode)
	database.DB = nil

	router := gin.New()
	router.GET("/api/subway-service/station/:stationId", GetStation)

	req := httptest.NewRequest(http.MethodGet, "/api/subway-service/station/wujiaochang_10", nil)
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusOK, rec.Code, rec.Body.String())
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(`"name":"五角场"`)) ||
		!bytes.Contains(rec.Body.Bytes(), []byte(`"lines":["10"]`)) {
		t.Fatalf("expected metro network station fallback, got %s", rec.Body.String())
	}
}

func TestGetStationFacilitiesFallsBackToGenericNetworkFacility(t *testing.T) {
	gin.SetMode(gin.TestMode)
	database.DB = nil

	router := gin.New()
	router.GET("/api/subway-service/station/:stationId/facilities", GetStationFacilities)

	req := httptest.NewRequest(http.MethodGet, "/api/subway-service/station/wujiaochang_10/facilities", nil)
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusOK, rec.Code, rec.Body.String())
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(`"stationName":"五角场"`)) ||
		!bytes.Contains(rec.Body.Bytes(), []byte(`全网演示设施信息`)) {
		t.Fatalf("expected generic network facility fallback, got %s", rec.Body.String())
	}
}

func TestGetTrainInfoWithoutDatabaseReturnsDemoGuideData(t *testing.T) {
	gin.SetMode(gin.TestMode)
	database.DB = nil

	router := gin.New()
	router.GET("/api/high-speed-rail/train/:trainNumber", GetTrainInfo)

	req := httptest.NewRequest(http.MethodGet, "/api/high-speed-rail/train/G7501", nil)
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusOK, rec.Code, rec.Body.String())
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(`"platform"`)) ||
		!bytes.Contains(rec.Body.Bytes(), []byte(`"carriages"`)) ||
		bytes.Contains(rec.Body.Bytes(), []byte(`待实现`)) {
		t.Fatalf("expected rich demo train data, got %s", rec.Body.String())
	}
}

func TestGetStaticResourcesWithoutDatabaseReturnsDemoResources(t *testing.T) {
	gin.SetMode(gin.TestMode)
	database.DB = nil

	router := gin.New()
	router.GET("/api/data/static-resources", GetStaticResources)

	req := httptest.NewRequest(http.MethodGet, "/api/data/static-resources", nil)
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusOK, rec.Code, rec.Body.String())
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(`"name":"tongji-university"`)) ||
		!bytes.Contains(rec.Body.Bytes(), []byte(`"type":"diagram"`)) {
		t.Fatalf("expected demo static resources, got %s", rec.Body.String())
	}
}

func TestDataModuleEndpointsCoverSRSInterfaces(t *testing.T) {
	gin.SetMode(gin.TestMode)
	database.DB = nil

	router := gin.New()
	router.GET("/api/data/default-config", GetDefaultConfig)
	router.GET("/api/data/stations", ListStations)
	router.GET("/api/data/lines/:lineId/stations", ListStationsByLine)
	router.GET("/api/data/transfer-rules", SearchTransferRules)
	router.GET("/api/data/route-plan/:ruleId", GetRoutePlanByRule)

	requests := []struct {
		path     string
		contains []byte
	}{
		{"/api/data/default-config", []byte(`"defaultStation":"同济大学"`)},
		{"/api/data/stations?keyword=浦东", []byte(`浦东国际机场`)},
		{"/api/data/lines/10/stations", []byte(`同济大学`)},
		{"/api/data/transfer-rules?keyword=五角场&originStationId=tongji_university&lineId=10", []byte(`ruleId`)},
	}
	for _, item := range requests {
		req := httptest.NewRequest(http.MethodGet, item.path, nil)
		rec := httptest.NewRecorder()
		router.ServeHTTP(rec, req)
		if rec.Code != http.StatusOK {
			t.Fatalf("%s expected 200, got %d with body %s", item.path, rec.Code, rec.Body.String())
		}
		if !bytes.Contains(rec.Body.Bytes(), item.contains) {
			t.Fatalf("%s expected body to contain %s, got %s", item.path, item.contains, rec.Body.String())
		}
	}

	ruleID := "network%7Ctongji_university%7C10%7Cwujiaochang_10"
	req := httptest.NewRequest(http.MethodGet, "/api/data/route-plan/"+ruleID, nil)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("expected route plan by rule to succeed, got %d with body %s", rec.Code, rec.Body.String())
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(`"segments"`)) {
		t.Fatalf("expected route plan segments, got %s", rec.Body.String())
	}
}

func TestGetCommonRoutesWithoutDatabaseReturnsDemoRoutes(t *testing.T) {
	gin.SetMode(gin.TestMode)
	database.DB = nil

	router := gin.New()
	router.GET("/api/common-routes/user/:userId", GetCommonRoutes)

	req := httptest.NewRequest(http.MethodGet, "/api/common-routes/user/default", nil)
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusOK, rec.Code, rec.Body.String())
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(`同济大学`)) ||
		!bytes.Contains(rec.Body.Bytes(), []byte(`local-demo`)) {
		t.Fatalf("expected demo common routes, got %s", rec.Body.String())
	}
}

func TestSaveUserAbilityRejectsInvalidLevel(t *testing.T) {
	gin.SetMode(gin.TestMode)
	database.DB = nil

	router := gin.New()
	router.PUT("/api/users/:userId/abilities/:abilityType", SaveUserAbility)

	req := httptest.NewRequest(http.MethodPut, "/api/users/demo/abilities/mobility", bytes.NewBufferString(`{"level":9}`))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusBadRequest, rec.Code, rec.Body.String())
	}
}

func TestSaveUserLuggageRejectsLongWeight(t *testing.T) {
	gin.SetMode(gin.TestMode)
	database.DB = nil

	router := gin.New()
	router.PUT("/api/users/:userId/luggage/:luggageType", SaveUserLuggage)

	req := httptest.NewRequest(
		http.MethodPut,
		"/api/users/demo/luggage/suitcase",
		bytes.NewBufferString(`{"weight":"123456789012345678901234567890123456789012345678901","size":"large"}`),
	)
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusBadRequest, rec.Code, rec.Body.String())
	}
}

func TestUserPrivacyEndpointsWorkInDemoMode(t *testing.T) {
	gin.SetMode(gin.TestMode)
	database.DB = nil

	router := gin.New()
	router.DELETE("/api/users/:userId", DeleteUserData)
	router.POST("/api/users/:userId/anonymize", AnonymizeUserData)

	deleteReq := httptest.NewRequest(http.MethodDelete, "/api/users/default", nil)
	deleteRec := httptest.NewRecorder()
	router.ServeHTTP(deleteRec, deleteReq)
	if deleteRec.Code != http.StatusOK {
		t.Fatalf("expected delete status %d, got %d with body %s", http.StatusOK, deleteRec.Code, deleteRec.Body.String())
	}
	if !bytes.Contains(deleteRec.Body.Bytes(), []byte(`"deleted":true`)) {
		t.Fatalf("expected delete confirmation, got %s", deleteRec.Body.String())
	}

	anonymizeReq := httptest.NewRequest(http.MethodPost, "/api/users/default/anonymize", nil)
	anonymizeRec := httptest.NewRecorder()
	router.ServeHTTP(anonymizeRec, anonymizeReq)
	if anonymizeRec.Code != http.StatusOK {
		t.Fatalf("expected anonymize status %d, got %d with body %s", http.StatusOK, anonymizeRec.Code, anonymizeRec.Body.String())
	}
	if !bytes.Contains(anonymizeRec.Body.Bytes(), []byte(`"anonymousUserId"`)) {
		t.Fatalf("expected anonymized id, got %s", anonymizeRec.Body.String())
	}
}
