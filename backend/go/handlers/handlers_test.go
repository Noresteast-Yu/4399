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
