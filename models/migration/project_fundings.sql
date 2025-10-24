MODEL (
  name migration.project_fundings,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    projectId INT UNSIGNED NOT NULL,
    affiliationId VARCHAR(255) NOT NULL,
    status VARCHAR(16) NOT NULL,
    funderProjectNumber VARCHAR(255) DEFAULT NULL,
    grantId VARCHAR(255) DEFAULT NULL,
    funderOpportunityNumber VARCHAR(255) DEFAULT NULL,
    createdById INT UNSIGNED NOT NULL,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifiedById INT UNSIGNED NOT NULL,
    modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ),
  enabled true
);

SELECT
  ROW_NUMBER() OVER () AS id,
  p.id AS projectId,
  p.funder_id AS affiliationId,
  p.funding_status AS status,
  NULL AS funderProjectNumber,
  p.grant_id AS grantId,
  p.grant_number AS funderOpportunityNumber,
  u.id AS createdById,
  p.created_at AS created,
  u.id AS modifiedById,
  p.updated_at AS modified
FROM intermediate.plans p
LEFT JOIN intermediate.users u ON p.owner_email = u.email;