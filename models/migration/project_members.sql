MODEL (
  name migration.project_members,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
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

SELECT
  ROW_NUMBER() OVER () AS id,
  p.id AS projectId,
  u.org_id AS affiliationId,
  u.firstname AS givenName,
  u.surname AS surName,
  u.orcid AS orcid,
  p.owner_email AS email,
  u.id AS createdById,
  u.created_at AS created,
  u.id AS modifiedById,
  u.updated_at AS modified,
  TRUE AS isPrimaryContact
FROM intermediate.plans p
INNER JOIN intermediate.users u ON p.owner_email = u.email;
