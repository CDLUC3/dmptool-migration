MODEL (
  name migration.guidance_tags,
  kind FULL,
  columns (
    id INT UNSIGNED PRIMARY KEY,
    guidanceId int unsigned NOT NULL,
    tagId int unsigned NOT NULL,
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
  g.id AS guidanceId,
  t.id AS tagId,
  g.createdById,
  g.created,
  g.modifiedById,
  g.modified
FROM migration.guidance AS g
  JOIN {{ var('source_db') }}.themes_in_guidance AS gt ON g.old_guidance_id = gt.guidance_id
      JOIN {{ var('source_db') }}.themes AS th ON gt.theme_id = th.id
        JOIN migration.tags AS t ON REPLACE(LOWER(TRIM(th.title)), ' ', '-') = t.slug
ORDER BY g.created ASC;

JINJA_END;