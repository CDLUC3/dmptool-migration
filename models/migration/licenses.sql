MODEL (
  name migration.licenses,
  kind FULL,
  columns (
    name VARCHAR(255) NOT NULL,
    uri VARCHAR(255) NOT NULL,
    description TEXT,
    createdById INT UNSIGNED NOT NULL,
    created TIMESTAMP NOT NULL,
    modifiedById INT UNSIGNED NOT NULL,
    modified TIMESTAMP NOT NULL
  ),
  enabled true
);

JINJA_QUERY_BEGIN;

WITH default_super_admin AS (
  SELECT id
  FROM intermediate.users
  WHERE role = 'SUPERADMIN'
  ORDER BY id DESC LIMIT 1
)

SELECT DISTINCT
  l.identifier AS name,
  l.uri,
  l.name AS description,
  (SELECT id FROM default_super_admin) AS createdById,
  l.created_at AS created,
  (SELECT id FROM default_super_admin) AS modifiedById,
  l.updated_at AS modified
FROM {{ var('source_db') }}.licenses AS l
WHERE l.deprecated = 0;

JINJA_END;
