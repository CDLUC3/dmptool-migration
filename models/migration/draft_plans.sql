MODEL (
  name migration.draft_plans,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    old_draft_id VARCHAR(255) NOT NULL,
    projectId INT UNSIGNED NOT NULL,
    versionedTemplateId INT UNSIGNED NOT NULL,
    title VARCHAR(255),
    visibility VARCHAR(16),
    status VARCHAR(16),
    dmpId VARCHAR(255),
    registeredById INT,
    registered DATETIME,
    languageId CHAR(5) NOT NULL DEFAULT 'en-US',
    featured TINYINT(1) NOT NULL DEFAULT 0,
    createdById INT UNSIGNED NOT NULL,
    created DATETIME NOT NULL DEFAULT CURRENT_DATE,
    modifiedById INT UNSIGNED NOT NULL,
    modified DATETIME NOT NULL DEFAULT CURRENT_DATE,
  ),
  enabled true,
);

WITH default_template AS (
  SELECT id
  FROM migration.versioned_templates
  WHERE active = 1 AND bestPractice = 1
  ORDER BY id DESC LIMIT 1
),

max_id AS (
  SELECT COALESCE(MAX(id), 0) AS max_id_value
  FROM dmptool.plans
),

sequenced_source_data AS (
  SELECT
    ROW_NUMBER() OVER (ORDER BY p.created) AS row_num,
    p.old_draft_id AS old_draft_id,
    p.id AS projectId,
    (SELECT id FROM default_template) AS versionedTemplateId,
    TRIM (p.title) AS title,
    COALESCE(UPPER(pd.visibility), 'PRIVATE') AS visibility,
    CASE WHEN p.dmp_id IS NOT NULL THEN 'COMPLETE' ELSE 'DRAFT' END AS status,
    p.dmp_id AS dmpId,
    CASE WHEN p.dmp_id IS NOT NULL THEN p.modifiedById ELSE NULL END AS registeredById,
    CASE WHEN p.dmp_id IS NOT NULL THEN p.modified ELSE NULL END AS registered,
    'en-US' AS languageId,
    0 AS featured,
    p.createdById,
    p.created,
    p.modifiedById,
    p.modified
  FROM migration.draft_projects p
    JOIN intermediate.pilot_drafts AS pd ON pd.old_draft_id = p.old_draft_id
)

SELECT
  (s.row_num + m.max_id_value) AS id,
  s.old_draft_id,
  s.projectId,
  s.versionedTemplateId,
  s.title,
  s.visibility,
  s.status,
  s.dmpId,
  s.registeredByid,
  s.registered,
  s.languageId,
  s.featured,
  s.createdById,
  s.created,
  s.modifiedById,
  s.modified
FROM sequenced_source_data AS s
  CROSS JOIN max_id AS m;
