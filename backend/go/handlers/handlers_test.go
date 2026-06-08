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

func TestValidateDataWithoutDatabaseReturnsServiceUnavailable(t *testing.T) {
	gin.SetMode(gin.TestMode)
	database.DB = nil

	router := gin.New()
	router.GET("/api/data/validate", ValidateData)

	req := httptest.NewRequest(http.MethodGet, "/api/data/validate", nil)
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("expected status %d, got %d with body %s", http.StatusServiceUnavailable, rec.Code, rec.Body.String())
	}
}

func TestGetStaticResourcesWithoutDatabaseReturnsEmptyList(t *testing.T) {
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
