ALTER TABLE users ADD COLUMN IF NOT EXISTS salt VARCHAR(255);

COMMENT ON COLUMN users.salt IS 'Соль для шифрования приватного ключа пользователя паролем';