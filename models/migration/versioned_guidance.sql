MODEL (
  name migration.versioned_guidance,
  kind FULL,
  columns (
    id INT UNSIGNED PRIMARY KEY,
    old_group_id INT UNSIGNED NOT NULL,
    old_guidance_id INT UNSIGNED NOT NULL,
    versionedGuidanceGroupId int unsigned NOT NULL,
    guidanceId int unsigned NOT NULL,
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
  ROW_NUMBER() OVER (ORDER BY g.created ASC) AS id,
  g.old_group_id,
  g.old_guidance_id,
  g.id AS guidanceId,
  gg.id AS versionedGuidanceGroupId,
  g.guidanceText AS guidanceText,
  gg.createdById,
  gg.created,
  gg.modifiedById,
  gg.modified
FROM migration.guidance AS g
  JOIN migration.versioned_guidance_groups AS gg ON g.old_group_id = gg.old_group_id
ORDER BY g.created ASC;

JINJA_END;