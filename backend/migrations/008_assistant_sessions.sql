USE smart_travel;

CREATE TABLE IF NOT EXISTS assistant_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(100) NOT NULL DEFAULT 'default',
    raw_text TEXT DEFAULT NULL,
    parsed_destination VARCHAR(200) DEFAULT NULL,
    start_station VARCHAR(200) DEFAULT NULL,
    start_entrance VARCHAR(200) DEFAULT NULL,
    end_station VARCHAR(200) DEFAULT NULL,
    end_exit VARCHAR(200) DEFAULT NULL,
    source VARCHAR(100) NOT NULL DEFAULT 'voice-assistant',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_assistant_user_created (user_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO schema_migrations (version, description)
VALUES ('008', 'Add AI assistant planning session log');
