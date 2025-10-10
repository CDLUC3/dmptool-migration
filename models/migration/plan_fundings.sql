MODEL (
  name migration.plan_fundings,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    planId INT UNSIGNED NOT NULL,
    projectFundingId INT UNSIGNED NOT NULL,
    createdById INT UNSIGNED NOT NULL,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifiedById INT UNSIGNED NOT NULL,
    modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ),
  enabled true
);

SELECT
  p.id,
  p.id AS planId,
  p.id AS projectFundingId,
  u.id AS createdById,
  p.created_at AS created,
  u.id AS modifiedById,
  p.updated_at AS modified
FROM intermediate.plans p
LEFT JOIN intermediate.users u ON p.owner_email = u.email;