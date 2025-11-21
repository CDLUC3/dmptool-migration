MODEL (
  name migration.guidance,
  kind FULL,
  columns (
    id INT UNSIGNED PRIMARY KEY,
    old_group_id INT UNSIGNED NOT NULL,
    old_guidance_id INT UNSIGNED NOT NULL,
    guidanceGroupId int unsigned NOT NULL,
    guidanceText text,
    created DATETIME NOT NULL,
    createdById INT,
    modified DATETIME NOT NULL,
    modifiedById INT
  ),
  enabled true
);

JINJA_QUERY_BEGIN;

SELECT
  ROW_NUMBER() OVER (ORDER BY g.created_at ASC) AS id,
  g.guidance_group_id AS old_group_id,
  g.id AS old_guidance_id,
  gg.id AS guidanceGroupId,
  g.text AS guidanceText,
  gg.createdById,
  gg.created,
  gg.modifiedById,
  gg.modified
FROM {{ var('source_db') }}.guidances AS g
  JOIN migration.guidance_groups AS gg ON g.guidance_group_id = gg.old_group_id
ORDER BY g.created_at ASC;

JINJA_END;