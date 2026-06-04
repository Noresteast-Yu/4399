package main

import (
	"log"

	"smart-travel-backend/config"
	"smart-travel-backend/database"
	"smart-travel-backend/router"
)

func main() {
	config.LoadConfig()

	if err := database.InitDB(); err != nil {
		log.Printf("数据库连接失败，将以模拟模式运行: %v", err)
	}
	defer database.CloseDB()

	r := router.SetupRouter()

	port := ":" + config.AppConfig.ServerPort
	log.Printf("服务器运行在端口 %s", port)

	if err := r.Run(port); err != nil {
		log.Fatalf("服务器启动失败: %v", err)
	}
}
