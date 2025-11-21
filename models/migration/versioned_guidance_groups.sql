MODEL (
  name migration.versioned_guidance_groups,
  kind FULL,
  columns (
    id INT UNSIGNED PRIMARY KEY,
    old_group_id INT UNSIGNED NOT NULL,
    guidanceGroupId INT UNSIGNED UNIQUE,
    version varchar(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    active Boolean NOT NULL DEFAULT false,
    bestPractice Boolean NOT NULL DEFAULT false,
    optionalSubset Boolean NOT NULL DEFAULT false,
    created DATETIME NOT NULL,
    createdById INT,
    modified DATETIME NOT NULL,
    modifiedById INT
  ),
  enabled true
);

JINJA_QUERY_BEGIN;

SELECT
  ROW_NUMBER() OVER (ORDER BY gg.created ASC) AS id,
  gg.old_group_id AS old_group_id,
  gg.id AS guidanceGroupId,
  gg.latestPublishedVersion AS version,
  gg.name,
  1 AS active,
  gg.bestPractice,
  gg.optionalSubset,
  gg.created,
  gg.createdById,
  gg.modified,
  gg.modifiedById
FROM migration.guidance_groups AS gg
WHERE gg.latestPublishedVersion IS NOT NULL
ORDER BY gg.created ASC;

JINJA_END;