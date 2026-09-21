DROP TRIGGER IF EXISTS check_storage_on_file_insert ON files;
DROP TRIGGER IF EXISTS update_storage_on_file_delete ON files;
DROP FUNCTION IF EXISTS check_storage_limit();
DROP FUNCTION IF EXISTS update_storage_on_delete();


CREATE OR REPLACE FUNCTION files_sync_user_storage()
RETURNS TRIGGER AS $$
DECLARE
    delta BIGINT := 0;
    target_user UUID;
    cur_used BIGINT;
    max_limit BIGINT;
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.is_deleted = FALSE THEN
            delta := NEW.size;
            target_user := NEW.user_id;
        END IF;

    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.is_deleted = FALSE THEN
            delta := -OLD.size;
            target_user := OLD.user_id;
        END IF;

    ELSIF TG_OP = 'UPDATE' THEN

        IF OLD.user_id <> NEW.user_id THEN
            IF OLD.is_deleted = FALSE THEN
                UPDATE users SET storage_used = GREATEST(0, storage_used - OLD.size)
                WHERE id = OLD.user_id;
            END IF;
            IF NEW.is_deleted = FALSE THEN
                UPDATE users SET storage_used = storage_used + NEW.size
                WHERE id = NEW.user_id;
            END IF;
            RETURN NEW;
        END IF;


        IF OLD.is_deleted = FALSE AND NEW.is_deleted = TRUE THEN
            delta := -NEW.size;
            target_user := NEW.user_id;

        ELSIF OLD.is_deleted = TRUE AND NEW.is_deleted = FALSE THEN
            delta := NEW.size;
            target_user := NEW.user_id;
        END IF;
    END IF;

    IF delta <> 0 AND target_user IS NOT NULL THEN

        IF delta > 0 THEN
            SELECT storage_used, storage_limit INTO cur_used, max_limit
            FROM users WHERE id = target_user;

            IF cur_used + delta > max_limit THEN
                RAISE EXCEPTION 'Storage limit exceeded for user % (used=%, limit=%, add=%)',
                    target_user, cur_used, max_limit, delta;
            END IF;
        END IF;

        UPDATE users
        SET storage_used = GREATEST(0, storage_used + delta)
        WHERE id = target_user;
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER files_storage_sync
AFTER INSERT OR UPDATE OR DELETE ON files
FOR EACH ROW
EXECUTE FUNCTION files_sync_user_storage();


UPDATE users u
SET storage_used = COALESCE((
    SELECT SUM(f.size)
    FROM files f
    WHERE f.user_id = u.id AND f.is_deleted = FALSE
), 0);