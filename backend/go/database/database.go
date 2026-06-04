package database

import (
	"database/sql"
	"fmt"
	"log"

	"smart-travel-backend/config"

	_ "github.com/go-sql-driver/mysql"
)

var DB *sql.DB

func InitDB() error {
	cfg := config.AppConfig
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		cfg.DBUser,
		cfg.DBPassword,
		cfg.DBHost,
		cfg.DBPort,
		cfg.DBName,
	)

	var err error
	DB, err = sql.Open("mysql", dsn)
	if err != nil {
		DB = nil
		return fmt.Errorf("打开数据库连接失败: %w", err)
	}

	if err = DB.Ping(); err != nil {
		DB = nil
		return fmt.Errorf("数据库连接失败: %w", err)
	}

	DB.SetMaxOpenConns(25)
	DB.SetMaxIdleConns(5)

	log.Println("MySQL 数据库连接成功")
	return nil
}

func CloseDB() {
	if DB != nil {
		DB.Close()
	}
}
