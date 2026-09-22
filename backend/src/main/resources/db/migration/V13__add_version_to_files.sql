ALTER TABLE files ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;
COMMENT ON COLUMN files.version IS 'Optimistic lock version (@Version)';