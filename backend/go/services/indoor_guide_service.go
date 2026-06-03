package services

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"sync"
)

type IndoorGuideStep struct {
	Stage          string            `json:"stage"`
	LineName       string            `json:"lineName"`
	LineColor      string            `json:"lineColor"`
	Title          string            `json:"title"`
	Detail         string            `json:"detail"`
	ImageTitle     string            `json:"imageTitle"`
	ImageSubtitle  string            `json:"imageSubtitle"`
	Minutes        int               `json:"minutes"`
	IconKey        string            `json:"iconKey"`
	TargetStation  string            `json:"targetStation,omitempty"`
	RemainingStops int               `json:"remainingStops,omitempty"`
	TotalStops     int               `json:"totalStops,omitempty"`
	DoorHint       string            `json:"doorHint,omitempty"`
	ArrivalQuery   map[string]string `json:"arrivalQuery,omitempty"`
}

type IndoorGuideProgressStatus struct {
	LeadText string  `json:"leadText"`
	Title    string  `json:"title"`
	Subtitle string  `json:"subtitle"`
	Progress float64 `json:"progress"`
	Color    string  `json:"color"`
	IconKey  string  `json:"iconKey"`
}

type IndoorGuideProgress struct {
	StepIndex    int                       `json:"stepIndex"`
	Stage        string                    `json:"stage"`
	ArrivalQuery map[string]string         `json:"arrivalQuery"`
	Arrival      *MetroArrivalResult       `json:"arrival,omitempty"`
	Status       IndoorGuideProgressStatus `json:"status"`
}

type IndoorGuideRouteSegment struct {
	LineName      string   `json:"lineName"`
	LineColor     string   `json:"lineColor"`
	From          string   `json:"from"`
	To            string   `json:"to"`
	Stops         []string `json:"stops"`
	Direction     int      `json:"direction"`
	DirectionName string   `json:"directionName"`
}

type IndoorGuideSummary struct {
	Title           string   `json:"title"`
	DurationMinutes int      `json:"durationMinutes"`
	TransferCount   int      `json:"transferCount"`
	TransferText    string   `json:"transferText"`
	DoorHint        string   `json:"doorHint"`
	Lines           []string `json:"lines"`
	NextAction      string   `json:"nextAction"`
}

type IndoorGuidePlan struct {
	From             string                    `json:"from"`
	To               string                    `json:"to"`
	Summary          IndoorGuideSummary        `json:"summary"`
	TransferStations []string                  `json:"transferStations"`
	TransferStation  string                    `json:"transferStation"`
	ArrivalQuery     map[string]string         `json:"arrivalQuery"`
	ArrivalQueries   []map[string]string       `json:"arrivalQueries"`
	Route            []IndoorGuideRouteSegment `json:"route"`
	Steps            []IndoorGuideStep         `json:"steps"`
}

type metroState struct {
	Station string
	Line    string
}

type metroEdge struct {
	To   metroState
	Cost int
}

type metroRoute struct {
	Segments         []IndoorGuideRouteSegment
	TransferStations []string
}

type indoorStepTemplate struct {
	Title         string
	Detail        string
	ImageTitle    string
	ImageSubtitle string
	Minutes       int
	IconKey       string
}

type indoorStationProfile struct {
	Entrance string
	Exit     string
	Entry    []indoorStepTemplate
	ExitStep []indoorStepTemplate
}

type indoorGuideDataConfig struct {
	MetroLineStations    map[string][]string             `json:"metroLineStations"`
	MetroLineColors      map[string]string               `json:"metroLineColors"`
	StationProfiles      map[string]indoorStationProfile `json:"stationProfiles"`
	TransferStepProfiles map[string][]indoorStepTemplate `json:"transferStepProfiles"`
	StationStopIDs       map[string]map[string]string    `json:"stationStopIDs"`
	LineIDs              map[string]string               `json:"lineIDs"`
	TransferMinutes      map[string]int                  `json:"transferMinutes"`
	DoorHints            map[string]string               `json:"doorHints"`
	RideMinutesPerStop   int                             `json:"rideMinutesPerStop"`
	CityCode             string                          `json:"cityCode"`
}

var metroLineStations = map[string][]string{
	"10号线": {
		"虹桥火车站", "虹桥2号航站楼", "龙溪路", "上海动物园", "伊犁路", "宋园路",
		"虹桥路", "交通大学", "上海图书馆", "陕西南路", "新天地", "老西门",
		"豫园", "南京东路", "天潼路", "四川北路", "海伦路", "邮电新村",
		"四平路", "同济大学", "国权路", "五角场", "江湾体育场",
	},
	"2号线": {
		"徐泾东", "虹桥火车站", "虹桥2号航站楼", "淞虹路", "北新泾",
		"威宁路", "娄山关路", "中山公园", "江苏路", "静安寺", "南京西路",
		"人民广场", "南京东路", "陆家嘴",
	},
	"17号线": {
		"虹桥火车站", "诸光路", "蟠龙路", "徐盈路", "徐泾北城", "嘉松中路",
	},
}

var metroLineColors = map[string]string{
	"10号线": "#B07AB2",
	"2号线":  "#73C92D",
	"17号线": "#B58A00",
	"出站":   "#008C4A",
}

var stationProfiles = map[string]indoorStationProfile{
	"default": {
		Entrance: "6号口",
		Exit:     "1号口",
		Entry: []indoorStepTemplate{
			{Title: "从{entrance}进入", Detail: "面向地铁入口向前走，优先选择人流较少的一侧进站。", ImageTitle: "{entrance} 实景确认", ImageSubtitle: "看见{line}标识后继续直行", Minutes: 1, IconKey: "login"},
			{Title: "下扶梯到站厅", Detail: "扶梯到底后保持直行，不要先跟随出站人流转弯。", ImageTitle: "站厅扶梯口", ImageSubtitle: "确认前方有{line}站台指示牌", Minutes: 1, IconKey: "escalator"},
			{Title: "刷码后右转", Detail: "过闸机后右转，跟随目标线路方向标识。", ImageTitle: "闸机后右转通道", ImageSubtitle: "右侧通道前往{line}站台", Minutes: 1, IconKey: "turnRight"},
		},
		ExitStep: []indoorStepTemplate{
			{Title: "从{exit}出站", Detail: "跟随出口编号走，出闸后靠右侧通道出站。", ImageTitle: "{exit} 出口实景", ImageSubtitle: "确认出口编号后再上行", Minutes: 3, IconKey: "output"},
		},
	},
	"五角场": {
		Entrance: "5号口",
		Exit:     "5号口",
	},
	"同济大学": {
		Entrance: "2号口",
		Exit:     "2号口",
	},
	"陕西南路": {
		Entrance: "6号口",
		Exit:     "2号口",
	},
	"静安寺": {
		Entrance: "3号口",
		Exit:     "3号口",
	},
	"虹桥火车站": {
		Entrance: "北2入口",
		Exit:     "B出口",
		Entry: []indoorStepTemplate{
			{Title: "从{entrance}进入", Detail: "跟随地铁/Metro标识进入地下通道，避开高铁出站人流正面汇入点。", ImageTitle: "{entrance} 实景确认", ImageSubtitle: "确认前方有地铁进站导向牌", Minutes: 1, IconKey: "login"},
			{Title: "沿右侧通道直行", Detail: "保持在右侧通道，看到10号线/2号线/17号线分流牌后继续向前。", ImageTitle: "虹桥火车站到达层通道", ImageSubtitle: "右侧通道更靠近地铁入口", Minutes: 2, IconKey: "straight"},
			{Title: "下扶梯到站厅", Detail: "下行后选择对应线路闸机口，先看清方向再刷码进站。", ImageTitle: "站厅扶梯口", ImageSubtitle: "确认目标线路颜色和方向牌", Minutes: 1, IconKey: "escalator"},
		},
	},
}

var transferStepProfiles = map[string][]indoorStepTemplate{
	"南京东路|10号线|2号线": {
		{Title: "下车后向车头方向走", Detail: "不要先上出站扶梯，沿站台向前走到换乘扶梯。", ImageTitle: "{station} {fromLine}站台", ImageSubtitle: "车头方向可见换乘扶梯", Minutes: 1, IconKey: "straight"},
		{Title: "上扶梯后左转", Detail: "扶梯到站厅后左转，进入2号线换乘通道。", ImageTitle: "换乘扶梯出口", ImageSubtitle: "左侧为2号线换乘通道", Minutes: 1, IconKey: "turnLeft"},
		{Title: "到2号线站台候车", Detail: "确认方向为“徐泾东/静安寺方向”，站到中部车门附近。", ImageTitle: "2号线候车区", ImageSubtitle: "确认绿色2号线方向牌", Minutes: 1, IconKey: "signpost"},
	},
	"虹桥火车站|*|*": {
		{Title: "跟随换乘大厅指示", Detail: "下车后进入换乘大厅，先看清{toLine}方向牌。", ImageTitle: "{station}换乘大厅", ImageSubtitle: "确认目标线路颜色后继续", Minutes: 2, IconKey: "straight"},
		{Title: "到{toLine}站台候车", Detail: "虹桥客流较大，优先站到车门侧后方，避免堵在扶梯口。", ImageTitle: "{toLine}候车区", ImageSubtitle: "确认开往目标方向的站台", Minutes: 1, IconKey: "signpost"},
	},
	"default": {
		{Title: "跟随{toLine}换乘标识", Detail: "下车后不要出站，沿站内换乘通道前往{toLine}。", ImageTitle: "{station}换乘通道", ImageSubtitle: "确认{toLine}方向牌", Minutes: 2, IconKey: "straight"},
		{Title: "到{toLine}站台候车", Detail: "到达站台后确认行车方向，再靠近推荐车门候车。", ImageTitle: "{toLine}候车区", ImageSubtitle: "确认方向牌后候车", Minutes: 1, IconKey: "signpost"},
	},
}

var stationStopIDs = map[string]map[string]string{
	"五角场": {
		"10号线": "wujiaochang_10",
	},
	"同济大学": {
		"10号线": "tongji_university_10",
	},
	"虹桥火车站": {
		"10号线": "hongqiao_railway_10",
		"2号线":  "hongqiao_railway_2",
		"17号线": "hongqiao_railway_17",
	},
	"虹桥2号航站楼": {
		"10号线": "hongqiao_t2_10",
		"2号线":  "hongqiao_t2_2",
	},
	"南京东路": {
		"10号线": "nanjing_east_road_10",
		"2号线":  "nanjing_east_road_2",
	},
	"静安寺": {
		"2号线": "jingan_temple_2",
	},
	"新天地": {
		"10号线": "xintiandi_10",
	},
}

var lineIDs = map[string]string{
	"10号线": "mock-line-10",
	"2号线":  "mock-line-2",
	"17号线": "mock-line-17",
}

var transferMinutes = map[string]int{
	"虹桥火车站": 6,
	"南京东路":  5,
	"虹桥路":   4,
	"交通大学":  4,
	"陕西南路":  4,
}

var doorHints = map[string]string{
	"10号线|南京东路":  "4车2门",
	"10号线|虹桥火车站": "2车3门",
	"2号线|*":      "中部车门",
	"虹桥火车站|*":    "2车3门",
}

var rideMinutesPerStop = 2
var indoorGuideCityCode = "mock-shanghai"
var indoorGuideDataOnce sync.Once

func ensureIndoorGuideDataLoaded() {
	indoorGuideDataOnce.Do(func() {
		for _, path := range indoorGuideDataPaths() {
			raw, err := os.ReadFile(path)
			if err != nil {
				continue
			}
			var config indoorGuideDataConfig
			if err := json.Unmarshal(raw, &config); err != nil {
				continue
			}
			applyIndoorGuideData(config)
			return
		}
	})
}

func indoorGuideDataPaths() []string {
	paths := []string{
		filepath.Join("data", "indoor_guide_data.json"),
		filepath.Join("backend", "go", "data", "indoor_guide_data.json"),
	}
	if wd, err := os.Getwd(); err == nil {
		paths = append(paths,
			filepath.Join(wd, "data", "indoor_guide_data.json"),
			filepath.Join(wd, "backend", "go", "data", "indoor_guide_data.json"),
		)
	}
	return paths
}

func applyIndoorGuideData(config indoorGuideDataConfig) {
	if len(config.MetroLineStations) > 0 {
		metroLineStations = config.MetroLineStations
	}
	if len(config.MetroLineColors) > 0 {
		metroLineColors = config.MetroLineColors
	}
	if len(config.StationProfiles) > 0 {
		stationProfiles = config.StationProfiles
	}
	if len(config.TransferStepProfiles) > 0 {
		transferStepProfiles = config.TransferStepProfiles
	}
	if len(config.StationStopIDs) > 0 {
		stationStopIDs = config.StationStopIDs
	}
	if len(config.LineIDs) > 0 {
		lineIDs = config.LineIDs
	}
	if len(config.TransferMinutes) > 0 {
		transferMinutes = config.TransferMinutes
	}
	if len(config.DoorHints) > 0 {
		doorHints = config.DoorHints
	}
	if config.RideMinutesPerStop > 0 {
		rideMinutesPerStop = config.RideMinutesPerStop
	}
	if config.CityCode != "" {
		indoorGuideCityCode = config.CityCode
	}
}

func BuildIndoorGuide(from string, to string) IndoorGuidePlan {
	ensureIndoorGuideDataLoaded()
	from = normalizeIndoorStation(from, "新天地")
	to = normalizeIndoorStation(to, "静安寺")

	route := planMetroRoute(from, to)
	if len(route.Segments) == 0 {
		route = fallbackMetroRoute(from, to)
	}

	steps := composeIndoorGuideSteps(route, from, to)
	transferStation := ""
	if len(route.TransferStations) > 0 {
		transferStation = route.TransferStations[0]
	}

	firstSegment := route.Segments[0]
	arrivalQueries := arrivalQueriesForRoute(route)
	return IndoorGuidePlan{
		From:             from,
		To:               to,
		Summary:          buildRouteSummary(route, steps, from, to),
		TransferStations: route.TransferStations,
		TransferStation:  transferStation,
		ArrivalQuery:     arrivalQueryForSegment(firstSegment, firstSegment.From),
		ArrivalQueries:   arrivalQueries,
		Route:            route.Segments,
		Steps:            steps,
	}
}

func BuildIndoorGuideProgress(from string, to string, stepIndex int) IndoorGuideProgress {
	plan := BuildIndoorGuide(from, to)
	if len(plan.Steps) == 0 {
		return IndoorGuideProgress{
			StepIndex: 0,
			Status: IndoorGuideProgressStatus{
				LeadText: "等待",
				Title:    "等待选择路线",
				Subtitle: "请先选择起点和终点",
				Progress: 0,
				Color:    "#B07AB2",
				IconKey:  "navigation",
			},
		}
	}

	if stepIndex < 0 {
		stepIndex = 0
	}
	if stepIndex >= len(plan.Steps) {
		stepIndex = len(plan.Steps) - 1
	}

	step := plan.Steps[stepIndex]
	arrival := queryArrivalForIndoorStep(step)

	return IndoorGuideProgress{
		StepIndex:    stepIndex,
		Stage:        step.Stage,
		ArrivalQuery: step.ArrivalQuery,
		Arrival:      arrival,
		Status:       progressStatusForIndoorStep(step, plan.Steps, stepIndex, arrival),
	}
}

func planMetroRoute(from string, to string) metroRoute {
	graph, stationLines := buildMetroGraph()
	startLines := stationLines[from]
	endLines := stationLines[to]
	if len(startLines) == 0 || len(endLines) == 0 {
		return metroRoute{}
	}

	const inf = int(^uint(0) >> 1)
	dist := map[metroState]int{}
	prev := map[metroState]metroState{}
	visited := map[metroState]bool{}

	for state := range graph {
		dist[state] = inf
	}
	for _, line := range startLines {
		dist[metroState{Station: from, Line: line}] = 0
	}

	var target metroState
	found := false
	for {
		current := metroState{}
		best := inf
		for state, cost := range dist {
			if !visited[state] && cost < best {
				current = state
				best = cost
			}
		}
		if best == inf {
			break
		}
		visited[current] = true
		if current.Station == to {
			target = current
			found = true
			break
		}
		for _, edge := range graph[current] {
			nextCost := best + edge.Cost
			if nextCost < dist[edge.To] {
				dist[edge.To] = nextCost
				prev[edge.To] = current
			}
		}
	}

	if !found {
		for _, line := range endLines {
			state := metroState{Station: to, Line: line}
			if dist[state] < dist[target] || !found {
				target = state
				found = true
			}
		}
	}
	if !found || dist[target] == inf {
		return metroRoute{}
	}

	states := []metroState{target}
	for states[len(states)-1].Station != from {
		p, ok := prev[states[len(states)-1]]
		if !ok {
			return metroRoute{}
		}
		states = append(states, p)
	}
	reverseStates(states)

	return statesToRoute(states)
}

func buildMetroGraph() (map[metroState][]metroEdge, map[string][]string) {
	graph := map[metroState][]metroEdge{}
	stationLines := map[string][]string{}

	for line, stations := range metroLineStations {
		for i, station := range stations {
			state := metroState{Station: station, Line: line}
			if _, ok := graph[state]; !ok {
				graph[state] = []metroEdge{}
			}
			stationLines[station] = appendUnique(stationLines[station], line)
			if i > 0 {
				prev := metroState{Station: stations[i-1], Line: line}
				graph[state] = append(graph[state], metroEdge{To: prev, Cost: rideMinutesBetween(stations[i-1], station)})
			}
			if i < len(stations)-1 {
				next := metroState{Station: stations[i+1], Line: line}
				graph[state] = append(graph[state], metroEdge{To: next, Cost: rideMinutesBetween(station, stations[i+1])})
			}
		}
	}

	for station, lines := range stationLines {
		for _, fromLine := range lines {
			for _, toLine := range lines {
				if fromLine == toLine {
					continue
				}
				fromState := metroState{Station: station, Line: fromLine}
				toState := metroState{Station: station, Line: toLine}
				graph[fromState] = append(graph[fromState], metroEdge{
					To:   toState,
					Cost: transferMinutesForStation(station, fromLine, toLine),
				})
			}
		}
	}

	return graph, stationLines
}

func statesToRoute(states []metroState) metroRoute {
	if len(states) == 0 {
		return metroRoute{}
	}

	segments := []IndoorGuideRouteSegment{}
	transfers := []string{}
	currentLine := states[0].Line
	currentStops := []string{states[0].Station}

	for i := 1; i < len(states); i++ {
		prev := states[i-1]
		current := states[i]
		if current.Line == currentLine {
			if current.Station != currentStops[len(currentStops)-1] {
				currentStops = append(currentStops, current.Station)
			}
			continue
		}

		segments = append(segments, routeSegment(currentLine, currentStops))
		if prev.Station == current.Station {
			transfers = appendUnique(transfers, current.Station)
			currentStops = []string{current.Station}
		} else {
			currentStops = []string{prev.Station, current.Station}
		}
		currentLine = current.Line
	}
	segments = append(segments, routeSegment(currentLine, currentStops))

	return metroRoute{
		Segments:         segments,
		TransferStations: transfers,
	}
}

func routeSegment(line string, stops []string) IndoorGuideRouteSegment {
	direction := directionForSegment(line, stops[0], stops[len(stops)-1])
	return IndoorGuideRouteSegment{
		LineName:      line,
		LineColor:     metroLineColors[line],
		From:          stops[0],
		To:            stops[len(stops)-1],
		Stops:         append([]string{}, stops...),
		Direction:     direction,
		DirectionName: directionNameForLine(line, direction),
	}
}

func composeIndoorGuideSteps(route metroRoute, from string, to string) []IndoorGuideStep {
	if len(route.Segments) == 0 {
		return nil
	}

	steps := []IndoorGuideStep{}
	first := route.Segments[0]
	steps = append(steps, entryStepsForStation(from, first.LineName)...)
	steps = append(steps, platformStepForSegment(first, first.To))
	steps = append(steps, rideStepForSegment(first, nextTransferTarget(route, 0)))

	for i := 1; i < len(route.Segments); i++ {
		prev := route.Segments[i-1]
		current := route.Segments[i]
		transferStation := current.From
		steps = append(steps, transferStepsForStation(transferStation, prev.LineName, current.LineName)...)
		steps = append(steps, rideStepForSegment(current, nextTransferTarget(route, i)))
	}

	steps = append(steps, exitStepsForStation(to)...)
	assignArrivalQueriesToSteps(steps, route)
	return steps
}

func entryStepsForStation(station string, line string) []IndoorGuideStep {
	profile := profileForStation(station)
	templates := profile.Entry
	if len(templates) == 0 {
		templates = stationProfiles["default"].Entry
	}
	lineColor := metroLineColors[line]
	context := map[string]string{
		"station":  station,
		"line":     line,
		"entrance": profile.Entrance,
		"exit":     profile.Exit,
	}
	return stepsFromTemplates("entry", line, lineColor, templates, context)
}

func platformStepForSegment(segment IndoorGuideRouteSegment, target string) IndoorGuideStep {
	doorHint := doorHintForSegment(segment, target)
	step := guideStep(
		"platform",
		segment.LineName,
		segment.LineColor,
		"站到"+doorHint+"候车",
		"这个位置下车后更靠近后续换乘或出站通道。",
		segment.LineName+"站台中部",
		"寻找"+doorHint+"地贴或屏蔽门编号",
		1,
		"door",
	)
	step.DoorHint = doorHint
	return step
}

func rideStepForSegment(segment IndoorGuideRouteSegment, target string) IndoorGuideStep {
	remainingStops := len(segment.Stops) - 1
	if remainingStops < 1 {
		remainingStops = 1
	}
	minutes := remainingStops * 2
	step := guideStep(
		"ride",
		segment.LineName,
		segment.LineColor,
		"乘"+segment.LineName+"到"+segment.To,
		"还有"+itoa(remainingStops)+"站下车，到站前提前靠近"+doorHintForSegment(segment, target)+"。",
		segment.LineName+"车厢内提示",
		"听到"+segment.To+"报站后准备下车",
		minutes,
		"train",
	)
	step.TargetStation = segment.To
	step.RemainingStops = remainingStops
	step.TotalStops = remainingStops
	step.DoorHint = doorHintForSegment(segment, target)
	return step
}

func transferStepsForStation(station string, fromLine string, toLine string) []IndoorGuideStep {
	lineColor := metroLineColors[toLine]
	key := station + "|" + fromLine + "|" + toLine
	templates := transferStepProfiles[key]
	if len(templates) == 0 {
		templates = transferStepProfiles[station+"|*|*"]
	}
	if len(templates) == 0 {
		templates = transferStepProfiles["default"]
	}
	context := map[string]string{
		"station":  station,
		"fromLine": fromLine,
		"toLine":   toLine,
	}
	steps := stepsFromTemplates("transfer", toLine, lineColor, templates, context)
	for i := range steps {
		if i == len(steps)-1 {
			steps[i].Stage = "transferWait"
		}
	}
	return steps
}

func exitStepsForStation(station string) []IndoorGuideStep {
	profile := profileForStation(station)
	templates := profile.ExitStep
	if len(templates) == 0 {
		templates = stationProfiles["default"].ExitStep
	}
	context := map[string]string{
		"station": station,
		"exit":    profile.Exit,
	}
	return stepsFromTemplates("exit", "出站", metroLineColors["出站"], templates, context)
}

func guideStep(stage string, lineName string, lineColor string, title string, detail string, imageTitle string, imageSubtitle string, minutes int, iconKey string) IndoorGuideStep {
	return IndoorGuideStep{
		Stage:         stage,
		LineName:      lineName,
		LineColor:     lineColor,
		Title:         title,
		Detail:        detail,
		ImageTitle:    imageTitle,
		ImageSubtitle: imageSubtitle,
		Minutes:       minutes,
		IconKey:       iconKey,
	}
}

func stepsFromTemplates(stage string, lineName string, lineColor string, templates []indoorStepTemplate, context map[string]string) []IndoorGuideStep {
	steps := make([]IndoorGuideStep, 0, len(templates))
	for _, template := range templates {
		steps = append(steps, guideStep(
			stage,
			lineName,
			lineColor,
			renderIndoorText(template.Title, context),
			renderIndoorText(template.Detail, context),
			renderIndoorText(template.ImageTitle, context),
			renderIndoorText(template.ImageSubtitle, context),
			template.Minutes,
			template.IconKey,
		))
	}
	return steps
}

func renderIndoorText(text string, context map[string]string) string {
	out := text
	for key, value := range context {
		out = strings.ReplaceAll(out, "{"+key+"}", value)
	}
	return out
}

func profileForStation(station string) indoorStationProfile {
	base := stationProfiles["default"]
	profile, ok := stationProfiles[station]
	if !ok {
		return base
	}
	if profile.Entrance == "" {
		profile.Entrance = base.Entrance
	}
	if profile.Exit == "" {
		profile.Exit = base.Exit
	}
	if len(profile.Entry) == 0 {
		profile.Entry = base.Entry
	}
	if len(profile.ExitStep) == 0 {
		profile.ExitStep = base.ExitStep
	}
	return profile
}

func assignArrivalQueriesToSteps(steps []IndoorGuideStep, route metroRoute) {
	if len(route.Segments) == 0 {
		return
	}
	segmentIndex := 0
	inTransferBlock := false
	for i := range steps {
		isTransferStage := steps[i].Stage == "transfer" || steps[i].Stage == "transferWait"
		if isTransferStage && !inTransferBlock {
			if segmentIndex+1 < len(route.Segments) {
				segmentIndex++
			}
		}
		inTransferBlock = isTransferStage
		segment := route.Segments[segmentIndex]
		steps[i].ArrivalQuery = arrivalQueryForSegment(segment, segment.From)
	}
}

func queryArrivalForIndoorStep(step IndoorGuideStep) *MetroArrivalResult {
	query := step.ArrivalQuery
	if len(query) == 0 {
		return defaultIndoorArrival(step)
	}
	result, err := QueryMetroArrival(MetroArrivalQuery{
		LineID:    query["lineId"],
		LineName:  query["lineName"],
		StopID:    query["stopId"],
		StopName:  query["stopName"],
		Direction: query["direction"],
		CityCode:  query["cityCode"],
	})
	if err != nil || result == nil {
		return defaultIndoorArrival(step)
	}
	return result
}

func defaultIndoorArrival(step IndoorGuideStep) *MetroArrivalResult {
	return &MetroArrivalResult{
		StationName:          step.TargetStation,
		LineName:             step.LineName,
		Direction:            "0",
		Interval:             "7",
		CurrentArriveMinutes: 5,
		NextArriveMinutes:    12,
		StopCount:            step.RemainingStops,
		Source:               "indoor-guide-default",
	}
}

func progressStatusForIndoorStep(step IndoorGuideStep, steps []IndoorGuideStep, index int, arrival *MetroArrivalResult) IndoorGuideProgressStatus {
	switch step.Stage {
	case "ride":
		total := step.TotalStops
		if total <= 0 {
			total = 1
		}
		done := total - step.RemainingStops
		if done < 0 {
			done = 0
		}
		progress := float64(done) / float64(total)
		return IndoorGuideProgressStatus{
			LeadText: itoa(step.RemainingStops) + "站",
			Title:    "乘车中",
			Subtitle: "到" + step.TargetStation + "下车，提前靠近" + step.DoorHint,
			Progress: clampProgress(progress),
			Color:    step.LineColor,
			IconKey:  "train",
		}
	case "transfer", "transferWait":
		catchPlan := catchPlanForIndoorStages(steps, index, map[string]bool{"transfer": true, "transferWait": true}, arrival, 1)
		title := "预计可赶上" + step.LineName + "当前班"
		if catchPlan.UsesNextTrain {
			title = step.LineName + "赶不上，改按下一班"
		}
		return IndoorGuideProgressStatus{
			LeadText: itoa(catchPlan.TrainMinutes) + "分钟",
			Title:    title,
			Subtitle: "换乘还要约" + itoa(catchPlan.RemainingWalkMinutes) + "分钟，已推进" + itoa(catchPlan.CompletedWalkMinutes) + "分钟，预计余量" + itoa(catchPlan.SafeBufferMinutes) + "分钟",
			Progress: catchPlan.Progress,
			Color:    catchPlan.StatusColor(step.LineColor),
			IconKey:  "transfer",
		}
	case "exit":
		return IndoorGuideProgressStatus{
			LeadText: "到达",
			Title:    "按出口指引出站",
			Subtitle: "推荐走" + step.TargetStation,
			Progress: 1,
			Color:    "#008C4A",
			IconKey:  "output",
		}
	default:
		catchPlan := catchPlanForIndoorStages(steps, index, map[string]bool{"entry": true, "platform": true}, arrival, 1)
		title := step.LineName + "当前班来得及"
		if catchPlan.UsesNextTrain {
			title = step.LineName + "赶不上，改按下一班"
		}
		return IndoorGuideProgressStatus{
			LeadText: itoa(catchPlan.TrainMinutes) + "分钟",
			Title:    title,
			Subtitle: "到站台还要约" + itoa(catchPlan.RemainingWalkMinutes) + "分钟，已推进" + itoa(catchPlan.CompletedWalkMinutes) + "分钟，预计余量" + itoa(catchPlan.SafeBufferMinutes) + "分钟",
			Progress: catchPlan.Progress,
			Color:    catchPlan.StatusColor(step.LineColor),
			IconKey:  "timer",
		}
	}
}

type indoorCatchPlan struct {
	TrainMinutes         int
	RemainingWalkMinutes int
	CompletedWalkMinutes int
	SafeBufferMinutes    int
	UsesNextTrain        bool
	Progress             float64
}

func (plan indoorCatchPlan) StatusColor(lineColor string) string {
	if plan.UsesNextTrain && plan.SafeBufferMinutes <= 0 {
		return "#BA1A1A"
	}
	if plan.UsesNextTrain || plan.SafeBufferMinutes < 2 {
		return "#E57900"
	}
	return lineColor
}

func catchPlanForIndoorStages(steps []IndoorGuideStep, index int, stages map[string]bool, arrival *MetroArrivalResult, safetyBufferMinutes int) indoorCatchPlan {
	currentTrain := currentTrainMinutes(arrival)
	nextTrain := nextTrainMinutes(arrival, currentTrain)
	remainingWalk := remainingMinutesForIndoorStages(steps, index, stages)
	completedWalk := completedMinutesForIndoorStages(steps, index, stages)
	requiredMinutes := remainingWalk + safetyBufferMinutes
	usesNextTrain := currentTrain < requiredMinutes
	selectedTrain := currentTrain
	if usesNextTrain {
		selectedTrain = nextTrain
	}
	buffer := selectedTrain - remainingWalk
	if buffer < 0 {
		buffer = 0
	}
	progress := 0.0
	if selectedTrain > 0 {
		progress = float64(selectedTrain-remainingWalk) / float64(selectedTrain)
	}

	return indoorCatchPlan{
		TrainMinutes:         selectedTrain,
		RemainingWalkMinutes: remainingWalk,
		CompletedWalkMinutes: completedWalk,
		SafeBufferMinutes:    buffer,
		UsesNextTrain:        usesNextTrain,
		Progress:             clampProgress(progress),
	}
}

func remainingMinutesForIndoorStages(steps []IndoorGuideStep, index int, stages map[string]bool) int {
	minutes := 0
	for i := index; i < len(steps); i++ {
		if !stages[steps[i].Stage] {
			if minutes > 0 {
				break
			}
			continue
		}
		minutes += steps[i].Minutes
	}
	if minutes <= 0 {
		return 1
	}
	return minutes
}

func completedMinutesForIndoorStages(steps []IndoorGuideStep, index int, stages map[string]bool) int {
	minutes := 0
	for i := 0; i < index; i++ {
		if stages[steps[i].Stage] {
			minutes += steps[i].Minutes
		}
	}
	return minutes
}

func currentTrainMinutes(arrival *MetroArrivalResult) int {
	if arrival == nil || arrival.CurrentArriveMinutes <= 0 {
		return 5
	}
	if arrival.CurrentArriveMinutes > 60 {
		return 60
	}
	return arrival.CurrentArriveMinutes
}

func nextTrainMinutes(arrival *MetroArrivalResult, currentTrainMinutes int) int {
	if arrival != nil && arrival.NextArriveMinutes > 0 {
		if arrival.NextArriveMinutes > 90 {
			return 90
		}
		return arrival.NextArriveMinutes
	}
	next := currentTrainMinutes + 7
	if next < 2 {
		return 2
	}
	if next > 90 {
		return 90
	}
	return next
}

func clampProgress(value float64) float64 {
	if value < 0 {
		return 0
	}
	if value > 0.95 {
		return 0.95
	}
	return value
}

func arrivalQueriesForRoute(route metroRoute) []map[string]string {
	queries := []map[string]string{}
	for _, segment := range route.Segments {
		queries = append(queries, arrivalQueryForSegment(segment, segment.From))
	}
	return queries
}

func arrivalQueryForSegment(segment IndoorGuideRouteSegment, station string) map[string]string {
	return map[string]string{
		"lineId":        lineIDForIndoorGuide(segment.LineName),
		"lineName":      segment.LineName,
		"stopId":        stopIDForIndoorGuide(station, segment.LineName),
		"stopName":      station,
		"direction":     itoa(segment.Direction),
		"directionName": segment.DirectionName,
		"cityCode":      indoorGuideCityCode,
	}
}

func buildRouteSummary(route metroRoute, steps []IndoorGuideStep, from string, to string) IndoorGuideSummary {
	lines := []string{}
	for _, segment := range route.Segments {
		lines = appendUnique(lines, segment.LineName)
	}
	duration := 0
	for _, step := range steps {
		duration += step.Minutes
	}
	doorHint := ""
	for _, step := range steps {
		if step.DoorHint != "" {
			doorHint = step.DoorHint
			break
		}
	}
	if doorHint == "" {
		doorHint = "中部车门"
	}
	transferText := "无需换乘"
	if len(route.TransferStations) > 0 {
		transferText = strings.Join(route.TransferStations, "、") + "换乘"
	}
	nextAction := "从" + profileForStation(from).Entrance + "进入"
	if len(steps) > 0 {
		nextAction = steps[0].Title
	}
	return IndoorGuideSummary{
		Title:           from + " → " + to,
		DurationMinutes: duration,
		TransferCount:   len(route.TransferStations),
		TransferText:    transferText,
		DoorHint:        doorHint,
		Lines:           lines,
		NextAction:      nextAction,
	}
}

func fallbackMetroRoute(from string, to string) metroRoute {
	segment := IndoorGuideRouteSegment{
		LineName:      "10号线",
		LineColor:     metroLineColors["10号线"],
		From:          from,
		To:            to,
		Stops:         []string{from, to},
		Direction:     directionForSegment("10号线", from, to),
		DirectionName: directionNameForLine("10号线", directionForSegment("10号线", from, to)),
	}
	return metroRoute{Segments: []IndoorGuideRouteSegment{segment}}
}

func nextTransferTarget(route metroRoute, index int) string {
	if index+1 < len(route.Segments) {
		return route.Segments[index+1].From
	}
	return route.Segments[index].To
}

func rideMinutesBetween(from string, to string) int {
	return rideMinutesPerStop
}

func transferMinutesForStation(station string, fromLine string, toLine string) int {
	if value, ok := transferMinutes[station+"|"+fromLine+"|"+toLine]; ok {
		return value
	}
	if value, ok := transferMinutes[station]; ok {
		return value
	}
	return 5
}

func doorHintForSegment(segment IndoorGuideRouteSegment, target string) string {
	if value, ok := doorHints[segment.LineName+"|"+target]; ok {
		return value
	}
	if value, ok := doorHints[segment.LineName+"|*"]; ok {
		return value
	}
	if value, ok := doorHints[segment.From+"|*"]; ok {
		return value
	}
	return "中部车门"
}

func normalizeIndoorStation(station string, fallback string) string {
	if station == "" {
		return fallback
	}
	switch station {
	case "上海虹桥火车站":
		return "虹桥火车站"
	default:
		return station
	}
}

func entranceForIndoorGuide(station string) string {
	switch station {
	case "五角场":
		return "5号口"
	case "同济大学":
		return "2号口"
	case "虹桥火车站":
		return "北2入口"
	case "陕西南路":
		return "6号口"
	default:
		return "6号口"
	}
}

func exitForIndoorGuide(station string) string {
	switch station {
	case "静安寺":
		return "3号口"
	case "虹桥火车站":
		return "B出口"
	case "五角场":
		return "5号口"
	case "陕西南路":
		return "2号口"
	default:
		return "1号口"
	}
}

func stopIDForIndoorGuide(station string, line string) string {
	if byLine, ok := stationStopIDs[station]; ok {
		if value, ok := byLine[line]; ok {
			return value
		}
	}
	return "xintiandi_10"
}

func lineIDForIndoorGuide(line string) string {
	if value, ok := lineIDs[line]; ok {
		return value
	}
	return "mock-line-10"
}

func directionForSegment(line string, from string, to string) int {
	stations := metroLineStations[line]
	fromIndex := stationIndex(stations, from)
	toIndex := stationIndex(stations, to)
	if fromIndex < 0 || toIndex < 0 {
		return 0
	}
	if toIndex >= fromIndex {
		return 0
	}
	return 1
}

func directionNameForLine(line string, direction int) string {
	stations := metroLineStations[line]
	if len(stations) == 0 {
		return ""
	}
	if direction == 1 {
		return "往" + stations[0]
	}
	return "往" + stations[len(stations)-1]
}

func stationIndex(stations []string, station string) int {
	for i, item := range stations {
		if item == station {
			return i
		}
	}
	return -1
}

func appendUnique(values []string, value string) []string {
	for _, item := range values {
		if item == value {
			return values
		}
	}
	return append(values, value)
}

func reverseStates(states []metroState) {
	for i, j := 0, len(states)-1; i < j; i, j = i+1, j-1 {
		states[i], states[j] = states[j], states[i]
	}
}

func itoa(value int) string {
	if value == 0 {
		return "0"
	}
	digits := []byte{}
	for value > 0 {
		digits = append([]byte{byte('0' + value%10)}, digits...)
		value /= 10
	}
	return string(digits)
}
