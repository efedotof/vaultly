COMMENT ON COLUMN file_contents.s3_key IS 'S3 object key (not full URL)';
CREATE INDEX IF NOT EXISTS idx_file_contents_s3_key ON file_contents(s3_key);