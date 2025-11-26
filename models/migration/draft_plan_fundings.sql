MODEL (
  name migration.draft_plan_fundings,
  kind FULL,
  columns (
    old_draft_id VARCHAR(255) NOT NULL,
    planId INT UNSIGNED NOT NULL,
    projectFundingId INT UNSIGNED NOT NULL,
    createdById INT UNSIGNED NOT NULL,
    created DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifiedById INT UNSIGNED NOT NULL,
    modified DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ),
  enabled true
);

SELECT
  p.old_draft_id AS old_draft_id,
  p.id AS planId,
  dpf.id AS projectFundingId,
  dpf.createdById,
  dpf.created,
  dpf.modifiedById,
  dpf.modified
FROM migration.draft_plans p
  LEFT JOIN migration.draft_project_fundings dpf ON p.projectId = dpf.projectId;