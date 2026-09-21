CREATE TABLE IF NOT EXISTS file_contents (
    id UUID PRIMARY KEY,
    hash VARCHAR(64) NOT NULL,
    s3_key VARCHAR(255) NOT NULL UNIQUE,
    s3_url VARCHAR(512),
    size BIGINT NOT NULL,
    mime_type VARCHAR(255),
    is_public BOOLEAN NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='files' AND column_name='file_content_id') THEN
        ALTER TABLE files ADD COLUMN file_content_id UUID REFERENCES file_contents(id);
    END IF;
END $$;