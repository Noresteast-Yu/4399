package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"smart-travel-backend/config"
)

type QwenRequest struct {
	Model    string          `json:"model"`
	Messages []QwenMessage   `json:"messages"`
	MaxTokens int            `json:"max_tokens,omitempty"`
}

type QwenMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type QwenResponse struct {
	Choices []QwenChoice `json:"choices"`
	Error   *QwenError   `json:"error,omitempty"`
}

type QwenChoice struct {
	Message QwenMessage `json:"message"`
}

type QwenError struct {
	Message string `json:"message"`
	Type    string `json:"type"`
}

var qwenClient = &http.Client{
	Timeout: 30 * time.Second,
}

func GenerateRouteAnalysis(routeJSON string) (string, error) {
	prompt := fmt.Sprintf(`你是一位专业的地铁出行顾问。请根据以下用户需求和路线信息，生成详细的路线建议：

用户个性化需求：
- 行动能力水平：%s
- 是否需要电梯：%s
- 是否需要扶梯：%s
- 是否避免楼梯：%s
- 最大步行距离：%d米
- 是否携带行李：%s
- 行李大小：%s
- 行李数量：%d件
- 是否需要宽闸机：%s

路线信息：%s

请综合考虑用户的具体需求，提供包含以下内容的详细建议：
1. 路径规划：详细列出每个路段的交通方式和站点
2. 交通方式建议：针对用户需求推荐最适合的交通工具
3. 预计行程时间：总时间和各段耗时
4. 关键站点说明：重要换乘站和服务设施
5. 适应性调整建议：特别针对用户需求的贴心提醒

请用清晰的中文回答，突出满足用户特殊需求的部分。`, 
	getUserMobilityDescription(),
	getElevatorRequirement(),
	getEscalatorRequirement(), 
	getStairAvoidance(),
	getMaxWalkingDistance(),
	getLuggageCarryStatus(),
	getLuggageSize(),
	getLuggageCount(),
	getWideGateRequirement(),
	routeJSON)

	req := QwenRequest{
		Model: config.GetQwenConfig().Model,
		Messages: []QwenMessage{
			{Role: "system", Content: "你是一位专业的地铁出行顾问，擅长为用户提供个性化、贴心的出行建议。你会充分考虑用户的身体状况、行动能力和特殊需求，提供最合适的路线规划。"},
			{Role: "user", Content: prompt},
		},
		MaxTokens: 500,
	}

	resp, err := callQwenAPI(req)
	if err != nil {
		return "", err
	}

	if len(resp.Choices) > 0 {
		return resp.Choices[0].Message.Content, nil
	}

	return "", fmt.Errorf("Qwen 返回空响应")
}

// 生成带有用户偏好数据的路线分析
func GenerateRouteAnalysisWithPrefs(routeJSON string, preferences map[string]interface{}) (string, error) {
	// 获取具体的偏好值
	mobilityLevel := getStringWithDefault(getMap(preferences, "mobilitySettings"), "mobilityLevel", "normal")
	needElevator := getBoolWithDefault(getMap(preferences, "mobilitySettings"), "needElevator", false)
	needEscalator := getBoolWithDefault(getMap(preferences, "mobilitySettings"), "needEscalator", false)
	avoidStairs := getBoolWithDefault(getMap(preferences, "mobilitySettings"), "avoidStairs", false)
	maxWalkingDistance := getIntWithDefault(getMap(preferences, "mobilitySettings"), "maxWalkingDistance", 500)
	hasLuggage := getBoolWithDefault(getMap(preferences, "luggageSettings"), "hasLuggage", false)
	luggageSize := getStringWithDefault(getMap(preferences, "luggageSettings"), "luggageSize", "small")
	luggageCount := getIntWithDefault(getMap(preferences, "luggageSettings"), "luggageCount", 0)
	needWideGate := getBoolWithDefault(getMap(preferences, "luggageSettings"), "needWideGate", false)

	prompt := fmt.Sprintf(`你是一位专业的地铁出行顾问。请根据以下用户个性化需求和路线信息，生成详细且贴心的路线建议：

用户个性化需求：
- 行动能力水平：%s
- 是否需要电梯：%t
- 是否需要扶梯：%t
- 是否避免楼梯：%t
- 最大步行距离：%d米
- 是否携带行李：%t
- 行李大小：%s
- 行李数量：%d件
- 是否需要宽闸机：%t

路线信息：%s

请综合考虑用户的具体需求，提供包含以下内容的详细建议：
1. 路径规划：详细列出每个路段的交通方式和站点
2. 交通方式建议：针对用户需求推荐最适合的交通工具
3. 预计行程时间：总时间和各段耗时
4. 关键站点说明：重要换乘站和服务设施
5. 适应性调整建议：特别针对用户需求的贴心提醒

请用清晰的中文回答，突出满足用户特殊需求的部分。`,
		mobilityLevel,
		needElevator,
		needEscalator,
		avoidStairs,
		maxWalkingDistance,
		hasLuggage,
		luggageSize,
		luggageCount,
		needWideGate,
		routeJSON)

	req := QwenRequest{
		Model: config.GetQwenConfig().Model,
		Messages: []QwenMessage{
			{Role: "system", Content: "你是一位专业的地铁出行顾问，擅长为用户提供个性化、贴心的出行建议。你会充分考虑用户的身体状况、行动能力和特殊需求，提供最合适的路线规划。"},
			{Role: "user", Content: prompt},
		},
		MaxTokens: 500,
	}

	resp, err := callQwenAPI(req)
	if err != nil {
		return "", err
	}

	if len(resp.Choices) > 0 {
		return resp.Choices[0].Message.Content, nil
	}

	return "", fmt.Errorf("Qwen 返回空响应")
}

// 辅助函数，提供默认的用户需求描述
func getUserMobilityDescription() string {
	return "普通水平，可根据实际情况调整建议"
}

func getElevatorRequirement() string {
	return "无特殊要求，如有电梯则优先使用"
}

func getEscalatorRequirement() string {
	return "无特殊要求"
}

func getStairAvoidance() string {
	return "可接受少量楼梯"
}

func getMaxWalkingDistance() int {
	return 500
}

func getLuggageCarryStatus() string {
	return "轻便小件行李"
}

func getLuggageSize() string {
	return "小件"
}

func getLuggageCount() int {
	return 1
}

func getWideGateRequirement() string {
	return "无特殊要求"
}

func callQwenAPI(req QwenRequest) (*QwenResponse, error) {
	jsonData, err := json.Marshal(req)
	if err != nil {
		return nil, err
	}

	qwenCfg := config.GetQwenConfig()
	url := qwenCfg.BaseURL + "/chat/completions"
	httpReq, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, err
	}

	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+qwenCfg.APIKey)

	resp, err := qwenClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("Qwen API 请求失败: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("Qwen API 返回错误 (HTTP %d): %s", resp.StatusCode, string(body))
	}

	var qwenResp QwenResponse
	if err := json.Unmarshal(body, &qwenResp); err != nil {
		return nil, fmt.Errorf("解析 Qwen 响应失败: %w", err)
	}

	if qwenResp.Error != nil {
		return nil, fmt.Errorf("Qwen API 错误: %s", qwenResp.Error.Message)
	}

	return &qwenResp, nil
}