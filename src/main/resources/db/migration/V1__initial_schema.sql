CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) UNIQUE NOT NULL
);

INSERT INTO roles (role_name) VALUES
('MODERATION'),
('ADMIN'),
('USER')
ON CONFLICT (role_name) DO NOTHING;

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    public_key TEXT,
    private_key_encrypted TEXT,
    avatar_s3_key VARCHAR(500),
    avatar_url VARCHAR(500),
    storage_used BIGINT DEFAULT 0,
    storage_limit BIGINT DEFAULT 1073741824,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    salt VARCHAR(255),
    totp_secret VARCHAR(64),
    totp_enabled BOOLEAN DEFAULT FALSE,
    totp_verified_at TIMESTAMP,
    backup_codes_hash TEXT,
    recovery_public_key TEXT,
    recovery_private_key_encrypted TEXT,
    recovery_salt VARCHAR(255),
    recovery_encrypted_rsa_key TEXT
);

CREATE TABLE IF NOT EXISTS user_sessions (
    token VARCHAR(255) PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE IF NOT EXISTS user_roles (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id INT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE IF NOT EXISTS folders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    path VARCHAR(1000) UNIQUE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parent_folder_id UUID,
    type VARCHAR(50) NOT NULL DEFAULT 'CUSTOM',
    is_hidden BOOLEAN DEFAULT FALSE,
    hidden_folder_key_hash VARCHAR(255),
    is_locked BOOLEAN DEFAULT FALSE,
    allowed_users TEXT,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(500) NOT NULL,
    original_name VARCHAR(500),
    s3_key VARCHAR(1000) NOT NULL UNIQUE,
    s3_url VARCHAR(1000),
    size BIGINT,
    mime_type VARCHAR(100),
    file_hash VARCHAR(255),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    folder_id UUID REFERENCES folders(id) ON DELETE SET NULL,
    is_encrypted BOOLEAN DEFAULT FALSE,
    encryption_key_encrypted TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_note BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS temp_file_access (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token VARCHAR(255) NOT NULL UNIQUE,
    file_id UUID NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    created_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    expires_at TIMESTAMP NOT NULL,
    max_downloads INTEGER,
    downloads_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    password VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS folder_accesses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    folder_id UUID NOT NULL REFERENCES folders(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    access_level VARCHAR(20) NOT NULL,
    can_edit BOOLEAN DEFAULT FALSE,
    can_delete BOOLEAN DEFAULT FALSE,
    can_share BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    granted_by UUID,
    granted_at TIMESTAMP,
    expires_at TIMESTAMP,
    access_key_hash VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS folder_passwords (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    folder_id UUID NOT NULL REFERENCES folders(id) ON DELETE CASCADE,
    password_hash VARCHAR(255) NOT NULL,
    salt VARCHAR(255) NOT NULL,
    algorithm VARCHAR(50) DEFAULT 'SHA-256',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    last_used TIMESTAMP
);

CREATE TABLE IF NOT EXISTS devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_name VARCHAR(255) NOT NULL,
    device_type VARCHAR(50),
    public_key TEXT,
    encrypted_private_key TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    unique_id VARCHAR(255) NOT NULL                   
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_folders_user_id ON folders(user_id);
CREATE INDEX idx_folders_parent_id ON folders(parent_folder_id);
CREATE INDEX idx_folders_path ON folders(path);
CREATE INDEX idx_files_user_id ON files(user_id);
CREATE INDEX idx_files_folder_id ON files(folder_id);
CREATE INDEX idx_files_s3_key ON files(s3_key);
CREATE INDEX idx_files_is_deleted ON files(is_deleted);
CREATE INDEX idx_temp_access_token ON temp_file_access(token);
CREATE INDEX idx_temp_access_expires ON temp_file_access(expires_at);
CREATE INDEX idx_temp_access_file_id ON temp_file_access(file_id);
CREATE INDEX idx_devices_user_id ON devices(user_id);
CREATE INDEX idx_devices_is_active ON devices(is_active);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_folders_updated_at
    BEFORE UPDATE ON folders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_files_updated_at
    BEFORE UPDATE ON files
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE FUNCTION check_storage_limit()
RETURNS TRIGGER AS $$
DECLARE
    user_storage_used BIGINT;
    user_storage_limit BIGINT;
BEGIN
    SELECT storage_used, storage_limit 
    INTO user_storage_used, user_storage_limit
    FROM users 
    WHERE id = NEW.user_id;
    
    IF (user_storage_used + NEW.size) > user_storage_limit THEN
        RAISE EXCEPTION 'Storage limit exceeded for user %', NEW.user_id;
    END IF;
    
    UPDATE users 
    SET storage_used = storage_used + NEW.size
    WHERE id = NEW.user_id;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER check_storage_on_file_insert
    BEFORE INSERT ON files
    FOR EACH ROW
    EXECUTE FUNCTION check_storage_limit();

CREATE OR REPLACE FUNCTION update_storage_on_delete()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE users 
    SET storage_used = storage_used - OLD.size
    WHERE id = OLD.user_id AND storage_used >= OLD.size;
    
    RETURN OLD;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_storage_on_file_delete
    AFTER DELETE ON files
    FOR EACH ROW
    EXECUTE FUNCTION update_storage_on_delete();

COMMENT ON TABLE users IS 'Пользователи системы облачного хранилища';
COMMENT ON TABLE folders IS 'Папки пользователей, включая системные папки';
COMMENT ON TABLE files IS 'Файлы пользователей с метаданными';
COMMENT ON TABLE temp_file_access IS 'Временные ссылки для доступа к файлам';
COMMENT ON TABLE devices IS 'Устройства пользователей для синхронизации приватных ключей';
COMMENT ON COLUMN folders.type IS 'Тип папки: DEFAULT, SYSTEM_RECENTLY_DELETED, SYSTEM_TEMP_LINKS, SYSTEM_ROOT, SYSTEM_HIDDEN, CUSTOM';
COMMENT ON COLUMN devices.public_key IS 'Публичный ключ устройства (для шифрования приватного ключа пользователя)';
COMMENT ON COLUMN devices.encrypted_private_key IS 'Приватный ключ пользователя, зашифрованный публичным ключом устройства';
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_id_identifier ON devices(unique_id);
CREATE INDEX idx_users_public_key ON users(public_key);
COMMENT ON COLUMN users.salt IS 'Соль для шифрования приватного ключа пользователя паролем';