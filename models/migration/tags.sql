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
    id INT UNSIGNED PRIMARY KEY,
    slug VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created TIMESTAMP NOT NULL,
    createdById INT,
    modified TIMESTAMP NOT NULL,
    modifiedById INT
  ),
  audits (
    -- assert_row_count(source_db_table:='themes', blocking := false),
    unique_values(columns := (slug)),
    not_null(columns := (slug, name, created, createdById, modified, modifiedById))
  ),
  enabled true
);

WITH default_super_admin AS (
  SELECT id
  FROM intermediate.users
  WHERE role = 'SUPERADMIN'
  ORDER BY id DESC LIMIT 1
)

SELECT
  ROW_NUMBER() OVER () AS id,
  LOWER(REPLACE(t.title, ' ', '-')) AS slug,
  TRIM(t.title) AS name,
  TRIM(t.description) AS description,
  t.created_at AS created,
  (SELECT id FROM default_super_admin) AS createdById,
  t.updated_at AS modified,
  (SELECT id FROM default_super_admin) AS modifiedById
FROM source_db.themes AS t;
