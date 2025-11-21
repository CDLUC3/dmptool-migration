MODEL (
  name migration.repositories,
  kind FULL,
  columns (
    name VARCHAR(255) NOT NULL,
    uri VARCHAR(255) NOT NULL,
    description TEXT,
    website VARCHAR(255),
    keywords JSON,
    repositoryTypes JSON,
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
  r.name,
  r.uri,
  r.description,
  r.homepage AS website,
  r.info -> '$.types' AS repositoryTypes,
  r.info -> '$.keywords' AS keywords,
  (SELECT id FROM default_super_admin) AS createdById,
  r.created_at AS created,
  (SELECT id FROM default_super_admin) AS modifiedById,
  r.updated_at AS modified
FROM {{ var('source_db') }}.repositories AS r
INNER JOIN (
  -- We have duplicate URIs :/
  -- Find the maximum (most recent) updated_at time for every unique uri
  SELECT
    uri,
    MAX(updated_at) AS max_updated_at
  FROM {{ var('source_db') }}.repositories
  GROUP BY uri
) AS latest_r ON r.uri = latest_r.uri AND r.updated_at = latest_r.max_updated_at
ORDER BY r.created_at;

JINJA_END;
