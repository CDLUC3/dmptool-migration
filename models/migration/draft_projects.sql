MODEL (
  name migration.draft_projects,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    old_draft_id VARCHAR(255) NOT NULL,
    dmp_id VARCHAR(255),
    title VARCHAR(255) NOT NULL,
    abstractText TEXT,
    startDate VARCHAR(16),
    endDate VARCHAR(16),
    visibility VARCHAR(16) NOT NULL DEFAULT 'PRIVATE',
    isTestProject TINYINT(1) NOT NULL DEFAULT 0,
    createdById INT UNSIGNED NOT NULL,
    created DATETIME NOT NULL DEFAULT CURRENT_DATE,
    modifiedById INT UNSIGNED NOT NULL,
    modified DATETIME NOT NULL DEFAULT CURRENT_DATE,
  ),
  enabled true
);

WITH max_id AS (
  SELECT COALESCE(MAX(id), 0) AS max_id_value
  FROM dmptool.projects
),

sequenced_source_data AS (
  SELECT
    t.*,
    ROW_NUMBER() OVER (ORDER BY t.created) AS row_num
  FROM intermediate.pilot_drafts AS t
  WHERE t.createdById NOT IN (48205)
    AND LOWER(t.title) NOT LIKE '%test%'
    AND LOWER(t.title) NOT LIKE '%please delete%'
    AND LOWER(t.title) NOT LIKE '%delete me%'
    AND LOWER(t.title) != 'blabhlahalbh'
    AND t.old_draft_id NOT IN (
      '20240524-d728de5302e4',
      '20250306-9c7227d187df',
      '20250108-df8738432a7f',
      '20240502-beae2a45daa4',
      '20240502-1bcfd9e067ed',
      '20240503-41cf05c7e1be',
      '20240124-288e8c74cb87',
      '20240326-a26e3a827f2b',
      '20240304-5b98934b2546',
      '20240404-f72a2a0de803',
      '20240412-36f161cd18fa'
    )
)

SELECT
  (s.row_num + m.max_id_value) AS id,
  s.old_draft_id,
  s.dmp_id,
  TRIM(s.title) AS title,
  TRIM(s.description) AS abstractText,
  CASE WHEN s.start_date IS NULL THEN NULL ELSE DATE_FORMAT(s.start_date, '%Y-%m-%d') END AS startDate,
  CASE WHEN s.end_date IS NULL THEN NULL ELSE DATE_FORMAT(s.end_date, '%Y-%m-%d') END AS endDate,
  COALESCE(s.visibility, 'PRIVATE') AS visibility,
  (s.createdById IN (95198, 48205) OR LOWER(title) LIKE '%test%') as isTestProject,
  s.createdById,
  s.created,
  s.modifiedById,
  s.modified
FROM sequenced_source_data AS s
  CROSS JOIN max_id AS m;
