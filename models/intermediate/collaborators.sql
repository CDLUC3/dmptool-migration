MODEL (
  name intermediate.collaborators,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    old_plan_id INT UNSIGNED NOT NULL,
    old_user_id INT UNSIGNED NOT NULL,
    email VARCHAR(255) NOT NULL,
    access VARCHAR(8) NOT NULL,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ),
  enabled true
);

JINJA_QUERY_BEGIN;

SELECT
  ROW_NUMBER() OVER (ORDER BY r.id ASC) AS id,
  r.plan_id AS old_plan_id,
  r.user_id AS old_user_id,
  u.email AS email,
  CASE
    WHEN r.access = 8 THEN 'COMMENT'
    WHEN r.access IN (4, 12) THEN 'EDIT'
    ELSE 'OWN'
  END AS access,
  r.created_at AS created,
  r.updated_at AS modified
FROM {{var('source_db')}}.roles r
  JOIN {{var('source_db')}}.users u ON r.user_id = u.id
WHERE r.active = 1 AND r.access < 16; -- Everything above is a reviewer and we don't want those

JINJA_END;
