MODEL (
  name migration.project_fundings,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    old_plan_id INT UNSIGNED NOT NULL,
    projectId INT UNSIGNED NOT NULL,
    affiliationId VARCHAR(255) NOT NULL,
    status VARCHAR(16) NOT NULL,
    funderProjectNumber VARCHAR(255) DEFAULT NULL,
    grantId VARCHAR(255) DEFAULT NULL,
    funderOpportunityNumber VARCHAR(255) DEFAULT NULL,
    createdById INT UNSIGNED NOT NULL,
    created DATETIME NOT NULL DEFAULT CURRENT_DATE,
    modifiedById INT UNSIGNED NOT NULL,
    modified DATETIME NOT NULL DEFAULT CURRENT_DATE,
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
  np.id AS projectId,
  p.funder_id AS affiliationId,
  CASE p.funding_status
    WHEN 1 THEN 'GRANTED'
    WHEN 2 THEN 'DENIED'
    ELSE 'PLANNED'
  END AS status,
  NULL AS funderProjectNumber,
  TRIM(p.grant_id) AS grantId,
  TRIM(p.grant_number) AS funderOpportunityNumber,
  COALESCE(u.id, (SELECT id FROM default_super_admin)) AS createdById,
  p.created_at AS created,
  COALESCE(u.id, (SELECT id FROM default_super_admin)) AS modifiedById,
  p.updated_at AS modified
FROM intermediate.plans p
  LEFT JOIN intermediate.users u ON p.owner_email = u.email
  LEFT JOIN migration.projects np ON p.id = np.old_plan_id
WHERE p.funder_id IS NOT NULL AND u.id IS NOT NULL;