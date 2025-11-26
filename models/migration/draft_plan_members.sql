MODEL (
  name migration.draft_plan_members,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    planId INT UNSIGNED NOT NULL,
    projectMemberId INT UNSIGNED NOT NULL,
    isPrimaryContact TINYINT(1) NOT NULL,
    createdById INT UNSIGNED NOT NULL,
    created DATETIME NOT NULL DEFAULT CURRENT_DATE,
    modifiedById INT UNSIGNED NOT NULL,
    modified DATETIME NOT NULL DEFAULT CURRENT_DATE,
  ),
  enabled true
);

WITH max_id AS (
  SELECT COALESCE(MAX(id), 0) AS max_id_value
  FROM migration.plan_members
),

sequenced_source_data AS (
  SELECT
    ROW_NUMBER() OVER (ORDER BY dpm.created) AS row_num,
    p.id AS planId,
    dpm.id AS projectMemberId,
    dpm.isPrimaryContact,
    dpm.createdById,
    dpm.created,
    dpm.modifiedById,
    dpm.modified
  FROM migration.draft_plans p
    LEFT JOIN migration.draft_project_members dpm ON p.projectId = dpm.projectId
)

SELECT
  (s.row_num + m.max_id_value) AS id,
  s.*
FROM sequenced_source_data s
  CROSS JOIN max_id m;
