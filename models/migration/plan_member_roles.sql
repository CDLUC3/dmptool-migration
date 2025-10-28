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

SELECT
  ROW_NUMBER() OVER () AS id,
  u.id AS planMemberId,
  (SELECT id FROM default_member_role) AS memberRoleId,
  u.id AS createdById,
  p.created_at AS created,
  u.id AS modifiedById,
  p.updated_at AS modified
FROM intermediate.plans p
INNER JOIN intermediate.users u ON p.owner_email = u.email;
