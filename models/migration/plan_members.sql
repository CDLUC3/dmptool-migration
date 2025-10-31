MODEL (
  name migration.plan_members,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    planId INT UNSIGNED NOT NULL,
    projectMemberId INT UNSIGNED NOT NULL,
    isPrimaryContact TINYINT(1) NOT NULL,
    createdById INT UNSIGNED NOT NULL,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifiedById INT UNSIGNED NOT NULL,
    modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ),
  enabled true
);

SELECT
  pm.id,
  pm.projectId AS planId,
  pm.id AS projectMemberId,
  pm.isPrimaryContact,
  pm.createdById,
  pm.created,
  pm.modifiedById,
  pm.modified
FROM intermediate.project_members pm;

