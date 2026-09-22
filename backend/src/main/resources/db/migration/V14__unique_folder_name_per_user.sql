CREATE UNIQUE INDEX IF NOT EXISTS idx_folders_user_parent_name
    ON folders (
        user_id,
        COALESCE(parent_folder_id, '00000000-0000-0000-0000-000000000000'::uuid),
        name
    )
    WHERE is_deleted = FALSE;

CREATE INDEX IF NOT EXISTS idx_files_file_content_id ON files(file_content_id);