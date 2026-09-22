ALTER TABLE folder_passwords ALTER COLUMN algorithm DROP DEFAULT;
COMMENT ON COLUMN folder_passwords.algorithm IS 'Алгоритм хэширования пароля (BCRYPT, LEGACY-SHA256)';