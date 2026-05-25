package config

type QwenConfig struct {
	BaseURL string
	APIKey  string
	Model   string
}

func GetQwenConfig() QwenConfig {
	return QwenConfig{
		BaseURL: getEnvOrDefault("QWEN_BASE_URL", "https://dashscope.aliyuncs.com/compatible-mode/v1"),
		APIKey:  getEnvOrDefault("QWEN_API_KEY", ""),
		Model:   getEnvOrDefault("QWEN_MODEL", "qwen-max"),
	}
}