DROP INDEX idx_unique_id_per_user;

CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_id_identifier ON devices(unique_id);