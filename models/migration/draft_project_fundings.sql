MODEL (
  name migration.draft_project_fundings,
  kind FULL,
  columns (
    old_draft_id INT UNSIGNED NOT NULL,
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

SELECT DISTINCT
  p.old_draft_id,
  np.id AS projectId,
  p.funder_id AS affiliationId,
  CASE p.funding_status
    WHEN 'granted' THEN 'GRANTED'
    ELSE 'PLANNED'
  END AS status,
  TRIM(p.funder_project_id) AS funderProjectNumber,
  TRIM(p.grant_id) AS grantId,
  TRIM(p.funder_opportunity_id) AS funderOpportunityNumber,
  p.createdById,
  p.created,
  p.modifiedById,
  p.modified
FROM intermediate.pilot_drafts p
  LEFT JOIN migration.draft_projects np ON p.old_draft_id = np.old_draft_id
WHERE p.funder_id IS NOT NULL;
