MODEL (
  name migration.draft_plan_member_roles,
  kind FULL,
  columns (
    planMemberId INT UNSIGNED NOT NULL,
    memberRoleId INT UNSIGNED NOT NULL,
    createdById INT UNSIGNED NOT NULL,
    created DATETIME NOT NULL DEFAULT CURRENT_DATE,
    modifiedById INT UNSIGNED NOT NULL,
    modified DATETIME NOT NULL DEFAULT CURRENT_DATE,
  ),
  enabled true
);

SELECT
  pm.id AS planMemberId,
  pmr.memberRoleId,
  pm.createdById,
  pm.created,
  pm.modifiedById,
  pm.modified
FROM migration.draft_plan_members pm
  LEFT JOIN migration.draft_project_members pjm ON pm.projectMemberId = pjm.id
    LEFT JOIN migration.draft_project_member_roles pmr ON pjm.id = pmr.projectMemberid;
