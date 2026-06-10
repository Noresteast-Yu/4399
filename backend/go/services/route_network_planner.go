package services

import (
	"fmt"
	"math"
	"strings"

	"smart-travel-backend/models"
)

type networkState struct {
	LineID  string
	Station metroNetworkStation
}

type networkStateStep struct {
	Prev     string
	Cost     int
	Transfer bool
}

func findMetroNetworkRoute(start, end models.Station) *PlannedRoute {
	startName := metroNetworkStationName(start.StationID, start.StationName)
	endName := metroNetworkStationName(end.StationID, end.StationName)
	if startName == "" || endName == "" {
		return nil
	}

	states := map[string]networkState{}
	stationToKeys := map[string][]string{}
	for lineID, stations := range metroNetworkLines {
		for _, station := range stations {
			key := networkStateKey(lineID, station.Name)
			states[key] = networkState{LineID: lineID, Station: station}
			stationToKeys[station.Name] = append(stationToKeys[station.Name], key)
		}
	}

	startKeys := stationToKeys[startName]
	endKeys := stationToKeys[endName]
	if len(startKeys) == 0 || len(endKeys) == 0 {
		return nil
	}

	dist := map[string]int{}
	prev := map[string]networkStateStep{}
	visited := map[string]bool{}
	for key := range states {
		dist[key] = math.MaxInt / 4
	}
	for _, key := range startKeys {
		dist[key] = 0
	}

	endSet := map[string]bool{}
	for _, key := range endKeys {
		endSet[key] = true
	}

	bestEnd := ""
	for len(visited) < len(states) {
		current := ""
		currentDist := math.MaxInt / 4
		for key := range states {
			if !visited[key] && dist[key] < currentDist {
				current = key
				currentDist = dist[key]
			}
		}
		if current == "" {
			break
		}
		if endSet[current] {
			bestEnd = current
			break
		}

		visited[current] = true
		for next, step := range networkNeighbors(current, states, stationToKeys) {
			nextDist := currentDist + step.Cost
			if nextDist < dist[next] {
				dist[next] = nextDist
				prev[next] = networkStateStep{Prev: current, Cost: step.Cost, Transfer: step.Transfer}
			}
		}
	}

	if bestEnd == "" {
		return nil
	}

	keys := []string{bestEnd}
	for keys[len(keys)-1] != "" && !containsString(startKeys, keys[len(keys)-1]) {
		step, ok := prev[keys[len(keys)-1]]
		if !ok {
			return nil
		}
		keys = append(keys, step.Prev)
	}
	reverseStrings(keys)

	segments := buildMetroNetworkSegments(keys, states, start, end)
	if len(segments) == 0 {
		return nil
	}

	transfers := 0
	for _, segment := range segments {
		if segment.Type == "walk" && segment.Line == "站内换乘" {
			transfers++
		}
	}

	totalTime := dist[bestEnd] + 6
	return &PlannedRoute{
		Title:          "全网换乘路线",
		TotalTime:      totalTime,
		Time:           formatTime(totalTime),
		Transfers:      transfers,
		StartStationID: start.StationID,
		EndStationID:   end.StationID,
		Description: fmt.Sprintf(
			"AI 分析：已按上海地铁全线路网规划，%s到%s需要%d次换乘，全程约%s。",
			start.StationName,
			end.StationName,
			transfers,
			formatTime(totalTime),
		),
		Segments: segments,
	}
}

func networkStateKey(lineID string, stationName string) string {
	return normalizeNetworkMetroLineID(lineID) + "|" + stationName
}

func networkNeighbors(key string, states map[string]networkState, stationToKeys map[string][]string) map[string]networkStateStep {
	current := states[key]
	result := map[string]networkStateStep{}

	stations := metroNetworkLines[current.LineID]
	for i, station := range stations {
		if station.Name != current.Station.Name {
			continue
		}
		if i > 0 {
			result[networkStateKey(current.LineID, stations[i-1].Name)] = networkStateStep{Cost: 2}
		}
		if i < len(stations)-1 {
			result[networkStateKey(current.LineID, stations[i+1].Name)] = networkStateStep{Cost: 2}
		}
		break
	}

	for _, transferKey := range stationToKeys[current.Station.Name] {
		if transferKey != key {
			result[transferKey] = networkStateStep{Cost: 5, Transfer: true}
		}
	}
	return result
}

func buildMetroNetworkSegments(keys []string, states map[string]networkState, start models.Station, end models.Station) []RouteSegment {
	if len(keys) == 0 {
		return nil
	}

	segments := []RouteSegment{
		{Type: "walk", Line: "步行", Description: "从" + start.StationName + "到" + start.StationName + "站", Time: "3分钟", Distance: "200m"},
	}

	rideStart := states[keys[0]]
	prevState := rideStart
	rideStops := 0

	flushRide := func(to networkState) {
		if rideStart.Station.Name == to.Station.Name {
			return
		}
		line, _ := metroNetworkLine(rideStart.LineID)
		color := ""
		if line.ColorHex != nil {
			color = *line.ColorHex
		}
		segments = append(segments, RouteSegment{
			Type:        "subway",
			Line:        line.LineName,
			Description: rideStart.Station.Name + "站 → " + to.Station.Name + "站",
			Time:        formatTime(rideStops * 2),
			Stops:       rideStops,
			Color:       color,
		})
	}

	for i := 1; i < len(keys); i++ {
		current := states[keys[i]]
		if current.LineID != prevState.LineID {
			flushRide(prevState)
			line, _ := metroNetworkLine(current.LineID)
			segments = append(segments, RouteSegment{
				Type:        "walk",
				Line:        "站内换乘",
				Description: prevState.Station.Name + "站换乘" + line.LineName,
				Time:        "5分钟",
				Distance:    "100m",
			})
			rideStart = current
			rideStops = 0
		} else if current.Station.Name != prevState.Station.Name {
			rideStops++
		}
		prevState = current
	}
	flushRide(prevState)

	segments = append(segments, RouteSegment{
		Type:        "walk",
		Line:        "步行",
		Description: "从" + end.StationName + "地铁站到达目的地",
		Time:        "3分钟",
		Distance:    "150m",
	})
	return segments
}

func containsString(items []string, target string) bool {
	for _, item := range items {
		if item == target {
			return true
		}
	}
	return false
}

func reverseStrings(items []string) {
	for i, j := 0, len(items)-1; i < j; i, j = i+1, j-1 {
		items[i], items[j] = items[j], items[i]
	}
}

func routeSignature(route PlannedRoute) string {
	parts := make([]string, 0, len(route.Segments))
	for _, segment := range route.Segments {
		if segment.Type == "subway" {
			parts = append(parts, segment.Line+":"+segment.Description)
		}
	}
	return strings.Join(parts, "|")
}
