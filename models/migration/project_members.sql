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
  audits (
    unique_values(columns := (id), blocking := false)
  ),
  enabled true
);

SELECT * FROM intermediate.project_members;