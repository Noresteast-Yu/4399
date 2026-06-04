package services

import "testing"

func TestBuildIndoorGuideWithOptionsSameStationUsesIndoorPath(t *testing.T) {
	options := IndoorGuideOptions{
		StartEntranceID:   "5",
		StartEntranceName: "5号口",
		EndExitID:         "1",
		EndExitName:       "1号口",
	}
	directPlan, ok := buildSameStationIndoorPlan("同济大学", "同济大学", options)
	if !ok {
		t.Fatal("expected same-station branch to build an indoor path")
	}

	plan := BuildIndoorGuideWithOptions("同济大学", "同济大学", options)

	if len(plan.Steps) == 0 {
		t.Fatal("expected same-station indoor path steps")
	}
	if len(directPlan.Steps) != len(plan.Steps) {
		t.Fatalf("expected public plan to use same-station branch, direct=%d public=%d", len(directPlan.Steps), len(plan.Steps))
	}
	for _, step := range plan.Steps {
		if step.Stage == "ride" || step.Stage == "platform" || step.Stage == "transfer" {
			t.Fatalf("same-station indoor path should not include metro stage %q", step.Stage)
		}
	}
	if plan.Summary.TransferText != "无需进闸乘车" {
		t.Fatalf("unexpected summary transfer text: %q", plan.Summary.TransferText)
	}
}

func TestBuildIndoorGuideWithOptionsSameStationSameExitDoesNotFallbackToRide(t *testing.T) {
	options := IndoorGuideOptions{
		StartEntranceID:   "1",
		StartEntranceName: "1号口",
		EndExitID:         "1",
		EndExitName:       "1号口",
	}

	plan := BuildIndoorGuideWithOptions("同济大学", "同济大学", options)

	if len(plan.Steps) != 1 {
		t.Fatalf("expected a single no-move step, got %d", len(plan.Steps))
	}
	step := plan.Steps[0]
	if step.Stage == "ride" || step.Stage == "platform" || step.Stage == "transfer" {
		t.Fatalf("same entrance and exit should not include metro stage %q", step.Stage)
	}
	if step.Minutes != 0 {
		t.Fatalf("expected no-move step to cost 0 minutes, got %d", step.Minutes)
	}
	if step.Title != "已在目标出入口" {
		t.Fatalf("unexpected no-move step title: %q", step.Title)
	}
}
