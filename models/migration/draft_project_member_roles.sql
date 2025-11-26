MODEL (
  name migration.draft_project_member_roles,
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
  COALESCE(mr.id, 15) AS memberRoleId,
  pm.createdById,
  pm.created,
  pm.modifiedById,
  pm.modified
FROM migration.draft_project_members pm
  LEFT JOIN intermediate.pilot_draft_members pdm ON pm.id = pdm.id
    LEFT JOIN migration.member_roles mr ON pdm.role = mr.uri;
