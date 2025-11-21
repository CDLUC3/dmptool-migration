MODEL (
  name migration.metadata_standards,
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
  m.title AS name,
  m.uri,
  m.description,
  (SELECT id FROM default_super_admin) AS createdById,
  m.created_at AS created,
  (SELECT id FROM default_super_admin) AS modifiedById,
  m.updated_at AS modified
FROM {{ var('source_db') }}.metadata_standards AS m
INNER JOIN (
  -- We have duplicate URIs :/
  -- Find the maximum (most recent) updated_at time for every unique uri
  SELECT
    uri,
    MAX(updated_at) AS max_updated_at
  FROM {{ var('source_db') }}.metadata_standards
  GROUP BY uri
) AS latest_m ON m.uri = latest_m.uri AND m.updated_at = latest_m.max_updated_at
ORDER BY m.created_at;

JINJA_END;
