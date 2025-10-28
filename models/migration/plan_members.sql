MODEL (
  name migration.plan_members,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    planId INT UNSIGNED NOT NULL,
    projectMemberId INT UNSIGNED NOT NULL,
    isPrimaryContact TINYINT(1) NOT NULL DEFAULT 0,
    createdById INT UNSIGNED NOT NULL,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifiedById INT UNSIGNED NOT NULL,
    modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ),
  enabled true
);

SELECT
  ROW_NUMBER() OVER () AS id,
  p.id AS planId,
  pm.id AS projectMemberId,
  pm.isPrimaryContact,
  u.userId AS createdById,
  p.created_at AS created,
  u.userId AS modifiedById,
  p.updated_at AS modified
FROM intermediate.plans p
  INNER JOIN migration.project_members pm ON p.owner_email = pm.email
    INNER JOIN migration.user_emails u on p.owner_email = u.email;
