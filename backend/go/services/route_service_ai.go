package services

import (
	"encoding/json"
	"fmt"
)

func scoreRoutesWithAI(routes []PlannedRoute, preferences map[string]interface{}) []PlannedRoute {
	travelPrefs := getMap(preferences, "travelPreferences")
	mobilityPrefs := getMap(preferences, "mobilitySettings")
	luggagePrefs := getMap(preferences, "luggageSettings")

	var scored []RouteScore

	for _, route := range routes {
		if !isRouteEligible(route, mobilityPrefs, luggagePrefs) {
			continue
		}

		score, reason := calculateAIScore(route, travelPrefs, mobilityPrefs, luggagePrefs)
		scored = append(scored, RouteScore{
			Route:  route,
			Score:  score,
			Reason: reason,
		})
	}

	sortRoutesByScore(scored)

	result := make([]PlannedRoute, 0, len(scored))
	for _, s := range scored {
		route := s.Route
		analysis := generateAIAnalysis(route, s.Reason, preferences)
		route.Description = "AI 推荐：" + analysis
		result = append(result, route)
	}

	if len(result) > 3 {
		result = result[:3]
	}

	return result
}

func generateAIAnalysis(route PlannedRoute, baseReason string, preferences map[string]interface{}) string {
	routeJSON, err := json.Marshal(map[string]interface{}{
		"title":       route.Title,
		"time":        route.Time,
		"transfers":   route.Transfers,
		"base_reason": baseReason,
		"segments":    route.Segments,
	})
	if err != nil {
		return baseReason
	}

	analysis, err := GenerateRouteAnalysisWithPrefs(string(routeJSON), preferences)
	if err != nil {
		// 记录错误日志，但不中断流程
		fmt.Printf("Warning: Failed to generate AI analysis: %v\n", err)
		// 返回基础原因作为降级方案
		return baseReason
	}

	return analysis
}
