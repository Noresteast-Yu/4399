package services

import (
	"testing"

	"smart-travel-backend/database"
)

func TestPlanRouteCanTransferFromLine10ToLine1(t *testing.T) {
	database.DB = nil

	result, err := PlanRoute("同济大学", "莘庄")
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if !result.Success {
		t.Fatalf("expected successful route planning, got error %q", result.Error)
	}

	foundLine1 := false
	for _, route := range result.Routes {
		for _, segment := range route.Segments {
			if segment.Line == "1号线" {
				foundLine1 = true
			}
		}
	}
	if !foundLine1 {
		t.Fatalf("expected at least one route segment on line 1, got %#v", result.Routes)
	}
}

func TestPlanRouteCanUseMultiTransferMetroNetwork(t *testing.T) {
	database.DB = nil

	result, err := PlanRoute("同济大学", "闵行开发区")
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if !result.Success {
		t.Fatalf("expected successful route planning, got error %q", result.Error)
	}

	foundLine5 := false
	for _, route := range result.Routes {
		for _, segment := range route.Segments {
			if segment.Line == "5号线" {
				foundLine5 = true
			}
		}
	}
	if !foundLine5 {
		t.Fatalf("expected at least one route segment on line 5, got %#v", result.Routes)
	}
}
