MODEL (
  name migration.final_project_members,
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

WITH duplicate_members AS (
  SELECT
    MIN(id) as minId,
    MAX(id) as maxId,
    projectId, email, orcid, givenName, surName,
    count(isPrimaryContact) AS primaryContactCount
  FROM migration.project_members
  GROUP BY projectId, email, orcid, givenName, surName
  HAVING primaryContactCount > 1
)

SELECT
  pm.id,
  pm.projectId,
  pm.affiliationId,
  pm.givenName,
  pm.surName,
  pm.orcid,
  pm.email,
  (dmGood.minId IS NOT NULL) as isPrimaryContact,
  pm.roles,
  pm.createdById,
  pm.created,
  pm.modifiedById,
  pm.modified
FROM migration.project_members AS pm
  LEFT JOIN duplicate_members AS dmGood ON pm.id = dmGood.minId
    LEFT JOIN duplicate_members AS dmBad ON pm.id = dmBad.maxId
WHERE dmBad.maxId IS NULL
ORDER BY pm.id;
