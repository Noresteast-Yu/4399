package router

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"smart-travel-backend/config"
	"smart-travel-backend/database"
)

func TestHealthCheckReportsMockModeWithoutDatabase(t *testing.T) {
	config.AppConfig = &config.Config{
		CORSOrigins: []string{"*"},
	}
	database.DB = nil

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rec := httptest.NewRecorder()

	SetupRouter().ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d", http.StatusOK, rec.Code)
	}
	if body := rec.Body.String(); !containsAll(body, []string{`"status":"ok"`, `"mode":"mock"`, `"database":false`}) {
		t.Fatalf("unexpected health body: %s", body)
	}
}

func TestCORSAllowsConfiguredOrigin(t *testing.T) {
	config.AppConfig = &config.Config{
		CORSOrigins: []string{"http://localhost:5173"},
	}

	req := httptest.NewRequest(http.MethodOptions, "/health", nil)
	req.Header.Set("Origin", "http://localhost:5173")
	rec := httptest.NewRecorder()

	SetupRouter().ServeHTTP(rec, req)

	if rec.Code != http.StatusNoContent {
		t.Fatalf("expected status %d, got %d", http.StatusNoContent, rec.Code)
	}
	if got := rec.Header().Get("Access-Control-Allow-Origin"); got != "http://localhost:5173" {
		t.Fatalf("expected configured origin header, got %q", got)
	}
}

func TestCORSWildcardEchoesRequestOrigin(t *testing.T) {
	config.AppConfig = &config.Config{
		CORSOrigins: []string{"*"},
	}

	req := httptest.NewRequest(http.MethodOptions, "/health", nil)
	req.Header.Set("Origin", "http://localhost:3000")
	rec := httptest.NewRecorder()

	SetupRouter().ServeHTTP(rec, req)

	if got := rec.Header().Get("Access-Control-Allow-Origin"); got != "http://localhost:3000" {
		t.Fatalf("expected request origin header, got %q", got)
	}
}

func TestIndoorNavigationRoutesAreRegistered(t *testing.T) {
	config.AppConfig = &config.Config{
		CORSOrigins: []string{"*"},
	}

	expected := map[string]bool{
		"GET /api/indoor-guide":                    false,
		"GET /api/indoor-guide/progress":           false,
		"GET /api/indoor-navigation/topology":      false,
		"GET /api/indoor-navigation/path":          false,
		"POST /api/transfer-time/start":            false,
		"GET /api/transfer-time/update/:sessionId": false,
	}

	for _, route := range SetupRouter().Routes() {
		key := route.Method + " " + route.Path
		if _, ok := expected[key]; ok {
			expected[key] = true
		}
	}

	for route, registered := range expected {
		if !registered {
			t.Fatalf("expected route %s to be registered", route)
		}
	}
}

func containsAll(value string, needles []string) bool {
	for _, needle := range needles {
		if !strings.Contains(value, needle) {
			return false
		}
	}
	return true
}
