MODEL (
  name migration.draft_project_fundings,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    old_draft_id VARCHAR(255) NOT NULL,
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

WITH max_id AS (
  SELECT COALESCE(MAX(id), 0) AS max_id_value
  FROM migration.project_fundings
),

sequenced_source_data AS (
  SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY p.created) AS row_num,
    p.old_draft_id,
    np.id AS projectId,
    CASE
      WHEN p.funder_id = 'https://api.crossref.org/funders/100000104' THEN 'https://ror.org/027ka1x80'
      ELSE p.funder_id
    END AS affiliationId,
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
    JOIN migration.draft_projects np ON p.old_draft_id = np.old_draft_id
    WHERE p.funder_id IS NOT NULL
)

SELECT
  (s.row_num + m.max_id_value) AS id,
  s.*
FROM sequenced_source_data s
  CROSS JOIN max_id m;
