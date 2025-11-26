MODEL (
  name migration.draft_project_collaborators,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    old_draft_id INT UNSIGNED NOT NULL,
    projectId INT UNSIGNED NOT NULL,
    email VARCHAR(255) NOT NULL,
    invitedById INT UNSIGNED NOT NULL,
    userId INT UNSIGNED,
    accessLevel VARCHAR(8) NOT NULL,
    createdById INT UNSIGNED NOT NULL,
    created DATETIME NOT NULL DEFAULT CURRENT_DATE,
    modifiedById INT UNSIGNED NOT NULL,
    modified DATETIME NOT NULL DEFAULT CURRENT_DATE,
  ),
  enabled true
);

SELECT
  ROW_NUMBER() OVER () AS id,
  dp.old_draft_id,
  dp.id AS projectId,
  TRIM(u.email) AS email,
  MAX(dp.createdById) AS invitedById,
  u.userId,
  'OWN' as accessLevel,
  MAX(dp.createdByid) AS createdById,
  MAX(dp.created) AS created,
  MAX(dp.modifiedById) AS modifiedById,
  MAX(dp.modified) AS modified
FROM migration.draft_projects AS dp
  JOIN migration.user_emails AS u ON dp.createdById = u.userId
GROUP BY dp.old_draft_id, u.email, dp.id, u.userId;
