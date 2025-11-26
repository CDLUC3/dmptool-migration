MODEL (
  name intermediate.pilot_draft_members,
  kind FULL,
  columns (
    id INT AUTO_INCREMENT PRIMARY KEY,
    old_draft_id VARCHAR(255),
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    email VARCHAR(255),
    is_contact BOOLEAN,
    role VARCHAR(255),
    orcid VARCHAR(255),
    ror VARCHAR(255)
  ),
  enabled true
);

WITH max_id AS (
  SELECT COALESCE(MAX(id), 0) AS max_id_value
  FROM migration.final_project_members
),

sequenced_source_data AS (
  SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY ppm.old_draft_id) AS row_num,
    ppm.old_draft_id,
    ppm.first_name,
    ppm.last_name,
    ppm.email,
    ppm.is_contact,
    ppm.role,
    ppm.orcid,
    ppm.ror
  FROM seeds.pilot_project_members AS ppm
)

SELECT
  (s.row_num + m.max_id_value) AS id,
  s.*
FROM sequenced_source_data AS s
  CROSS JOIN max_id AS m;



