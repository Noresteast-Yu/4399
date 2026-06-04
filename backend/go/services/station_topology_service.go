package services

import (
	"encoding/json"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"strings"
)

type StationTopology struct {
	StationID            string                   `json:"stationId"`
	StationName          string                   `json:"stationName"`
	LineIDs              []string                 `json:"lineIds"`
	GraphName            string                   `json:"graphName"`
	WeightUnit           string                   `json:"weightUnit"`
	PhotoBasePath        string                   `json:"photoBasePath"`
	Nodes                []TopologyNode           `json:"nodes"`
	Edges                []TopologyEdge           `json:"edges"`
	Facilities           []TopologyFacility       `json:"facilities"`
	Exits                []TopologyExit           `json:"exits"`
	PhotoSlots           []TopologyPhoto          `json:"photoSlots"`
	CoordinateRule       map[string]string        `json:"coordinateRule,omitempty"`
	FacilityReference    []map[string]interface{} `json:"facilityReference,omitempty"`
	TrainCarAssociations map[string]interface{}   `json:"trainCarAssociations,omitempty"`
	DataVersion          string                   `json:"dataVersion,omitempty"`
}

type TopologyNode struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	Type        string   `json:"type,omitempty"`
	Floor       string   `json:"floor,omitempty"`
	Area        string   `json:"area,omitempty"`
	X           int      `json:"x,omitempty"`
	Y           int      `json:"y,omitempty"`
	PhotoKey    string   `json:"photoKey,omitempty"`
	Description string   `json:"description,omitempty"`
	Facilities  []string `json:"facilities,omitempty"`
}

type TopologyEdge struct {
	From          string `json:"from"`
	To            string `json:"to"`
	Time          int    `json:"time"`
	Bidirectional bool   `json:"bidirectional"`
	Type          string `json:"type,omitempty"`
	Action        string `json:"action,omitempty"`
	Direction     string `json:"direction,omitempty"`
	Note          string `json:"note,omitempty"`
	UpMode        string `json:"upMode,omitempty"`
	DownMode      string `json:"downMode,omitempty"`
	PhotoKey      string `json:"photoKey,omitempty"`
}

type TopologyFacility struct {
	ID       string `json:"id"`
	Type     string `json:"type"`
	Name     string `json:"name"`
	NodeID   string `json:"nodeId"`
	Floor    string `json:"floor,omitempty"`
	PhotoKey string `json:"photoKey,omitempty"`
}

type TopologyExit struct {
	ExitNo    string   `json:"exitNo"`
	Name      string   `json:"name"`
	NodeID    string   `json:"nodeId"`
	Landmarks []string `json:"landmarks"`
	PhotoKey  string   `json:"photoKey,omitempty"`
}

type TopologyPhoto struct {
	PhotoKey string `json:"photoKey"`
	Title    string `json:"title"`
	File     string `json:"file"`
}

type IndoorNavigationPath struct {
	StationID        string                    `json:"stationId"`
	StationName      string                    `json:"stationName"`
	FromNode         TopologyNode              `json:"fromNode"`
	ToNode           TopologyNode              `json:"toNode"`
	TargetType       string                    `json:"targetType"`
	TargetID         string                    `json:"targetId"`
	TotalSeconds     int                       `json:"totalSeconds"`
	TotalMinutesText string                    `json:"totalMinutesText"`
	NodePath         []TopologyNode            `json:"nodePath"`
	Steps            []IndoorNavigationStep    `json:"steps"`
	Target           map[string]interface{}    `json:"target,omitempty"`
	PhotoSlots       []TopologyPhoto           `json:"photoSlots"`
	Debug            IndoorNavigationDebugInfo `json:"debug"`
}

type IndoorNavigationStep struct {
	Index       int          `json:"index"`
	FromNode    TopologyNode `json:"fromNode"`
	ToNode      TopologyNode `json:"toNode"`
	Title       string       `json:"title"`
	Instruction string       `json:"instruction"`
	Seconds     int          `json:"seconds"`
	EdgeType    string       `json:"edgeType"`
	PhotoKey    string       `json:"photoKey,omitempty"`
	PhotoFile   string       `json:"photoFile,omitempty"`
	Note        string       `json:"note,omitempty"`
}

type IndoorNavigationDebugInfo struct {
	GraphName  string `json:"graphName"`
	WeightUnit string `json:"weightUnit"`
	EdgeCount  int    `json:"edgeCount"`
	NodeCount  int    `json:"nodeCount"`
}

type directedTopologyEdge struct {
	Edge     TopologyEdge
	From     string
	To       string
	Reversed bool
}

func BuildIndoorNavigationPath(stationID string, fromNodeID string, toNodeID string, targetType string, targetID string) (*IndoorNavigationPath, error) {
	topology, err := LoadStationTopology(stationID)
	if err != nil {
		return nil, err
	}

	nodeByID := topology.nodeMap()
	fromNode, ok := nodeByID[fromNodeID]
	if !ok {
		return nil, fmt.Errorf("起点节点不存在: %s", fromNodeID)
	}

	targetNodeID, target, err := topology.resolveTargetNode(toNodeID, targetType, targetID)
	if err != nil {
		return nil, err
	}
	toNode, ok := nodeByID[targetNodeID]
	if !ok {
		return nil, fmt.Errorf("终点节点不存在: %s", targetNodeID)
	}

	edgePath, err := shortestTopologyPath(topology, fromNode.ID, toNode.ID)
	if err != nil {
		return nil, err
	}

	photoByKey := topology.photoMap()
	nodePath := []TopologyNode{fromNode}
	steps := make([]IndoorNavigationStep, 0, len(edgePath))
	totalSeconds := 0
	for index, edge := range edgePath {
		to := nodeByID[edge.To]
		totalSeconds += edge.Edge.Time
		nodePath = append(nodePath, to)
		steps = append(steps, indoorNavigationStep(index+1, nodePath, edge, photoByKey))
	}

	if targetType == "" {
		targetType = "node"
	}
	if targetID == "" {
		targetID = toNode.ID
	}

	return &IndoorNavigationPath{
		StationID:        topology.StationID,
		StationName:      topology.StationName,
		FromNode:         fromNode,
		ToNode:           toNode,
		TargetType:       targetType,
		TargetID:         targetID,
		TotalSeconds:     totalSeconds,
		TotalMinutesText: secondsText(totalSeconds),
		NodePath:         nodePath,
		Steps:            steps,
		Target:           target,
		PhotoSlots:       topology.PhotoSlots,
		Debug: IndoorNavigationDebugInfo{
			GraphName:  topology.GraphName,
			WeightUnit: topology.WeightUnit,
			EdgeCount:  len(topology.Edges),
			NodeCount:  len(topology.Nodes),
		},
	}, nil
}

func LoadStationTopology(stationID string) (*StationTopology, error) {
	if stationID == "" {
		stationID = "tongji_university"
	}

	for _, path := range stationTopologyPaths(stationID) {
		raw, err := os.ReadFile(path)
		if err != nil {
			continue
		}
		var topology StationTopology
		if err := json.Unmarshal(raw, &topology); err != nil {
			return nil, fmt.Errorf("站内拓扑数据解析失败: %w", err)
		}
		if topology.StationID == "" {
			topology.StationID = stationID
		}
		if topology.WeightUnit == "" {
			topology.WeightUnit = "seconds"
		}
		return &topology, nil
	}

	return nil, fmt.Errorf("未找到站内拓扑数据: %s", stationID)
}

func stationTopologyPaths(stationID string) []string {
	filename := stationID + ".json"
	paths := []string{
		filepath.Join("data", "station_topologies", filename),
		filepath.Join("..", "data", "station_topologies", filename),
		filepath.Join("backend", "go", "data", "station_topologies", filename),
	}
	if wd, err := os.Getwd(); err == nil {
		paths = append(paths,
			filepath.Join(wd, "data", "station_topologies", filename),
			filepath.Join(wd, "..", "data", "station_topologies", filename),
			filepath.Join(wd, "backend", "go", "data", "station_topologies", filename),
		)
	}
	return paths
}

func (topology StationTopology) nodeMap() map[string]TopologyNode {
	out := map[string]TopologyNode{}
	for _, node := range topology.Nodes {
		out[node.ID] = node
	}
	return out
}

func (topology StationTopology) photoMap() map[string]TopologyPhoto {
	out := map[string]TopologyPhoto{}
	for _, photo := range topology.PhotoSlots {
		out[photo.PhotoKey] = photo
	}
	return out
}

func (topology StationTopology) resolveTargetNode(toNodeID string, targetType string, targetID string) (string, map[string]interface{}, error) {
	if toNodeID != "" {
		return toNodeID, nil, nil
	}

	switch targetType {
	case "facility":
		for _, facility := range topology.Facilities {
			if facility.ID == targetID || facility.Type == targetID || facility.Name == targetID {
				return facility.NodeID, map[string]interface{}{
					"id":       facility.ID,
					"type":     facility.Type,
					"name":     facility.Name,
					"nodeId":   facility.NodeID,
					"floor":    facility.Floor,
					"photoKey": facility.PhotoKey,
				}, nil
			}
		}
		return "", nil, fmt.Errorf("设施不存在: %s", targetID)
	case "exit":
		for _, exit := range topology.Exits {
			if exit.ExitNo == targetID || exit.Name == targetID {
				return exit.NodeID, map[string]interface{}{
					"exitNo":    exit.ExitNo,
					"name":      exit.Name,
					"nodeId":    exit.NodeID,
					"landmarks": exit.Landmarks,
					"photoKey":  exit.PhotoKey,
				}, nil
			}
		}
		return "", nil, fmt.Errorf("出口不存在: %s", targetID)
	default:
		return "", nil, fmt.Errorf("请提供 toNodeId，或 targetType=facility/exit 与 targetId")
	}
}

func shortestTopologyPath(topology *StationTopology, from string, to string) ([]directedTopologyEdge, error) {
	nodeByID := topology.nodeMap()
	edges := expandTopologyEdges(topology.Edges)
	graph := map[string][]directedTopologyEdge{}
	for _, edge := range edges {
		graph[edge.From] = append(graph[edge.From], edge)
	}

	dist := map[string]int{}
	prevNode := map[string]string{}
	prevEdge := map[string]directedTopologyEdge{}
	visited := map[string]bool{}
	for id := range nodeByID {
		dist[id] = math.MaxInt / 4
	}
	dist[from] = 0

	for {
		current := ""
		best := math.MaxInt / 4
		for id := range nodeByID {
			if !visited[id] && dist[id] < best {
				current = id
				best = dist[id]
			}
		}
		if current == "" {
			break
		}
		if current == to {
			break
		}
		visited[current] = true

		for _, edge := range graph[current] {
			nextCost := best + edge.Edge.Time
			if nextCost < dist[edge.To] {
				dist[edge.To] = nextCost
				prevNode[edge.To] = current
				prevEdge[edge.To] = edge
			}
		}
	}

	if dist[to] >= math.MaxInt/4 {
		return nil, fmt.Errorf("无法从 %s 到达 %s", from, to)
	}

	path := []directedTopologyEdge{}
	for current := to; current != from; {
		edge, ok := prevEdge[current]
		if !ok {
			return nil, fmt.Errorf("路径回溯失败: %s", current)
		}
		path = append([]directedTopologyEdge{edge}, path...)
		current = prevNode[current]
	}

	return path, nil
}

func expandTopologyEdges(edges []TopologyEdge) []directedTopologyEdge {
	out := []directedTopologyEdge{}
	for _, edge := range edges {
		out = append(out, directedTopologyEdge{
			Edge: edge,
			From: edge.From,
			To:   edge.To,
		})
		if edge.Bidirectional {
			out = append(out, directedTopologyEdge{
				Edge:     edge,
				From:     edge.To,
				To:       edge.From,
				Reversed: true,
			})
		}
	}
	return out
}

func indoorNavigationStep(index int, nodePath []TopologyNode, edge directedTopologyEdge, photos map[string]TopologyPhoto) IndoorNavigationStep {
	from := nodePath[len(nodePath)-2]
	to := nodePath[len(nodePath)-1]
	photoKey := edge.Edge.PhotoKey
	if photoKey == "" {
		photoKey = to.PhotoKey
	}
	photoFile := ""
	if photo, ok := photos[photoKey]; ok {
		photoFile = photo.File
	}

	return IndoorNavigationStep{
		Index:       index,
		FromNode:    from,
		ToNode:      to,
		Title:       stepTitle(nodePath, edge, to.Name),
		Instruction: stepInstruction(nodePath, edge),
		Seconds:     edge.Edge.Time,
		EdgeType:    edge.Edge.Type,
		PhotoKey:    photoKey,
		PhotoFile:   photoFile,
		Note:        edge.Edge.Note,
	}
}

func stepTitle(nodePath []TopologyNode, edge directedTopologyEdge, toName string) string {
	from := nodePath[len(nodePath)-2]
	to := nodePath[len(nodePath)-1]
	if useStoredEdgeAction(nodePath, edge) {
		return edge.Edge.Action
	}

	switch edge.Edge.Type {
	case "entry_gate":
		return "刷码进站"
	case "exit_gate":
		return "刷码出站"
	case "vertical":
		return verticalAction(from, to, verticalMode(edge, from, to))
	case "elevator":
		return "乘坐无障碍电梯"
	case "facility":
		return "到达设施"
	default:
		if len(nodePath) >= 3 {
			return directionPrefix(nodePath)
		}
		return "向前走"
	}
}

func stepInstruction(nodePath []TopologyNode, edge directedTopologyEdge) string {
	from := nodePath[len(nodePath)-2]
	to := nodePath[len(nodePath)-1]
	if useStoredEdgeAction(nodePath, edge) {
		if edge.Edge.Note != "" {
			return edge.Edge.Action + "，前往" + to.Name + "。" + edge.Edge.Note
		}
		return edge.Edge.Action + "，前往" + to.Name
	}

	switch edge.Edge.Type {
	case "entry_gate":
		return "刷码进站，通过闸机后到达" + to.Name
	case "exit_gate":
		return "刷码出站，通过闸机后到达" + to.Name
	case "vertical":
		mode := verticalMode(edge, from, to)
		return verticalAction(from, to, mode) + "到" + to.Name
	case "elevator":
		return elevatorAction(from, to) + "到" + to.Name
	case "facility":
		return directionPrefix(nodePath) + "，到达" + to.Name
	default:
		return directionPrefix(nodePath) + "，前往" + to.Name
	}
}

func useStoredEdgeAction(nodePath []TopologyNode, edge directedTopologyEdge) bool {
	if edge.Edge.Action == "" || edge.Reversed {
		return false
	}
	switch edge.Edge.Type {
	case "entry_gate", "exit_gate", "vertical", "elevator":
		return true
	default:
		return len(nodePath) < 3
	}
}

func directionPrefix(nodePath []TopologyNode) string {
	if len(nodePath) < 3 {
		from := nodePath[len(nodePath)-2]
		return "从" + from.Name + "出发，沿通道前进"
	}

	prev := nodePath[len(nodePath)-3]
	current := nodePath[len(nodePath)-2]
	next := nodePath[len(nodePath)-1]

	v1x := current.X - prev.X
	v1y := current.Y - prev.Y
	v2x := next.X - current.X
	v2y := next.Y - current.Y

	if v1x == 0 && v1y == 0 || v2x == 0 && v2y == 0 {
		return "继续前进"
	}

	cross := v1x*v2y - v1y*v2x
	dot := v1x*v2x + v1y*v2y
	lenProduct := math.Sqrt(float64(v1x*v1x+v1y*v1y)) *
		math.Sqrt(float64(v2x*v2x+v2y*v2y))

	if lenProduct == 0 {
		return "继续前进"
	}

	turnRatio := math.Abs(float64(cross)) / lenProduct
	if turnRatio < 0.35 {
		if dot < 0 {
			return "掉头"
		}
		return "直行"
	}
	if cross > 0 {
		return "左转"
	}
	return "右转"
}

func verticalAction(from TopologyNode, to TopologyNode, mode string) string {
	if from.Floor == to.Floor {
		return "通过" + mode + "前进"
	}
	if floorRank(to.Floor) > floorRank(from.Floor) {
		return "下" + mode
	}
	return "上" + mode
}

func elevatorAction(from TopologyNode, to TopologyNode) string {
	if from.Floor == to.Floor {
		return "乘坐无障碍电梯"
	}
	if floorRank(to.Floor) > floorRank(from.Floor) {
		return "乘坐无障碍电梯下行"
	}
	return "乘坐无障碍电梯上行"
}

func floorRank(floor string) int {
	switch strings.TrimSpace(floor) {
	case "ground", "G", "1F":
		return 0
	case "B1":
		return 1
	case "B2":
		return 2
	default:
		return 0
	}
}

func absInt(value int) int {
	if value < 0 {
		return -value
	}
	return value
}

func verticalMode(edge directedTopologyEdge, from TopologyNode, to TopologyNode) string {
	if floorRank(to.Floor) > floorRank(from.Floor) {
		if edge.Edge.DownMode != "" {
			return modeText(edge.Edge.DownMode)
		}
		if edge.Edge.UpMode != "" {
			return modeText(edge.Edge.UpMode)
		}
	}
	if floorRank(to.Floor) < floorRank(from.Floor) {
		if edge.Edge.UpMode != "" {
			return modeText(edge.Edge.UpMode)
		}
		if edge.Edge.DownMode != "" {
			return modeText(edge.Edge.DownMode)
		}
	}
	return "楼梯/扶梯"
}

func modeText(mode string) string {
	switch strings.TrimSpace(mode) {
	case "escalator":
		return "扶梯"
	case "stairs":
		return "楼梯"
	case "elevator":
		return "电梯"
	default:
		return mode
	}
}

func secondsText(seconds int) string {
	if seconds < 60 {
		return itoa(seconds) + "秒"
	}
	minutes := seconds / 60
	remainder := seconds % 60
	if remainder == 0 {
		return itoa(minutes) + "分钟"
	}
	return itoa(minutes) + "分" + itoa(remainder) + "秒"
}
