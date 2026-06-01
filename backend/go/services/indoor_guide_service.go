package services

type IndoorGuideStep struct {
	Stage          string `json:"stage"`
	LineName       string `json:"lineName"`
	LineColor      string `json:"lineColor"`
	Title          string `json:"title"`
	Detail         string `json:"detail"`
	ImageTitle     string `json:"imageTitle"`
	ImageSubtitle  string `json:"imageSubtitle"`
	Minutes        int    `json:"minutes"`
	IconKey        string `json:"iconKey"`
	TargetStation  string `json:"targetStation,omitempty"`
	RemainingStops int    `json:"remainingStops,omitempty"`
	TotalStops     int    `json:"totalStops,omitempty"`
	DoorHint       string `json:"doorHint,omitempty"`
}

type IndoorGuideRouteSegment struct {
	LineName  string   `json:"lineName"`
	LineColor string   `json:"lineColor"`
	From      string   `json:"from"`
	To        string   `json:"to"`
	Stops     []string `json:"stops"`
}

type IndoorGuidePlan struct {
	From             string                    `json:"from"`
	To               string                    `json:"to"`
	TransferStations []string                  `json:"transferStations"`
	TransferStation  string                    `json:"transferStation"`
	ArrivalQuery     map[string]string         `json:"arrivalQuery"`
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

func BuildIndoorGuide(from string, to string) IndoorGuidePlan {
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
	return IndoorGuidePlan{
		From:             from,
		To:               to,
		TransferStations: route.TransferStations,
		TransferStation:  transferStation,
		ArrivalQuery: map[string]string{
			"lineId":    lineIDForIndoorGuide(firstSegment.LineName),
			"lineName":  firstSegment.LineName,
			"stopId":    stopIDForIndoorGuide(from, firstSegment.LineName),
			"stopName":  from,
			"direction": "0",
			"cityCode":  "mock-shanghai",
		},
		Route: route.Segments,
		Steps: steps,
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
	return IndoorGuideRouteSegment{
		LineName:  line,
		LineColor: metroLineColors[line],
		From:      stops[0],
		To:        stops[len(stops)-1],
		Stops:     append([]string{}, stops...),
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
	return steps
}

func entryStepsForStation(station string, line string) []IndoorGuideStep {
	entrance := entranceForIndoorGuide(station)
	lineColor := metroLineColors[line]
	if station == "虹桥火车站" {
		return []IndoorGuideStep{
			guideStep("entry", line, lineColor, "从"+entrance+"进入", "跟随地铁/Metro标识进入地下通道，避开高铁出站人流正面汇入点。", entrance+" 实景确认", "确认前方有地铁进站导向牌", 1, "login"),
			guideStep("entry", line, lineColor, "沿右侧通道直行", "保持在右侧通道，看到10号线/2号线/17号线分流牌后继续向前。", "虹桥火车站到达层通道", "右侧通道更靠近地铁入口", 2, "straight"),
			guideStep("entry", line, lineColor, "下扶梯到站厅", "下行后选择对应线路闸机口，先看清方向再刷码进站。", "站厅扶梯口", "确认目标线路颜色和方向牌", 1, "escalator"),
		}
	}

	return []IndoorGuideStep{
		guideStep("entry", line, lineColor, "从"+entrance+"进入", "面向地铁入口向前走，优先选择人流较少的一侧进站。", entrance+" 实景确认", "看见"+line+"标识后继续直行", 1, "login"),
		guideStep("entry", line, lineColor, "下扶梯到站厅", "扶梯到底后保持直行，不要先跟随出站人流转弯。", "站厅扶梯口", "确认前方有"+line+"站台指示牌", 1, "escalator"),
		guideStep("entry", line, lineColor, "刷码后右转", "过闸机后右转，跟随目标线路方向标识。", "闸机后右转通道", "右侧通道前往"+line+"站台", 1, "turnRight"),
	}
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
	if station == "南京东路" && fromLine == "10号线" && toLine == "2号线" {
		return []IndoorGuideStep{
			guideStep("transfer", toLine, lineColor, "下车后向车头方向走", "不要先上出站扶梯，沿站台向前走到换乘扶梯。", station+" "+fromLine+"站台", "车头方向可见换乘扶梯", 1, "straight"),
			guideStep("transfer", toLine, lineColor, "上扶梯后左转", "扶梯到站厅后左转，进入2号线换乘通道。", "换乘扶梯出口", "左侧为2号线换乘通道", 1, "turnLeft"),
			guideStep("transferWait", toLine, lineColor, "到2号线站台候车", "确认方向为“徐泾东/静安寺方向”，站到中部车门附近。", "2号线候车区", "确认绿色2号线方向牌", 1, "signpost"),
		}
	}
	if station == "虹桥火车站" {
		return []IndoorGuideStep{
			guideStep("transfer", toLine, lineColor, "跟随换乘大厅指示", "下车后进入换乘大厅，先看清"+toLine+"方向牌。", station+"换乘大厅", "确认目标线路颜色后继续", 2, "straight"),
			guideStep("transferWait", toLine, lineColor, "到"+toLine+"站台候车", "虹桥客流较大，优先站到车门侧后方，避免堵在扶梯口。", toLine+"候车区", "确认开往目标方向的站台", 1, "signpost"),
		}
	}
	return []IndoorGuideStep{
		guideStep("transfer", toLine, lineColor, "跟随"+toLine+"换乘标识", "下车后不要出站，沿站内换乘通道前往"+toLine+"。", station+"换乘通道", "确认"+toLine+"方向牌", 2, "straight"),
		guideStep("transferWait", toLine, lineColor, "到"+toLine+"站台候车", "到达站台后确认行车方向，再靠近推荐车门候车。", toLine+"候车区", "确认方向牌后候车", 1, "signpost"),
	}
}

func exitStepsForStation(station string) []IndoorGuideStep {
	exit := exitForIndoorGuide(station)
	return []IndoorGuideStep{
		guideStep("exit", "出站", metroLineColors["出站"], "从"+exit+"出站", "跟随出口编号走，出闸后靠右侧通道出站。", exit+" 出口实景", "确认出口编号后再上行", 3, "output"),
	}
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

func fallbackMetroRoute(from string, to string) metroRoute {
	segment := IndoorGuideRouteSegment{
		LineName:  "10号线",
		LineColor: metroLineColors["10号线"],
		From:      from,
		To:        to,
		Stops:     []string{from, to},
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
	return 2
}

func transferMinutesForStation(station string, fromLine string, toLine string) int {
	switch station {
	case "虹桥火车站":
		return 6
	case "南京东路":
		return 5
	case "虹桥路", "交通大学", "陕西南路":
		return 4
	default:
		return 5
	}
}

func doorHintForSegment(segment IndoorGuideRouteSegment, target string) string {
	if segment.LineName == "10号线" && target == "南京东路" {
		return "4车2门"
	}
	if segment.From == "虹桥火车站" {
		return "2车3门"
	}
	if segment.LineName == "2号线" {
		return "中部车门"
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
	if station == "虹桥火车站" && line == "2号线" {
		return "hongqiao_railway_2"
	}
	if station == "虹桥火车站" && line == "17号线" {
		return "hongqiao_railway_17"
	}
	switch station {
	case "五角场":
		return "wujiaochang_10"
	case "同济大学":
		return "tongji_university_10"
	case "虹桥火车站":
		return "hongqiao_railway_10"
	default:
		return "xintiandi_10"
	}
}

func lineIDForIndoorGuide(line string) string {
	switch line {
	case "2号线":
		return "mock-line-2"
	case "17号线":
		return "mock-line-17"
	default:
		return "mock-line-10"
	}
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
