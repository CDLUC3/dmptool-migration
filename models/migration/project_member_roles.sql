MODEL (
  name migration.project_member_roles,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    projectMemberId INT UNSIGNED NOT NULL,
    memberRoleId INT UNSIGNED NOT NULL,
    createdById INT UNSIGNED NOT NULL,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifiedById INT UNSIGNED NOT NULL,
    modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ),
  enabled true
);

WITH default_member_role AS (
  SELECT id
  FROM migration.member_roles
  WHERE isDefault = 1
  LIMIT 1
)

WITH default_super_admin AS (
  SELECT id
  FROM intermediate.users
  WHERE role = 'SUPERADMIN'
  ORDER BY id DESC LIMIT 1
)

SELECT
  ROW_NUMBER() OVER (ORDER BY p.id ASC) AS id,
  pm.id AS projectMemberId,
  (SELECT id FROM default_member_role) AS memberRoleId,
  COALESCE(u.id, (SELECT id FROM default_super_admin)) AS createdById,
  p.created_at AS created,
  COALESCE(u.id, (SELECT id FROM default_super_admin)) AS modifiedById,
  p.updated_at AS modified
FROM intermediate.plans p
JOIN intermediate.users u ON p.owner_email = u.email
JOIN migration.project_members pm ON u.email = pm.email AND p.id = pm.old_plan_id;
