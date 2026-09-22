ALTER TABLE users ALTER COLUMN totp_secret TYPE TEXT;
COMMENT ON COLUMN users.totp_secret IS 'TOTP секрет, зашифрованный мастер-ключом сервера';