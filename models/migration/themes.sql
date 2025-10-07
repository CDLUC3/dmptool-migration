--   Target schema (table `tags`):
--  `id` int NOT NULL AUTO_INCREMENT,
--  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `description` mediumtext COLLATE utf8mb4_unicode_ci,
--  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `createdById` int DEFAULT NULL,
--  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `modifiedById` int DEFAULT NULL,

MODEL (
  name migration.themes,
  kind FULL,
  columns (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
  ),
  audits (
    assert_row_count(dmp_table:='themes', blocking := false),
  ),
  enabled true
);

SELECT
  dmp.themes.title,
  dmp.themes.description,
  dmp.themes.created_at,
  dmp.themes.updated_at
FROM dmp.themes;
