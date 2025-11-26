MODEL (
  name migration.draft_project_members,
  kind FULL,
  columns (
    id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    projectId INT UNSIGNED NOT NULL,
    affiliationId VARCHAR(255),
    givenName VARCHAR(255),
    surName VARCHAR(255),
    orcid VARCHAR(255),
    email VARCHAR(255),
    isPrimaryContact TINYINT(1) NOT NULL DEFAULT 0,
    createdById INT UNSIGNED NOT NULL,
    created DATETIME NOT NULL DEFAULT CURRENT_DATE,
    modifiedById INT UNSIGNED NOT NULL,
    modified DATETIME NOT NULL DEFAULT CURRENT_DATE,
  ),
  enabled true
);

WITH max_id AS (
  SELECT COALESCE(MAX(id), 0) AS max_id_value
  FROM migration.project_members
),

sequenced_source_data AS (
  SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY dp.created) AS row_num,
    dp.id AS projectId,
    pm.ror AS affiliationId,
    pm.first_name AS givenName,
    pm.last_name AS surName,
    CASE
      WHEN pm.email IS NOT NULL AND pm.orcid IS NULL THEN
        (SELECT fpm.orcid
         FROM migration.final_project_members fpm
         WHERE pm.email = fpm.email
         ORDER BY fpm.orcid DESC LIMIT 1)
      ELSE pm.orcid
    END AS orcid,
    pm.email,
    (pm.is_contact) as isPrimaryContact,
    dp.createdById,
    dp.created,
    dp.modifiedById,
    dp.modified
  FROM intermediate.pilot_draft_members AS pm
    LEFT JOIN migration.draft_projects AS dp ON pm.old_draft_id = dp.old_draft_id
  WHERE email NOT LIKE ('%@test.%') AND dp.id IS NOT NULL
  GROUP BY dp.id, pm.ror, pm.first_name, pm.last_name, pm.email, pm.orcid, pm.is_contact,
           dp.createdById, dp.created, dp.modifiedById, dp.modified
  ORDER BY pm.id
)

SELECT
  (s.row_num + m.max_id_value) AS id,
  s.*
FROM sequenced_source_data s
  CROSS JOIN max_id m;