MODEL (
  name migration.plan_member_roles,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    planMemberId INT UNSIGNED NOT NULL,
    memberRoleId INT UNSIGNED NOT NULL,
    createdById INT UNSIGNED NOT NULL,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifiedById INT UNSIGNED NOT NULL,
    modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ),
  enabled true
);

SELECT
  ROW_NUMBER() OVER () AS id,
  pm.id AS planMemberId,
  CASE
    WHEN pm.memberRoleId IS NOT NULL THEN pm.memberRoleId
    ELSE rm.new_id
  END
  AS memberRoleId,
  pm.createdById,
  pm.created,
  pm.modifiedById,
  pm.modified
FROM intermediate.project_members pm
LEFT JOIN seeds.role_mappings rm ON pm.oldRoleId = rm.old_id