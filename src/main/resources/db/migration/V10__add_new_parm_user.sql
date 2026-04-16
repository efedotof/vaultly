ALTER TABLE users ADD COLUMN recovery_public_key TEXT;
ALTER TABLE users ADD COLUMN recovery_private_key_encrypted TEXT;
ALTER TABLE users ADD COLUMN recovery_salt VARCHAR(255);