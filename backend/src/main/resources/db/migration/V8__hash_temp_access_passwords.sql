ALTER TABLE temp_file_access
    ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255);

UPDATE temp_file_access SET password = NULL WHERE password IS NOT NULL;

ALTER TABLE temp_file_access DROP COLUMN IF EXISTS password;


ALTER TABLE user_sessions ADD COLUMN token_hash VARCHAR(64);

UPDATE user_sessions
SET token_hash = encode(sha256(token::bytea), 'hex');

ALTER TABLE user_sessions ALTER COLUMN token_hash SET NOT NULL;

ALTER TABLE user_sessions DROP CONSTRAINT user_sessions_pkey;
ALTER TABLE user_sessions DROP COLUMN token;

ALTER TABLE user_sessions ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (token_hash);

CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_expires_at ON user_sessions(expires_at);