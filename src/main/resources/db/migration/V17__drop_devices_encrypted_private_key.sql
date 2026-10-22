ALTER TABLE devices DROP COLUMN IF EXISTS encrypted_private_key;

COMMENT ON COLUMN devices.public_key IS
    'Public key of the device (used for device pairing / E2E key transfer).';