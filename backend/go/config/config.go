package config

import (
	"log"
	"os"
	"strings"

	"github.com/joho/godotenv"
)

type Config struct {
	ServerPort       string
	DBHost           string
	DBPort           string
	DBUser           string
	DBPassword       string
	DBName           string
	ShmaasHost       string
	ShmaasMerchantID string
	ShmaasSalt       string
	ShmaasCityCode   string
	CORSOrigins      []string
}

var AppConfig *Config

func LoadConfig() {
	err := godotenv.Load()
	if err != nil {
		log.Println("未找到 .env 文件，使用默认配置")
	}

	AppConfig = &Config{
		ServerPort:       getEnv("PORT", "3000"),
		DBHost:           getEnv("DB_HOST", "localhost"),
		DBPort:           getEnv("DB_PORT", "3306"),
		DBUser:           getEnv("DB_USER", "root"),
		DBPassword:       getEnv("DB_PASSWORD", ""),
		DBName:           getEnv("DB_NAME", "smart_travel"),
		ShmaasHost:       getEnv("SHMAAS_HOST", "http://127.0.0.1:8787"),
		ShmaasMerchantID: getEnv("SHMAAS_MERCHANT_ID", "mock-merchant"),
		ShmaasSalt:       getEnv("SHMAAS_SALT", "mock-salt"),
		ShmaasCityCode:   getEnv("SHMAAS_CITY_CODE", "mock-shanghai"),
		CORSOrigins:      splitEnv("CORS_ORIGINS", "*"),
	}
}

func getEnv(key, defaultValue string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return defaultValue
}

func getEnvOrDefault(key, defaultValue string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return defaultValue
}

func splitEnv(key, defaultValue string) []string {
	raw := getEnv(key, defaultValue)
	parts := strings.Split(raw, ",")
	values := make([]string, 0, len(parts))
	for _, part := range parts {
		value := strings.TrimSpace(part)
		if value != "" {
			values = append(values, value)
		}
	}
	if len(values) == 0 {
		return []string{defaultValue}
	}
	return values
}
