MODEL (
  name migration.guidance_groups,
  kind FULL,
  columns (
    id INT UNSIGNED PRIMARY KEY,
    old_group_id INT UNSIGNED NOT NULL,
    affiliationId varchar(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    isDirty Boolean NOT NULL DEFAULT true,
    bestPractice Boolean NOT NULL DEFAULT false,
    optionalSubset Boolean NOT NULL DEFAULT false,
    latestPublishedVersion text,
    latestPublishedDate timestamp NULL DEFAULT NULL,
    created DATETIME NOT NULL,
    createdById INT,
    modified DATETIME NOT NULL,
    modifiedById INT
  ),
  enabled true
);

JINJA_QUERY_BEGIN;

WITH default_super_admin AS (
  SELECT id
  FROM intermediate.users
  WHERE role = 'SUPERADMIN'
  ORDER BY id DESC LIMIT 1
),

admins AS (
  SELECT MAX(id) AS admin_id, affiliationId
  FROM migration.users
  WHERE role = 'ADMIN'
  GROUP BY affiliationId
)

SELECT
  ROW_NUMBER() OVER (ORDER BY gg.created_at ASC) AS id,
  gg.id AS old_group_id,
  TRIM(gg.name) AS name,
  CASE WHEN gg.id = 256 THEN true ELSE false END AS bestPractice,
  gg.optional_subset AS optionalSubset,
  CASE WHEN gg.published = 1 THEN 'v1' ELSE NULL END AS latestPublishedVersion,
  CASE WHEN gg.published = 1 THEN gg.updated_at ELSE NULL END AS latestPublishedDate,
  (gg.published = 0) AS isDirty,
  CASE
    WHEN gg.org_id IS NULL THEN NULL
    WHEN ro.id IS NULL THEN CONCAT('https://dmptool.org/affiliations/', gg.org_id)
    ELSE ro.ror_id
  END AS affiliationId,
  COALESCE(admins.admin_id, (SELECT id FROM default_super_admin)) AS createdById,
  gg.created_at AS created,
  COALESCE(admins.admin_id, (SELECT id FROM default_super_admin)) AS modifiedById,
  gg.updated_at AS modified
FROM {{ var('source_db') }}.guidance_groups AS gg
  LEFT JOIN {{ var('source_db') }}.registry_orgs AS ro ON gg.org_id = ro.org_id
    LEFT JOIN admins ON ro.ror_id = admins.affiliationId
ORDER BY gg.created_at ASC;

JINJA_END;