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
	if path.Steps[0].PhotoURL != "http://10.0.2.2:9000/station-media/stations/tongji_university/16_to_7_in_01.jpg" {
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
