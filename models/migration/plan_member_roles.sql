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
    ROW_NUMBER() OVER (ORDER BY pm.id ASC) AS id,
    pm.id AS planMemberId,
    (SELECT id FROM default_member_role) AS memberRoleId,
    pm.createdById,
    pm.created,
    pm.modifiedById,
    pm.modified
FROM migration.plan_members pm;