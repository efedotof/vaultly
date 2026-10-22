ALTER TABLE users DROP COLUMN IF EXISTS recovery_private_key_encrypted;
ALTER TABLE users DROP COLUMN IF EXISTS recovery_salt;

COMMENT ON COLUMN users.recovery_public_key IS
    'Recovery RSA public key. Used only to verify /recover signatures.';
COMMENT ON COLUMN users.recovery_encrypted_rsa_key IS
    'Main RSA private key, RSA-OAEP encrypted with recovery_public_key. '
    'Server can never decrypt this; only the client holding recovery_private_key can.';