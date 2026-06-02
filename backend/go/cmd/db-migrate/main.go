package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"smart-travel-backend/config"
	"smart-travel-backend/database"
)

func main() {
	config.LoadConfig()
	if err := database.InitDB(); err != nil {
		log.Fatalf("数据库连接失败: %v", err)
	}
	defer database.CloseDB()

	migrationsDir := os.Getenv("MIGRATIONS_DIR")
	if migrationsDir == "" {
		migrationsDir = "../migrations"
	}
	if _, err := os.Stat(migrationsDir); err != nil {
		migrationsDir = "backend/migrations"
	}

	files, err := filepath.Glob(filepath.Join(migrationsDir, "*.sql"))
	if err != nil {
		log.Fatalf("读取迁移目录失败: %v", err)
	}
	sort.Strings(files)
	if len(files) == 0 {
		log.Printf("没有找到迁移文件: %s", migrationsDir)
		return
	}

	for _, file := range files {
		if err := runMigration(file); err != nil {
			log.Fatalf("迁移失败 %s: %v", file, err)
		}
		log.Printf("迁移完成: %s", filepath.Base(file))
	}
}

func runMigration(file string) error {
	content, err := os.ReadFile(file)
	if err != nil {
		return err
	}

	for _, statement := range splitSQL(string(content)) {
		if _, err := database.DB.Exec(statement); err != nil {
			if isDuplicateColumnError(err) {
				log.Printf("跳过已存在字段: %s", shortStatement(statement))
				continue
			}
			return fmt.Errorf("%w; SQL: %s", err, shortStatement(statement))
		}
	}
	return nil
}

func splitSQL(sql string) []string {
	parts := strings.Split(sql, ";")
	statements := make([]string, 0, len(parts))
	for _, part := range parts {
		statement := strings.TrimSpace(part)
		if statement == "" {
			continue
		}
		statements = append(statements, statement)
	}
	return statements
}

func isDuplicateColumnError(err error) bool {
	message := strings.ToLower(err.Error())
	return strings.Contains(message, "duplicate column") || strings.Contains(message, "error 1060")
}

func shortStatement(statement string) string {
	statement = strings.Join(strings.Fields(statement), " ")
	if len(statement) <= 120 {
		return statement
	}
	return statement[:120] + "..."
}
