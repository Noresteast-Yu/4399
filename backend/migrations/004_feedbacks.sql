USE smart_travel;

-- 业务代码已经使用该表。将表结构纳入正式迁移，避免依赖接口运行时建表。
CREATE TABLE IF NOT EXISTS feedbacks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    contact VARCHAR(255) DEFAULT NULL,
    status ENUM('pending', 'processing', 'resolved', 'closed') NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_feedback_status_created (status, created_at),
    INDEX idx_feedback_type (type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 兼容此前由接口运行时创建的旧版 feedbacks 表。
-- 现有迁移器会逐条跳过字段已存在错误。
ALTER TABLE feedbacks
    ADD COLUMN status ENUM('pending', 'processing', 'resolved', 'closed')
        NOT NULL DEFAULT 'pending' AFTER contact;

ALTER TABLE feedbacks
    ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP AFTER created_at;

-- 旧表可能由接口自动创建且没有索引；通过 information_schema 条件补齐。
SET @feedback_status_index_sql = (
    SELECT IF(
        EXISTS (
            SELECT 1
            FROM information_schema.statistics
            WHERE table_schema = DATABASE()
              AND table_name = 'feedbacks'
              AND index_name = 'idx_feedback_status_created'
        ),
        'SELECT 1',
        'CREATE INDEX idx_feedback_status_created ON feedbacks (status, created_at)'
    )
);
PREPARE feedback_status_index_stmt FROM @feedback_status_index_sql;
EXECUTE feedback_status_index_stmt;
DEALLOCATE PREPARE feedback_status_index_stmt;

SET @feedback_type_index_sql = (
    SELECT IF(
        EXISTS (
            SELECT 1
            FROM information_schema.statistics
            WHERE table_schema = DATABASE()
              AND table_name = 'feedbacks'
              AND index_name = 'idx_feedback_type'
        ),
        'SELECT 1',
        'CREATE INDEX idx_feedback_type ON feedbacks (type)'
    )
);
PREPARE feedback_type_index_stmt FROM @feedback_type_index_sql;
EXECUTE feedback_type_index_stmt;
DEALLOCATE PREPARE feedback_type_index_stmt;

INSERT IGNORE INTO schema_migrations (version, description)
VALUES ('004', 'Create feedback storage');
