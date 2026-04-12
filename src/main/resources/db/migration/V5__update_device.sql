DROP INDEX idx_unique_id_identifier;

CREATE UNIQUE INDEX idx_unique_id_per_user ON devices(user_id, unique_id);