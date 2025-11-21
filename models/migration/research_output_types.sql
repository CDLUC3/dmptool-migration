MODEL (
  name migration.research_output_types,
  kind FULL,
  columns (
    name VARCHAR(255) COLLATE utf8mb4_0900_ai_ci NOT NULL,
    value VARCHAR(255) COLLATE utf8mb4_0900_ai_ci NOT NULL,
    description VARCHAR(255) COLLATE utf8mb4_0900_ai_ci NOT NULL,
    createdById INT UNSIGNED NOT NULL,
    created DATETIME NOT NULL,
    modifiedById INT UNSIGNED NOT NULL,
    modified DATETIME NOT NULL
  ),
  audits (
    unique_values(columns := (name, value), blocking := false)
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
  TRIM(rot.name) AS name,
  TRIM(rot.value) AS value,
  TRIM(rot.description) AS description,
  (SELECT id FROM default_super_admin) AS createdById,
  CURRENT_DATE() AS created,
  (SELECT id FROM default_super_admin) AS modifiedById,
  CURRENT_DATE() AS modified
FROM intermediate.research_output_types AS rot;
