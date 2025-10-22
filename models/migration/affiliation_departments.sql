MODEL (
  name migration.affiliation_departments,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    affiliationId VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    code VARCHAR(255),
    createdById INT UNSIGNED NOT NULL,
    created TIMESTAMP NOT NULL,
    modifiedById INT UNSIGNED NOT NULL,
    modified TIMESTAMP NOT NULL
  ),
  audits (
    unique_values(columns := (id), blocking := false)
  ),
  enabled true
);

SELECT
  ROW_NUMBER() OVER () AS id,
  CASE
    WHEN ro.org_id IS NULL THEN CONCAT('https://dmptool.org/affiliations/', o.id)
    ELSE ro.ror_id
  END AS affiliationId,
  TRIM(d.name) AS name,
  TRIM(d.code) AS code,
  @VAR('super_admin_id') AS createdById,
  d.created_at AS created,
  @VAR('super_admin_id') AS modifiedById,
  d.updated_at AS modified
FROM dmp.departments d
INNER JOIN dmp.orgs o ON d.org_id = o.id
LEFT JOIN dmp.registry_orgs ro ON o.id = ro.org_id;