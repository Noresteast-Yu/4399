package services

import (
	"testing"
)

// =========================================================================
// TDD 测试集: facility_service.go
//
// 覆盖:
// - getFacilityByID (站内查找 + 不存在站点)
// - IsStationAccessible (无障碍判定)
// - IsWheelchairFriendly (轮椅友好判定)
// - FindStationByID (站点模型查找)
// - GetStationLineNames (线路归属)
// - StationFacilityInfo 字段完整性
// - GetAllStationFacilities (全量设施列表)
// =========================================================================

func TestGetFacilityByIDExists(t *testing.T) {
	info := getFacilityByID("tong_ji_university")
	if info == nil {
		t.Fatal("expected facility info for tong_ji_university")
	}
	if info.StationID != "tong_ji_university" {
		t.Fatalf("expected StationID=tong_ji_university, got %s", info.StationID)
	}
	if info.StationName != "同济大学" {
		t.Fatalf("expected StationName=同济大学, got %s", info.StationName)
	}
	if len(info.LineIDs) == 0 {
		t.Fatal("expected at least one LineID")
	}
	if !containsStr(info.LineIDs, "10") {
		t.Fatalf("expected LineIDs to contain '10', got %v", info.LineIDs)
	}
}

func TestGetFacilityByIDRenminSquare(t *testing.T) {
	info := getFacilityByID("renmin_square")
	if info == nil {
		t.Fatal("expected facility info for renmin_square")
	}
	if info.StationName != "人民广场" {
		t.Fatalf("expected StationName=人民广场, got %s", info.StationName)
	}
	if !info.HasElevator {
		t.Error("人民广场 should have elevator")
	}
	if info.ElevatorCount < 2 {
		t.Errorf("人民广场 elevator count should be >= 2, got %d", info.ElevatorCount)
	}
	if !info.HasAccessibleRestroom {
		t.Error("人民广场 should have accessible restroom")
	}
}

func TestGetFacilityByIDNotExists(t *testing.T) {
	info := getFacilityByID("nonexistent_station_xyz")
	if info != nil {
		t.Fatal("expected nil for nonexistent station")
	}
}

func TestGetFacilityByIDEmptyString(t *testing.T) {
	info := getFacilityByID("")
	if info != nil {
		t.Fatal("expected nil for empty station ID")
	}
}

// =========================================================================
// IsStationAccessible
// =========================================================================

func TestIsStationAccessibleAccessibleStation(t *testing.T) {
	// 同济大学: HasElevator=true, HasWheelchairRamp=true
	if !IsStationAccessible("tong_ji_university") {
		t.Error("同济大学 should be accessible (has elevator + wheelchair ramp)")
	}
}

func TestIsStationAccessibleRenminSquare(t *testing.T) {
	// 人民广场: HasElevator=true, HasWheelchairRamp=true
	if !IsStationAccessible("renmin_square") {
		t.Error("人民广场 should be accessible")
	}
}

func TestIsStationAccessibleNonexistentStation(t *testing.T) {
	if IsStationAccessible("fake_station_123") {
		t.Error("nonexistent station should not be accessible")
	}
}

func TestIsStationAccessibleAllKnownStations(t *testing.T) {
	// 验证所有已知站点中，HasElevator=true 且 HasWheelchairRamp=true 的站点为 accessible
	stationsToCheck := []string{
		"tong_ji_university",
		"renmin_square",
		"jiaotong_university",
		"Century_Avenue",
		"hongqiao_railway_2",
	}
	for _, id := range stationsToCheck {
		info := getFacilityByID(id)
		if info == nil {
			t.Errorf("missing facility data for known station: %s", id)
			continue
		}
		expected := info.HasElevator && info.HasWheelchairRamp
		got := IsStationAccessible(id)
		if got != expected {
			t.Errorf("%s: IsStationAccessible=%v, expected=%v (elevator=%v, ramp=%v)",
				id, got, expected, info.HasElevator, info.HasWheelchairRamp)
		}
	}
}

// =========================================================================
// IsWheelchairFriendly
// =========================================================================

func TestIsWheelchairFriendlyTongji(t *testing.T) {
	// 同济大学: HasElevator + HasWheelchairRamp + HasAccessibleRestroom + HasWideGate 均为 true
	if !IsWheelchairFriendly("tong_ji_university") {
		t.Error("同济大学 should be wheelchair friendly")
	}
}

func TestIsWheelchairFriendlyRenminSquare(t *testing.T) {
	if !IsWheelchairFriendly("renmin_square") {
		t.Error("人民广场 should be wheelchair friendly")
	}
}

func TestIsWheelchairFriendlyStationMissingRestroom(t *testing.T) {
	// 远东大道: HasAccessibleRestroom=false, 不应 wheelchair friendly
	if IsWheelchairFriendly("yuanshen") {
		t.Error("远东大道 should NOT be wheelchair friendly (no accessible restroom)")
	}
}

func TestIsWheelchairFriendlyStationMissingAED(t *testing.T) {
	// 金科路: HasElevator + HasWheelchairRamp + HasWideGate + HasBlindPath 均 true
	// 但 HasAccessibleRestroom=false
	if IsWheelchairFriendly("jinyang_road") {
		t.Error("金科路 should NOT be wheelchair friendly (no accessible restroom)")
	}
}

func TestIsWheelchairFriendlyNonexistent(t *testing.T) {
	if IsWheelchairFriendly("nonexistent_999") {
		t.Error("nonexistent station should not be wheelchair friendly")
	}
}

func TestWheelchairFriendlyImpliesAccessible(t *testing.T) {
	// wheelchair friendly → accessible (轮椅友好是 accessible 的超集)
	testIDs := []string{
		"tong_ji_university",
		"renmin_square",
		"jiaotong_university",
	}
	for _, id := range testIDs {
		wc := IsWheelchairFriendly(id)
		ac := IsStationAccessible(id)
		if wc && !ac {
			t.Errorf("%s: wheelchair friendly=true but accessible=false (impossible)", id)
		}
	}
}

// =========================================================================
// StationFacilityInfo 字段完整性
// =========================================================================

func TestStationFacilityInfoRequiredFields(t *testing.T) {
	info := getFacilityByID("tong_ji_university")
	if info == nil {
		t.Fatal("missing tong_ji_university")
	}

	requiredNonEmpty := map[string]string{
		"StationID":   info.StationID,
		"StationName": info.StationName,
	}
	for field, val := range requiredNonEmpty {
		if val == "" {
			t.Errorf("field %s should not be empty", field)
		}
	}

	if info.ElevatorCount < 0 {
		t.Error("ElevatorCount should be >= 0")
	}
}

func TestShanghaiRailwayStationFacilities(t *testing.T) {
	// 上海火车站是多线换乘枢纽，设施应完整
	info := getFacilityByID("shanghai_railway_station")
	if info == nil {
		t.Fatal("missing shanghai_railway_station")
	}
	if !info.HasElevator {
		t.Error("上海火车站 should have elevator")
	}
	if !info.HasEscalator {
		t.Error("上海火车站 should have escalator")
	}
	if !info.HasAccessibleRestroom {
		t.Error("上海火车站 should have accessible restroom")
	}
	if !info.HasRestroomInPaid {
		t.Error("上海火车站 should have restroom in paid area")
	}
	if !info.HasMotherBabyRoom {
		t.Error("上海火车站 should have mother-baby room")
	}
	if !info.HasAED {
		t.Error("上海火车站 should have AED")
	}
	if !info.HasServiceCenter {
		t.Error("上海火车站 should have service center")
	}
}

func TestPudongAirportFacilities(t *testing.T) {
	// 浦东国际机场是航空枢纽，设施应完整
	info := getFacilityByID("pudong_airport")
	if info == nil {
		t.Fatal("missing pudong_airport")
	}
	if !info.HasElevator {
		t.Error("浦东国际机场 should have elevator")
	}
	if !info.HasThirdBathroom {
		t.Error("浦东国际机场 should have third bathroom (family/gender-neutral)")
	}
	if !info.HasAED {
		t.Error("浦东国际机场 should have AED")
	}
}

// =========================================================================
// FindStationByID
// =========================================================================

func TestFindStationByIDExists(t *testing.T) {
	s, err := FindStationByID("tong_ji_university")
	if err != nil {
		t.Fatalf("expected to find tong_ji_university: %v", err)
	}
	if s.StationID != "tong_ji_university" {
		t.Fatalf("expected StationID=tong_ji_university, got %s", s.StationID)
	}
	if s.StationName != "同济大学" {
		t.Fatalf("expected StationName=同济大学, got %s", s.StationName)
	}
	if s.City != "上海" {
		t.Fatalf("expected City=上海, got %s", s.City)
	}
	if s.StationType != "地铁站" {
		t.Fatalf("expected StationType=地铁站, got %s", s.StationType)
	}
	if s.ID <= 0 {
		t.Fatalf("expected ID > 0, got %d", s.ID)
	}
}

func TestFindStationByIDNotExists(t *testing.T) {
	_, err := FindStationByID("mars_station")
	if err == nil {
		t.Fatal("expected error for nonexistent station")
	}
	if err.Error() == "" {
		t.Error("error message should not be empty")
	}
}

func TestFindStationByIDEmpty(t *testing.T) {
	_, err := FindStationByID("")
	if err == nil {
		t.Fatal("expected error for empty station ID")
	}
}

func TestFindStationByIDAll(t *testing.T) {
	// 验证一批关键站点的查找
	stations := []string{
		"pudong_airport",
		"renmin_square",
		"lujiazui",
		"Century_Avenue",
		"jiaotong_university",
		"shanghai_library",
		"xu_jia_hui",
		"hongqiao_railway_2",
		"hongqiao_railway_10",
		"shanghai_railway_station",
		"shanghai_south_railway_station",
		"caohexi_kfq",
	}
	for _, id := range stations {
		s, err := FindStationByID(id)
		if err != nil {
			t.Errorf("expected to find %s: %v", id, err)
			continue
		}
		if s.StationID != id {
			t.Errorf("StationID mismatch: expected %s, got %s", id, s.StationID)
		}
		if s.StationName == "" {
			t.Errorf("%s has empty StationName", id)
		}
	}
}

// =========================================================================
// GetStationLineNames
// =========================================================================

func TestGetStationLineNamesSingleLine(t *testing.T) {
	lines := GetStationLineNames("tong_ji_university")
	if len(lines) == 0 {
		t.Fatal("expected at least one line for 同济大学")
	}
	if !containsStr(lines, "10") {
		t.Errorf("expected line 10 in 同济大学, got %v", lines)
	}
}

func TestGetStationLineNamesMultiLine(t *testing.T) {
	lines := GetStationLineNames("jiaotong_university")
	if len(lines) < 2 {
		t.Fatalf("交通大学 should have at least 2 lines, got %d: %v", len(lines), lines)
	}
	if !containsStr(lines, "10") {
		t.Error("交通大学 should be on line 10")
	}
	if !containsStr(lines, "11") {
		t.Error("交通大学 should be on line 11")
	}
}

func TestGetStationLineNamesShanghaiRailway(t *testing.T) {
	// 上海火车站: 1, 3, 4号线
	lines := GetStationLineNames("shanghai_railway_station")
	if len(lines) < 3 {
		t.Fatalf("上海火车站 should have at least 3 lines, got %d: %v", len(lines), lines)
	}
}

func TestGetStationLineNamesNonexistent(t *testing.T) {
	lines := GetStationLineNames("fake_station")
	if lines != nil {
		t.Error("expected nil for nonexistent station")
	}
}

// =========================================================================
// GetAllStationFacilities
// =========================================================================

func TestGetAllStationFacilitiesNonEmpty(t *testing.T) {
	facilities := GetAllStationFacilities()
	if len(facilities) == 0 {
		t.Fatal("expected non-empty facility list")
	}
	// 应有至少 80 个站点
	if len(facilities) < 80 {
		t.Errorf("expected >= 80 facilities, got %d", len(facilities))
	}
}

func TestGetAllStationFacilitiesNoDuplicates(t *testing.T) {
	facilities := GetAllStationFacilities()
	seen := make(map[string]bool)
	for _, f := range facilities {
		if seen[f.StationID] {
			t.Errorf("duplicate stationID: %s", f.StationID)
		}
		seen[f.StationID] = true
	}
}

func TestGetAllStationFacilitiesEachHasRequiredFields(t *testing.T) {
	facilities := GetAllStationFacilities()
	for _, f := range facilities {
		if f.StationID == "" {
			t.Error("found facility with empty StationID")
		}
		if f.StationName == "" {
			t.Errorf("station %s has empty StationName", f.StationID)
		}
	}
}

// =========================================================================
// Save/Restore 一致性
// =========================================================================

func TestFacilityDataConsistencyAcrossLookups(t *testing.T) {
	// 通过 getFacilityByID 和 GetAllStationFacilities 查找相同站点，数据应一致
	id := "tong_ji_university"
	direct := getFacilityByID(id)
	if direct == nil {
		t.Fatal("direct lookup failed")
	}

	var fromAll *StationFacilityInfo
	for _, f := range GetAllStationFacilities() {
		if f.StationID == id {
			fromAll = f
			break
		}
	}
	if fromAll == nil {
		t.Fatal("not found in GetAllStationFacilities")
	}

	if direct.StationName != fromAll.StationName {
		t.Errorf("name mismatch: %s vs %s", direct.StationName, fromAll.StationName)
	}
	if direct.HasElevator != fromAll.HasElevator {
		t.Error("HasElevator mismatch")
	}
	if direct.ElevatorCount != fromAll.ElevatorCount {
		t.Error("ElevatorCount mismatch")
	}
	if direct.HasAccessibleRestroom != fromAll.HasAccessibleRestroom {
		t.Error("HasAccessibleRestroom mismatch")
	}
	if direct.HasWheelchairRamp != fromAll.HasWheelchairRamp {
		t.Error("HasWheelchairRamp mismatch")
	}
	if direct.HasWideGate != fromAll.HasWideGate {
		t.Error("HasWideGate mismatch")
	}
}

// =========================================================================
// GetStationFacilityInfo (public wrapper)
// =========================================================================

func TestGetStationFacilityInfoExists(t *testing.T) {
	info, err := GetStationFacilityInfo("tong_ji_university")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if info == nil {
		t.Fatal("expected non-nil facility info")
	}
	if info.StationID != "tong_ji_university" {
		t.Fatalf("expected tong_ji_university, got %s", info.StationID)
	}
}

func TestGetStationFacilityInfoNotExists(t *testing.T) {
	info, err := GetStationFacilityInfo("fake_station")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if info != nil {
		t.Fatal("expected nil for nonexistent station")
	}
}

// =========================================================================
// 辅助函数
// =========================================================================

func containsStr(slice []string, s string) bool {
	for _, item := range slice {
		if item == s {
			return true
		}
	}
	return false
}
