package services

import "testing"

func TestPlatformAccessUpperEndsConnectDirectlyToExitGateInside(t *testing.T) {
	for _, fromNodeID := range []string{"16", "18"} {
		path, err := BuildIndoorNavigationPath(
			"tongji_university",
			fromNodeID,
			"7_in",
			"",
			"",
		)
		if err != nil {
			t.Fatalf("expected path from %s to 7_in: %v", fromNodeID, err)
		}
		if len(path.NodePath) != 2 {
			t.Fatalf(
				"expected direct path from %s to 7_in, got %d nodes",
				fromNodeID,
				len(path.NodePath),
			)
		}
		if path.TotalSeconds != 10 {
			t.Fatalf(
				"expected direct path from %s to take 10 seconds, got %d",
				fromNodeID,
				path.TotalSeconds,
			)
		}

		reversePath, err := BuildIndoorNavigationPath(
			"tongji_university",
			"7_in",
			fromNodeID,
			"",
			"",
		)
		if err != nil {
			t.Fatalf("expected reverse path from 7_in to %s: %v", fromNodeID, err)
		}
		if len(reversePath.NodePath) != 2 || reversePath.TotalSeconds != 10 {
			t.Fatalf(
				"expected direct reverse path from 7_in to %s in 10 seconds",
				fromNodeID,
			)
		}
	}
}

func TestIndoorNavigationUsesDirectionSpecificPhoto(t *testing.T) {
	path, err := BuildIndoorNavigationPath(
		"tongji_university",
		"16",
		"7_in",
		"",
		"",
	)
	if err != nil {
		t.Fatalf("expected path from 16 to 7_in: %v", err)
	}
	if len(path.Steps) != 1 {
		t.Fatalf("expected one navigation step, got %d", len(path.Steps))
	}
	if path.Steps[0].PhotoKey != "16_to_7_in_01" {
		t.Fatalf("unexpected directional photo key: %q", path.Steps[0].PhotoKey)
	}
	if path.Steps[0].PhotoURL != "/static/stations/tongji_university/16_to_7_in_01.jpg" {
		t.Fatalf("unexpected directional photo URL: %q", path.Steps[0].PhotoURL)
	}

	reversePath, err := BuildIndoorNavigationPath(
		"tongji_university",
		"7_in",
		"16",
		"",
		"",
	)
	if err != nil {
		t.Fatalf("expected reverse path from 7_in to 16: %v", err)
	}
	if len(reversePath.Steps) != 1 {
		t.Fatalf("expected one reverse navigation step, got %d", len(reversePath.Steps))
	}
	if reversePath.Steps[0].PhotoURL != "" {
		t.Fatalf(
			"reverse path must not reuse the forward photo, got %q",
			reversePath.Steps[0].PhotoURL,
		)
	}
}

func TestNavigateToFacilityToilet(t *testing.T) {
	path, err := BuildIndoorNavigationPath(
		"tongji_university",
		"20",
		"",
		"facility",
		"toilet_1",
	)
	if err != nil {
		t.Fatalf("expected path to toilet_1: %v", err)
	}
	if path.TargetType != "facility" {
		t.Fatalf("expected targetType=facility, got %q", path.TargetType)
	}
	if path.TargetID != "toilet_1" {
		t.Fatalf("expected targetID=toilet_1, got %q", path.TargetID)
	}
	if len(path.NodePath) < 2 {
		t.Fatalf("expected at least 2 nodes in path, got %d", len(path.NodePath))
	}
	if path.ToNode.ID != "21" {
		t.Fatalf("expected toilet at node 21, got %s", path.ToNode.ID)
	}
	if path.TotalSeconds <= 0 {
		t.Fatalf("expected positive totalSeconds, got %d", path.TotalSeconds)
	}
	if len(path.Steps) == 0 {
		t.Fatal("expected at least one navigation step")
	}
}

func TestNavigateToServiceCenter(t *testing.T) {
	path, err := BuildIndoorNavigationPath(
		"tongji_university",
		"20",
		"",
		"facility",
		"service_center_1",
	)
	if err != nil {
		t.Fatalf("expected path to service_center_1: %v", err)
	}
	if path.TargetType != "facility" {
		t.Fatalf("expected targetType=facility, got %q", path.TargetType)
	}
	if path.TargetID != "service_center_1" {
		t.Fatalf("expected targetID=service_center_1, got %q", path.TargetID)
	}
	if len(path.NodePath) < 2 {
		t.Fatalf("expected at least 2 nodes in path, got %d", len(path.NodePath))
	}
	if len(path.Steps) == 0 {
		t.Fatal("expected at least one navigation step")
	}
}

func TestNavigateToAccessibleElevator(t *testing.T) {
	path, err := BuildIndoorNavigationPath(
		"tongji_university",
		"20",
		"",
		"facility",
		"accessible_elevator_1",
	)
	if err != nil {
		t.Fatalf("expected path to accessible_elevator_1: %v", err)
	}
	if path.TargetType != "facility" {
		t.Fatalf("expected targetType=facility, got %q", path.TargetType)
	}
	if path.TargetID != "accessible_elevator_1" {
		t.Fatalf("expected targetID=accessible_elevator_1, got %q", path.TargetID)
	}
	if path.ToNode.ID != "20" {
		t.Fatalf("expected elevator at node 20, got %s", path.ToNode.ID)
	}
	// From 20 to 20 should be direct (same node)
	if len(path.NodePath) != 1 {
		t.Fatalf("expected 1 node (direct reach) from 20 to elevator at 20, got %d nodes", len(path.NodePath))
	}
	if len(path.Steps) != 0 {
		t.Fatalf("expected 0 steps (same node), got %d", len(path.Steps))
	}
}

func TestNavigateToExit5(t *testing.T) {
	path, err := BuildIndoorNavigationPath(
		"tongji_university",
		"20",
		"",
		"exit",
		"5",
	)
	if err != nil {
		t.Fatalf("expected path to exit 5: %v", err)
	}
	if path.TargetType != "exit" {
		t.Fatalf("expected targetType=exit, got %q", path.TargetType)
	}
	if path.ToNode.ID != "1" {
		t.Fatalf("expected exit 5 at node 1, got %s", path.ToNode.ID)
	}
	if len(path.NodePath) < 2 {
		t.Fatalf("expected at least 2 nodes in path, got %d", len(path.NodePath))
	}
	if len(path.Steps) == 0 {
		t.Fatal("expected at least one navigation step")
	}
	if path.Target == nil {
		t.Fatal("expected target metadata non-nil for exit navigation")
	}
	exitNo, _ := path.Target["exitNo"].(string)
	if exitNo != "5" {
		t.Fatalf("expected target exitNo=5, got %q", exitNo)
	}
}

func TestNavigateFromEntranceNode(t *testing.T) {
	path, err := BuildIndoorNavigationPath(
		"tongji_university",
		"1",
		"",
		"facility",
		"toilet_1",
	)
	if err != nil {
		t.Fatalf("expected path from node 1 to toilet_1: %v", err)
	}
	if path.ToNode.ID != "21" {
		t.Fatalf("expected toilet at node 21, got %s", path.ToNode.ID)
	}
	if path.FromNode.ID != "1" {
		t.Fatalf("expected from node 1, got %s", path.FromNode.ID)
	}
	if len(path.NodePath) < 2 {
		t.Fatalf("expected at least 2 nodes from entrance to toilet, got %d", len(path.NodePath))
	}
	if len(path.Steps) == 0 {
		t.Fatal("expected at least one navigation step from entrance to toilet")
	}
}

func TestInvalidFacilityReturnsError(t *testing.T) {
	_, err := BuildIndoorNavigationPath(
		"tongji_university",
		"20",
		"",
		"facility",
		"nonexistent_facility",
	)
	if err == nil {
		t.Fatal("expected error for nonexistent facility, got nil")
	}
}

func TestInvalidStationReturnsError(t *testing.T) {
	_, err := BuildIndoorNavigationPath(
		"nonexistent_station",
		"20",
		"",
		"facility",
		"toilet_1",
	)
	if err == nil {
		t.Fatal("expected error for nonexistent station, got nil")
	}
}
