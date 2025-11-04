MODEL (
  name migration.project_collaborators,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    old_plan_id INT UNSIGNED NOT NULL,
    projectId INT UNSIGNED NOT NULL,
    email VARCHAR(255) NOT NULL,
    invitedById INT UNSIGNED NOT NULL,
    userId INT UNSIGNED,
    accessLevel VARCHAR(8) NOT NULL,
    createdById INT UNSIGNED NOT NULL,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifiedById INT UNSIGNED NOT NULL,
    modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ),
  enabled true
);

SELECT
  ROW_NUMBER() OVER () AS id,
  c.old_plan_id AS old_plan_id,
  mp.id AS projectId,
  c.email AS email,
  MAX(mp.createdById) AS invitedById,
  ue.userId,
  MAX(c.access) as accessLevel,
  MAX(mp.createdByid) AS createdById,
  MAX(mp.created) AS created,
  MAX(mp.modifiedById) AS modifiedById,
  MAX(mp.modified) AS modified
FROM intermediate.collaborators c
  LEFT JOIN migration.projects mp ON c.old_plan_id = mp.old_plan_id
  JOIN migration.user_emails ue ON c.email = ue.email
GROUP BY c.old_plan_id, c.email, mp.id, ue.userId;
