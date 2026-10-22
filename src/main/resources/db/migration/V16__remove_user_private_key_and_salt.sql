ALTER TABLE users DROP COLUMN IF EXISTS private_key_encrypted;
ALTER TABLE users DROP COLUMN IF EXISTS salt;

COMMENT ON COLUMN users.public_key IS
    'RSA public key (PEM). Private key never leaves the user device.';