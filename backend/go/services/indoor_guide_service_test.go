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

func TestStageProgressUsesCompletedShareOfWalkingStage(t *testing.T) {
	if got := stageProgress(0, 4); got != 0 {
		t.Fatalf("expected untouched stage progress 0, got %v", got)
	}
	if got := stageProgress(2, 2); got != 0.5 {
		t.Fatalf("expected half-complete stage progress 0.5, got %v", got)
	}
	if got := stageProgress(4, 0); got != 0.95 {
		t.Fatalf("expected completed stage to respect display clamp 0.95, got %v", got)
	}
}

func TestProgressStatusMarksDefaultArrivalAsFallback(t *testing.T) {
	step := IndoorGuideStep{
		Stage:     "entry",
		LineName:  "10号线",
		LineColor: "#B07AB2",
		Minutes:   2,
	}
	arrival := defaultIndoorArrival(step)

	status := progressStatusForIndoorStep(
		step,
		[]IndoorGuideStep{step},
		0,
		arrival,
	)

	if !status.IsFallback {
		t.Fatal("expected default arrival data to be marked as fallback")
	}
}

func TestCatchPlanSkipsEveryTrainThatCannotBeReachedSafely(t *testing.T) {
	steps := []IndoorGuideStep{
		{Stage: "entry", Minutes: 4},
	}
	arrival := &MetroArrivalResult{
		Interval:             "6",
		CurrentArriveMinutes: 1,
		NextArriveMinutes:    3,
	}

	plan := catchPlanForIndoorStages(
		steps,
		0,
		map[string]bool{"entry": true},
		arrival,
		1,
	)

	if plan.TrainMinutes != 9 {
		t.Fatalf("expected earliest reachable train in 9 minutes, got %d", plan.TrainMinutes)
	}
	if plan.MissedTrainCount != 2 {
		t.Fatalf("expected current and next train to be skipped, got %d", plan.MissedTrainCount)
	}
	if plan.SafeBufferMinutes != 5 {
		t.Fatalf("expected 5-minute walking buffer, got %d", plan.SafeBufferMinutes)
	}
}
