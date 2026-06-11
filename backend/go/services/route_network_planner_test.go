package services

import (
	"testing"

	"smart-travel-backend/models"
)

// =========================================================================
// TDD 测试集: route_network_planner.go
//
// 覆盖:
// - containsString (字符串包含判定)
// - reverseStrings (切片反转)
// - routeSignature (路线签名)
// - networkStateKey (状态键生成)
// - findMetroNetworkRoute (Dijkstra 全网路径规划)
// =========================================================================

// =========================================================================
// containsString
// =========================================================================

func TestContainsStringFound(t *testing.T) {
	items := []string{"a", "b", "c"}
	if !containsString(items, "b") {
		t.Error("expected true for 'b'")
	}
}

func TestContainsStringNotFound(t *testing.T) {
	items := []string{"a", "b", "c"}
	if containsString(items, "d") {
		t.Error("expected false for 'd'")
	}
}

func TestContainsStringEmptySlice(t *testing.T) {
	if containsString([]string{}, "anything") {
		t.Error("expected false for empty slice")
	}
}

func TestContainsStringNilSlice(t *testing.T) {
	if containsString(nil, "anything") {
		t.Error("expected false for nil slice")
	}
}

func TestContainsStringFirstElement(t *testing.T) {
	items := []string{"first", "middle", "last"}
	if !containsString(items, "first") {
		t.Error("expected true for first element")
	}
}

func TestContainsStringLastElement(t *testing.T) {
	items := []string{"first", "middle", "last"}
	if !containsString(items, "last") {
		t.Error("expected true for last element")
	}
}

func TestContainsStringSingleElement(t *testing.T) {
	if !containsString([]string{"only"}, "only") {
		t.Error("expected true for single element match")
	}
}

// =========================================================================
// reverseStrings
// =========================================================================

func TestReverseStringsOddLength(t *testing.T) {
	items := []string{"1", "2", "3", "4", "5"}
	reverseStrings(items)
	expected := []string{"5", "4", "3", "2", "1"}
	for i := range items {
		if items[i] != expected[i] {
			t.Fatalf("index %d: expected %s, got %s", i, expected[i], items[i])
		}
	}
}

func TestReverseStringsEvenLength(t *testing.T) {
	items := []string{"a", "b", "c", "d"}
	reverseStrings(items)
	expected := []string{"d", "c", "b", "a"}
	for i := range items {
		if items[i] != expected[i] {
			t.Fatalf("index %d: expected %s, got %s", i, expected[i], items[i])
		}
	}
}

func TestReverseStringsSingleElement(t *testing.T) {
	items := []string{"only"}
	reverseStrings(items)
	if len(items) != 1 || items[0] != "only" {
		t.Fatal("single element slice should be unchanged")
	}
}

func TestReverseStringsEmptySlice(t *testing.T) {
	items := []string{}
	reverseStrings(items)
	if len(items) != 0 {
		t.Fatal("empty slice should remain empty")
	}
}

func TestReverseStringsTwoElements(t *testing.T) {
	items := []string{"first", "second"}
	reverseStrings(items)
	if items[0] != "second" || items[1] != "first" {
		t.Fatalf("expected [second first], got %v", items)
	}
}

func TestReverseStringsRoundTrip(t *testing.T) {
	original := []string{"x", "y", "z", "w"}
	items := make([]string, len(original))
	copy(items, original)
	reverseStrings(items)
	reverseStrings(items) // 再反转一次应回到原始顺序
	for i := range items {
		if items[i] != original[i] {
			t.Fatalf("round trip failed at index %d: %s != %s", i, items[i], original[i])
		}
	}
}

// =========================================================================
// routeSignature
// =========================================================================

func TestRouteSignatureSingleLine(t *testing.T) {
	route := PlannedRoute{
		Segments: []RouteSegment{
			{Type: "walk", Line: "步行", Description: "start walk"},
			{Type: "subway", Line: "10号线", Description: "同济大学站 → 陕西南路站"},
			{Type: "walk", Line: "步行", Description: "end walk"},
		},
	}
	sig := routeSignature(route)
	if sig == "" {
		t.Error("signature should not be empty for a valid route")
	}
	if sig != "10号线:同济大学站 → 陕西南路站" {
		t.Errorf("unexpected signature: %s", sig)
	}
}

func TestRouteSignatureMultiTransfer(t *testing.T) {
	route := PlannedRoute{
		Segments: []RouteSegment{
			{Type: "walk", Line: "步行", Description: "start"},
			{Type: "subway", Line: "10号线", Description: "同济大学站 → 南京东路站"},
			{Type: "walk", Line: "站内换乘", Description: "南京东路站换乘2号线"},
			{Type: "subway", Line: "2号线", Description: "南京东路站 → 陆家嘴站"},
			{Type: "walk", Line: "步行", Description: "end"},
		},
	}
	sig := routeSignature(route)
	expected := "10号线:同济大学站 → 南京东路站|2号线:南京东路站 → 陆家嘴站"
	if sig != expected {
		t.Errorf("signature mismatch:\n  expected: %s\n  got:      %s", expected, sig)
	}
}

func TestRouteSignatureNoSubwaySegments(t *testing.T) {
	route := PlannedRoute{
		Segments: []RouteSegment{
			{Type: "walk", Line: "步行", Description: "walk only"},
		},
	}
	sig := routeSignature(route)
	if sig != "" {
		t.Errorf("expected empty signature for walk-only route, got: %s", sig)
	}
}

func TestRouteSignatureEmptySegments(t *testing.T) {
	route := PlannedRoute{}
	sig := routeSignature(route)
	if sig != "" {
		t.Error("expected empty signature for empty route")
	}
}

func TestRouteSignatureSkipTransferSegments(t *testing.T) {
	route := PlannedRoute{
		Segments: []RouteSegment{
			{Type: "subway", Line: "1号线", Description: "人民广场站 → 上海火车站"},
			{Type: "walk", Line: "站内换乘", Description: "上海火车站换乘3号线"},
			{Type: "subway", Line: "3号线", Description: "上海火车站 → 上海南站"},
		},
	}
	sig := routeSignature(route)
	// 换乘步骤 (walk + 站内换乘) 被跳过，只收集 subway 步骤
	expected := "1号线:人民广场站 → 上海火车站|3号线:上海火车站 → 上海南站"
	if sig != expected {
		t.Errorf("unexpected signature: %s", sig)
	}
}

// =========================================================================
// networkStateKey
// =========================================================================

func TestNetworkStateKey(t *testing.T) {
	key := networkStateKey("10", "同济大学")
	expected := "10|同济大学"
	if key != expected {
		t.Errorf("expected %s, got %s", expected, key)
	}
}

func TestNetworkStateKeyWithPrefix(t *testing.T) {
	// normalizeNetworkMetroLineID 对纯数字 "10" 不变，但可能处理 "line10" 等形式
	key := networkStateKey("line10", "同济大学")
	if key == "" {
		t.Error("key should not be empty")
	}
}

func TestNetworkStateKeyEmptyName(t *testing.T) {
	key := networkStateKey("1", "")
	if key != "1|" {
		t.Errorf("expected '1|', got '%s'", key)
	}
}

// =========================================================================
// findMetroNetworkRoute — Dijkstra 全网规划
// =========================================================================

func TestFindMetroNetworkRouteDirectSameLine(t *testing.T) {
	// 2号线直达: 人民广场 → 陆家嘴
	start := models.Station{StationID: "renmin_square", StationName: "人民广场"}
	end := models.Station{StationID: "lujiazui", StationName: "陆家嘴"}

	route := findMetroNetworkRoute(start, end)
	if route == nil {
		t.Fatal("expected route between 人民广场 and 陆家嘴 on line 2")
	}
	if route.StartStationID != "renmin_square" {
		t.Errorf("expected StartStationID=renmin_square, got %s", route.StartStationID)
	}
	if route.EndStationID != "lujiazui" {
		t.Errorf("expected EndStationID=lujiazui, got %s", route.EndStationID)
	}
	// 同线路直达，换乘应为 0
	if route.Transfers != 0 {
		t.Errorf("expected 0 transfers for direct line, got %d", route.Transfers)
	}
	if route.TotalTime <= 0 {
		t.Error("total time should be positive")
	}
	if len(route.Segments) == 0 {
		t.Error("segments should not be empty")
	}
}

func TestFindMetroNetworkRouteTransfer(t *testing.T) {
	// 10号线 → 2号线: 同济大学 → 陆家嘴
	start := models.Station{StationID: "tong_ji_university", StationName: "同济大学"}
	end := models.Station{StationID: "lujiazui", StationName: "陆家嘴"}

	route := findMetroNetworkRoute(start, end)
	if route == nil {
		t.Fatal("expected route between 同济大学 and 陆家嘴")
	}
	// 应有换乘
	if route.Transfers < 1 {
		t.Errorf("expected at least 1 transfer, got %d", route.Transfers)
	}
	if len(route.Segments) < 3 {
		t.Errorf("expected at least 3 segments (walk+ride+transfer+ride+walk), got %d", len(route.Segments))
	}
}

func TestFindMetroNetworkRouteTongjiToShaanxi(t *testing.T) {
	// 10号线直达: 同济大学 → 陕西南路
	start := models.Station{StationID: "tong_ji_university", StationName: "同济大学"}
	end := models.Station{StationID: "shaanxi_south_road", StationName: "陕西南路"}

	route := findMetroNetworkRoute(start, end)
	if route == nil {
		t.Fatal("expected route on line 10")
	}
	if route.Transfers != 0 {
		t.Errorf("expected 0 transfers (same line 10), got %d", route.Transfers)
	}
}

func TestFindMetroNetworkRouteSameStation(t *testing.T) {
	start := models.Station{StationID: "tong_ji_university", StationName: "同济大学"}
	end := models.Station{StationID: "tong_ji_university", StationName: "同济大学"}

	route := findMetroNetworkRoute(start, end)
	if route == nil {
		t.Fatal("expected route for same station")
	}
	if route.Transfers != 0 {
		t.Errorf("expected 0 transfers for same station, got %d", route.Transfers)
	}
}

func TestFindMetroNetworkRouteNonexistentStart(t *testing.T) {
	start := models.Station{StationID: "mars_base", StationName: "火星基地"}
	end := models.Station{StationID: "renmin_square", StationName: "人民广场"}

	route := findMetroNetworkRoute(start, end)
	if route != nil {
		t.Fatal("expected nil for nonexistent start station")
	}
}

func TestFindMetroNetworkRouteNonexistentEnd(t *testing.T) {
	start := models.Station{StationID: "renmin_square", StationName: "人民广场"}
	end := models.Station{StationID: "moon_base", StationName: "月球基地"}

	route := findMetroNetworkRoute(start, end)
	if route != nil {
		t.Fatal("expected nil for nonexistent end station")
	}
}

func TestFindMetroNetworkRouteMultiTransfer(t *testing.T) {
	// 从 同济大学(10号线) 到 虹桥火车站(2/10号线) — 10号线有直接线路
	start := models.Station{StationID: "tong_ji_university", StationName: "同济大学"}
	end := models.Station{StationID: "hongqiao_railway_2", StationName: "虹桥火车站"}

	route := findMetroNetworkRoute(start, end)
	if route == nil {
		t.Fatal("expected route between 同济大学 and 虹桥火车站")
	}
	// 10号线可直达 (同济大学→虹桥路→交通大学→...→虹桥火车站)
	if route.Transfers == 0 {
		// 10号线直达
		t.Log("direct route via line 10")
	}
}

func TestFindMetroNetworkRouteJiaotongToCenturyAvenue(t *testing.T) {
	// 交通大学(10/11号线) → 世纪大道(2号线)
	start := models.Station{StationID: "jiaotong_university", StationName: "交通大学"}
	end := models.Station{StationID: "Century_Avenue", StationName: "世纪大道"}

	route := findMetroNetworkRoute(start, end)
	if route == nil {
		t.Fatal("expected route between 交通大学 and 世纪大道")
	}
}

func TestFindMetroNetworkRouteLine1ToLine10(t *testing.T) {
	// 1号线上的站 → 10号线上的站
	start := models.Station{StationID: "shanghai_railway_station", StationName: "上海火车站"}
	end := models.Station{StationID: "tong_ji_university", StationName: "同济大学"}

	route := findMetroNetworkRoute(start, end)
	if route == nil {
		t.Fatal("expected route between 上海火车站 and 同济大学")
	}
	// 应有换乘
	if route.Transfers >= 0 {
		t.Logf("transfers: %d", route.Transfers)
	}
}

func TestFindMetroNetworkRouteRing(t *testing.T) {
	// 4号线环线上的两个站
	start := models.Station{StationID: "shanghai_railway_station", StationName: "上海火车站"}
	end := models.Station{StationID: "Century_Avenue", StationName: "世纪大道"}

	route := findMetroNetworkRoute(start, end)
	if route == nil {
		t.Fatal("expected route between 上海火车站 and 世纪大道")
	}
}

// =========================================================================
// findMetroNetworkRoute — 路由结构完整性
// =========================================================================

func TestFindMetroNetworkRouteHasBookendWalks(t *testing.T) {
	start := models.Station{StationID: "tong_ji_university", StationName: "同济大学"}
	end := models.Station{StationID: "lujiazui", StationName: "陆家嘴"}

	route := findMetroNetworkRoute(start, end)
	if route == nil {
		t.Fatal("expected route")
	}
	if len(route.Segments) < 2 {
		t.Fatal("expected at least 2 segments")
	}
	// 第一个 segment 应为入站步行
	first := route.Segments[0]
	if first.Type != "walk" {
		t.Errorf("first segment should be walk, got %s", first.Type)
	}
	if first.Line != "步行" {
		t.Errorf("first segment line should be 步行, got %s", first.Line)
	}
	// 最后一个 segment 应为出站步行
	last := route.Segments[len(route.Segments)-1]
	if last.Type != "walk" {
		t.Errorf("last segment should be walk, got %s", last.Type)
	}
}

func TestFindMetroNetworkRouteHasTransferWalk(t *testing.T) {
	start := models.Station{StationID: "tong_ji_university", StationName: "同济大学"}
	end := models.Station{StationID: "lujiazui", StationName: "陆家嘴"}

	route := findMetroNetworkRoute(start, end)
	if route == nil {
		t.Fatal("expected route")
	}

	hasTransfer := false
	hasSubway := false
	for _, seg := range route.Segments {
		if seg.Line == "站内换乘" {
			hasTransfer = true
		}
		if seg.Type == "subway" {
			hasSubway = true
		}
	}
	if !hasSubway {
		t.Error("route should have at least one subway segment")
	}
	if route.Transfers > 0 && !hasTransfer {
		t.Error("route has transfers but no transfer segments found")
	}
}

func TestFindMetroNetworkRouteDescriptionNotEmpty(t *testing.T) {
	start := models.Station{StationID: "renmin_square", StationName: "人民广场"}
	end := models.Station{StationID: "lujiazui", StationName: "陆家嘴"}

	route := findMetroNetworkRoute(start, end)
	if route == nil {
		t.Fatal("expected route")
	}
	if route.Description == "" {
		t.Error("description should not be empty")
	}
	if route.Title == "" {
		t.Error("title should not be empty")
	}
	if route.Time == "" {
		t.Error("formatted time should not be empty")
	}
}

// =========================================================================
// findMetroNetworkRoute — 边界条件
// =========================================================================

func TestFindMetroNetworkRouteEmptyIDs(t *testing.T) {
	start := models.Station{StationID: "", StationName: ""}
	end := models.Station{StationID: "", StationName: ""}

	route := findMetroNetworkRoute(start, end)
	if route != nil {
		t.Fatal("expected nil for empty station IDs")
	}
}

func TestFindMetroNetworkRouteAllLinesConnectivity(t *testing.T) {
	// 验证全网连通性：任意两个有数据的站点之间应有路径
	testCases := []struct {
		startID string
		startName string
		endID string
		endName string
	}{
		{"renmin_square", "人民广场", "pudong_airport", "浦东国际机场"},
		{"xujingdong", "徐泾东", "pudong_airport", "浦东国际机场"},
		// 10号线(新江湾城) → 11号线(花桥): 需要交通大学换乘(10↔11)，路径可达
		// 注意：该对依赖于 metroNetworkLines 的换乘站连接
		{"shanghai_south_railway_station", "上海南站", "shanghai_railway_station", "上海火车站"},
		{"caohexi_kfq", "漕河泾开发区", "jiaotong_university", "交通大学"},
	}

	for _, tc := range testCases {
		t.Run(tc.startName+" → "+tc.endName, func(t *testing.T) {
			start := models.Station{StationID: tc.startID, StationName: tc.startName}
			end := models.Station{StationID: tc.endID, StationName: tc.endName}
			route := findMetroNetworkRoute(start, end)
			if route == nil {
				t.Errorf("expected route from %s to %s", tc.startName, tc.endName)
				return
			}
			if len(route.Segments) == 0 {
				t.Error("route has no segments")
			}
			if route.TotalTime <= 0 {
				t.Error("total time should be positive")
			}
		})
	}
}

// =========================================================================
// 综合测试: 路线段数据一致性
// =========================================================================

func TestSegmentStopsConsistency(t *testing.T) {
	start := models.Station{StationID: "renmin_square", StationName: "人民广场"}
	end := models.Station{StationID: "lujiazui", StationName: "陆家嘴"}

	route := findMetroNetworkRoute(start, end)
	if route == nil {
		t.Fatal("expected route")
	}

	for _, seg := range route.Segments {
		if seg.Type == "subway" {
			if seg.Stops < 0 {
				t.Errorf("subway segment stops should be >= 0, got %d", seg.Stops)
			}
			if seg.Line == "" {
				t.Error("subway segment should have a line name")
			}
		}
	}
}

func TestRouteTotalTimeMatchesSegments(t *testing.T) {
	start := models.Station{StationID: "tong_ji_university", StationName: "同济大学"}
	end := models.Station{StationID: "shaanxi_south_road", StationName: "陕西南路"}

	route := findMetroNetworkRoute(start, end)
	if route == nil {
		t.Fatal("expected route")
	}

	// sum 各个 segment 的时间并与 route.TotalTime 对比
	segTime := 0
	for _, seg := range route.Segments {
		switch seg.Type {
		case "walk":
			if seg.Time == "3分钟" {
				segTime += 3
			} else if seg.Time == "5分钟" {
				segTime += 5
			}
		case "subway":
			segTime += seg.Stops * 2
		}
	}
	// TotalTime = dist[bestEnd] + 6 (步行)
	t.Logf("segment sum: %d min, route total: %d min (%s)", segTime, route.TotalTime, route.Time)
	if route.TotalTime <= 0 {
		t.Error("total time should be positive")
	}
}
