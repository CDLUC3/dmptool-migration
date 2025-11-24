MODEL (
  name migration.project_member_roles,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    projectMemberId INT UNSIGNED NOT NULL,
    memberRoleId INT UNSIGNED NOT NULL,
    createdById INT UNSIGNED NOT NULL,
    created DATETIME NOT NULL DEFAULT CURRENT_DATE,
    modifiedById INT UNSIGNED NOT NULL,
    modified DATETIME NOT NULL DEFAULT CURRENT_DATE,
  ),
  enabled true
);

SELECT
  ROW_NUMBER() OVER () AS id,
  pm.id AS projectMemberId,
  COALESCE(rm.new_id, 15) AS memberRoleId,
  pm.createdById,
  pm.created,
  pm.modifiedById,
  pm.modified
FROM migration.final_project_members pm
  LEFT JOIN seeds.role_mappings rm ON pm.roles = rm.old_id;