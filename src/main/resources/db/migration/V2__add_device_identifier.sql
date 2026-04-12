ALTER TABLE devices ADD COLUMN IF NOT EXISTS unique_id VARCHAR(255) NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_id_identifier ON devices(unique_id);