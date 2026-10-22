CREATE TABLE IF NOT EXISTS device_pairings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    initiator_public_key TEXT NOT NULL,
    initiator_algorithm VARCHAR(32) NOT NULL DEFAULT 'X25519',

    responder_public_key TEXT,
    responder_algorithm VARCHAR(32),

    blob_ciphertext TEXT,
    blob_nonce TEXT,
    blob_algorithm VARCHAR(64),
    blob_created_at TIMESTAMPTZ,

    expires_at TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_device_pairings_user
    ON device_pairings(user_id);
CREATE INDEX IF NOT EXISTS idx_device_pairings_expires
    ON device_pairings(expires_at) WHERE consumed_at IS NULL;

COMMENT ON TABLE device_pairings IS
    'Ephemeral E2E key transfer between two devices of the same user. '
    'Server relays ephemeral public keys and E2E ciphertext only; '
    'never sees plaintext private key.';