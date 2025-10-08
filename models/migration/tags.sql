--   Target schema (table `tags`):
--  `id` int NOT NULL AUTO_INCREMENT,
--  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `description` mediumtext COLLATE utf8mb4_unicode_ci,
--  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `createdById` int DEFAULT NULL,
--  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `modifiedById` int DEFAULT NULL,

MODEL (
  name migration.tags,
  kind FULL,
  columns (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    slug VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created TIMESTAMP NOT NULL,
    createdById INT,
    modified TIMESTAMP NOT NULL,
    modifiedById INT
  ),
  audits (
    assert_row_count(dmp_table:='themes', blocking := false),
    unique_values(columns := (slug)),
    not_null(columns := (slug, name, created, createdById, modified, modifiedById))
  ),
  enabled true
);

SELECT
  ROW_NUMBER() OVER (ORDER BY dmp.themes.created_at) AS id,
  LOWER(REPLACE(dmp.themes.title, ' ', '-')) AS slug,
  dmp.themes.title AS name,
  dmp.themes.description,
  dmp.themes.created_at AS created,
  @VAR('super_admin_id') AS createdById,
  dmp.themes.updated_at AS modified,
  @VAR('super_admin_id') AS modifiedById
FROM dmp.themes;
