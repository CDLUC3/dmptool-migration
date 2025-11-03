MODEL (
  name migration.project_members,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    old_plan_id INT UNSIGNED NOT NULL,
    projectId INT UNSIGNED NOT NULL,
    affiliationId VARCHAR(255),
    givenName VARCHAR(255),
    surName VARCHAR(255),
    orcid VARCHAR(255),
    email VARCHAR(255),
    isPrimaryContact TINYINT(1) NOT NULL DEFAULT 0,
    createdById INT UNSIGNED NOT NULL,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifiedById INT UNSIGNED NOT NULL,
    modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
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
  u.org_id AS affiliationId,
  u.firstname AS givenName,
  u.surname AS surName,
  u.orcid AS orcid,
  p.owner_email AS email,
  COALESCE(u.id, (SELECT id FROM default_super_admin)) AS createdById,
  u.created_at AS created,
  COALESCE(u.id, (SELECT id FROM default_super_admin)) AS modifiedById,
  u.updated_at AS modified,
  TRUE AS isPrimaryContact
FROM intermediate.plans p
LEFT JOIN intermediate.users u ON p.owner_email = u.email
LEFT JOIN migration.projects np ON p.id = np.old_plan_id;
