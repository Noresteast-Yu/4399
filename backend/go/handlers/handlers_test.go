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
