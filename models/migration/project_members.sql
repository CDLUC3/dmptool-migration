MODEL (
  name migration.project_members,
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
    roles INT NOT NULL DEFAULT 15,
    createdById INT UNSIGNED NOT NULL,
    created DATETIME NOT NULL DEFAULT CURRENT_DATE,
    modifiedById INT UNSIGNED NOT NULL,
    modified DATETIME NOT NULL DEFAULT CURRENT_DATE,
  ),
  enabled true
);

-- Select all existing contributors
WITH members AS (
  SELECT
    p.id AS projectId,
    c.affiliation_id AS affiliationId,
    c.first_name AS givenName,
    c.last_name AS surName,
    c.orcid,
    c.email,
    0 AS isPrimaryContact,
    c.roles,
    p.createdById,
    p.created     AS created,
    p.createdById AS modifiedById,
    p.modified    AS modified
  FROM intermediate.contributors AS c
    JOIN migration.projects p ON p.old_plan_id = c.plan_id

  UNION ALL

  -- Select owners who are NOT found in the contributors table
  SELECT DISTINCT
    o.projectId,
    o.affiliationId,
    TRIM(o.givenName),
    TRIM(o.surName),
    TRIM(o.orcid),
    TRIM(o.email),
    1 AS isPrimaryContact,
    15 AS roles,
    o.createdById,
    o.created  AS created,
    o.createdById,
    o.modified AS modified
  FROM intermediate.plan_owners o
  WHERE o.add_to_members = 1
),

projects_with_contact AS (
  SELECT DISTINCT p.old_plan_id
  FROM migration.projects AS p
    JOIN members AS m ON p.id = m.projectId
  WHERE m.isPrimaryContact = 1
),

full_members AS (
  SELECT *
  FROM members

  UNION ALL

  SELECT DISTINCT
    po.projectId,
    po.affiliationId,
    TRIM(po.givenName),
    TRIM(po.surName),
    TRIM(po.orcid),
    TRIM(po.email),
    1 AS isPrimaryContact,
    15 AS roles,
    po.createdById,
    po.created  AS created,
    po.createdById,
    po.modified AS modified
  FROM intermediate.plan_owners AS po
    LEFT JOIN projects_with_contact AS pwc ON po.old_plan_id = pwc.old_plan_id
  WHERE pwc.old_plan_id IS NULL
)

SELECT
  ROW_NUMBER() OVER (ORDER BY created) AS id,
  projectId,
  affiliationId,
  givenName,
  surName,
  orcid,
  email,
  isPrimaryContact,
  roles,
  createdById,
  created,
  modifiedById,
  modified
FROM full_members;
