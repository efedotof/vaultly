DO $$
DECLARE
    orphan_count INT;
BEGIN
    SELECT COUNT(*) INTO orphan_count
    FROM files
    WHERE file_content_id IS NULL
      AND is_deleted = FALSE;

    IF orphan_count > 0 THEN
        RAISE WARNING
            'V15: found % active files with NULL file_content_id. '
            'Manual data review required.', orphan_count;
    ELSE
        RAISE NOTICE 'V15: no orphan files found';
    END IF;
END $$;