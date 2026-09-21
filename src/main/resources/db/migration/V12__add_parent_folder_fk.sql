UPDATE folders
SET parent_folder_id = NULL
WHERE parent_folder_id IS NOT NULL
  AND parent_folder_id NOT IN (SELECT id FROM folders);


ALTER TABLE folders
    ADD CONSTRAINT fk_folders_parent
    FOREIGN KEY (parent_folder_id)
    REFERENCES folders(id)
    ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_folders_parent_folder_id ON folders(parent_folder_id);