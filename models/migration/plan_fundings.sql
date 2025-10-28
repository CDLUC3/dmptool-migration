MODEL (
  name migration.plan_fundings,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    old_plan_id INT UNSIGNED NOT NULL,
    planId INT UNSIGNED NOT NULL,
    projectFundingId INT UNSIGNED NOT NULL,
    createdById INT UNSIGNED NOT NULL,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifiedById INT UNSIGNED NOT NULL,
    modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ),
  enabled true
);

WITH default_super_admin AS (
  SELECT id
  FROM intermediate.users
  WHERE role = 'SUPERADMIN'
  ORDER BY id DESC LIMIT 1
)

SELECT
  ROW_NUMBER() OVER (ORDER BY p.id ASC) AS id,
  p.id AS old_plan_id,
  mp.id AS planId,
  p.id AS projectFundingId,
  mp.createdById,
  p.created_at AS created,
  mp.modifiedById,
  p.updated_at AS modified
FROM intermediate.plans p
LEFT JOIN migration.plans mp ON p.id = mp.old_plan_id;