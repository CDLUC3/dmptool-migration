MODEL (
  name migration.member_roles,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    label VARCHAR(255) COLLATE utf8mb4_0900_ai_ci NOT NULL,
    uri VARCHAR(255) COLLATE utf8mb4_0900_ai_ci NOT NULL,
    description VARCHAR(255) COLLATE utf8mb4_0900_ai_ci NOT NULL,
    displayOrder INT NOT NULL,
    isDefault TINYINT(1) NOT NULL DEFAULT 0,
    createdById INT UNSIGNED NOT NULL,
    created TIMESTAMP NOT NULL,
    modifiedById INT UNSIGNED NOT NULL,
    modified TIMESTAMP NOT NULL
  ),
  audits (
    unique_values(columns := (uri, label), blocking := false)
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
  TRIM(mr.label) AS label,
  TRIM(mr.uri) AS uri,
  TRIM(mr.description) AS description,
  mr.display_order AS displayOrder,
  mr.is_default AS isDefault,
  (SELECT id FROM default_super_admin) AS createdById,
  CURRENT_DATE() AS created,
  (SELECT id FROM default_super_admin) AS modifiedById,
  CURRENT_DATE() AS modified
FROM intermediate.member_roles AS mr;