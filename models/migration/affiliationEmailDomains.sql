-- Target schema:
--  `id` int NOT NULL AUTO_INCREMENT,
--  `affiliationId` int NOT NULL,
--  `emailDomain` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `createdById` int NOT NULL,
--  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `modifiedById` int NOT NULL,
--  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP

MODEL (
  name migration.affiliation_email_domains,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    affiliationId VARCHAR(255) NOT NULL,
    emailDomain VARCHAR(255),
    createdById INT UNSIGNED NOT NULL,
    created TIMESTAMP NOT NULL,
    modifiedById INT UNSIGNED NOT NULL,
    modified TIMESTAMP NOT NULL
  ),
  audits (
    unique_values(columns := (id, emailDomain), blocking := false)
  ),
  enabled true
);

WITH email_domains AS (
  SELECT
    CASE
      WHEN ro.org_id IS NULL THEN CONCAT('https://dmptool.org/affiliations/', o.id)
      ELSE ro.ror_id
    END AS affiliationId,
    TRIM(REGEXP_REPLACE(
      REGEXP_SUBSTR(o.target_url, '(?<=//)[^/]+'),
      '^www\\.',
      ''
    )) AS emailDomain,
    @VAR('super_admin_id') AS createdById,
    o.created_at AS created,
    @VAR('super_admin_id') AS modifiedById,
    o.updated_at AS modified
  FROM dmp.orgs o
  LEFT JOIN dmp.registry_orgs ro ON o.id = ro.org_id
)

SELECT
  ROW_NUMBER() OVER () AS id,
  ed.*
FROM email_domains ed
WHERE ed.emailDomain IS NOT NULL AND ed.emailDomain != "";
