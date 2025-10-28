--  Target schema:
--  `id` int NOT NULL AUTO_INCREMENT,
--  `uri` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `provenance` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DMPTOOL',
--  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `displayName` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `searchName` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
--  `funder` tinyint(1) NOT NULL DEFAULT '0',
--  `fundrefId` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
--  `homepage` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
--  `acronyms` json DEFAULT NULL,
--  `aliases` json DEFAULT NULL,
--  `types` json DEFAULT NULL,
--  `logoURI` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
--  `logoName` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
--  `contactName` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
--  `contactEmail` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
--  `ssoEntityId` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
--  `feedbackEnabled` tinyint(1) NOT NULL DEFAULT '0',
--  `feedbackMessage` text COLLATE utf8mb4_unicode_ci,
--  `feedbackEmails` json DEFAULT NULL,
--  `managed` tinyint(1) NOT NULL DEFAULT '0',
--  `active` tinyint(1) NOT NULL DEFAULT '1',
--  `apiTarget` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
--  `createdById` int NOT NULL,
--  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `modifiedById` int NOT NULL,
--  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,

MODEL (
  name migration.affiliations,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    uri VARCHAR(255) COLLATE utf8mb4_unicode_ci NOT NULL,
    provenance VARCHAR(255) COLLATE utf8mb4_unicode_ci NOT NULL,
    name VARCHAR(255) COLLATE utf8mb4_unicode_ci NOT NULL,
    displayName VARCHAR(255) COLLATE utf8mb4_unicode_ci NOT NULL,
    searchName VARCHAR(512) COLLATE utf8mb4_unicode_ci ,
    funder BOOLEAN NOT NULL DEFAULT 0,
    fundrefId VARCHAR(255) COLLATE utf8mb4_unicode_ci ,
    homepage VARCHAR(255) COLLATE utf8mb4_unicode_ci ,
    acronyms JSON COLLATE utf8mb4_unicode_ci ,
    aliases JSON COLLATE utf8mb4_unicode_ci ,
    types JSON COLLATE utf8mb4_unicode_ci ,
    logoURI VARCHAR(255) COLLATE utf8mb4_unicode_ci ,
    logoName VARCHAR(255) COLLATE utf8mb4_unicode_ci ,
    contactName VARCHAR(255) COLLATE utf8mb4_unicode_ci ,
    contactEmail VARCHAR(255) COLLATE utf8mb4_unicode_ci ,
    ssoEntityId VARCHAR(255) COLLATE utf8mb4_unicode_ci ,
    feedbackEnabled BOOLEAN NOT NULL DEFAULT 0,
    feedbackMessage TEXT COLLATE utf8mb4_unicode_ci ,
    feedbackEmails JSON COLLATE utf8mb4_unicode_ci ,
    managed BOOLEAN NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT 1,
    apiTarget VARCHAR(255) COLLATE utf8mb4_unicode_ci ,
    createdById INT UNSIGNED NOT NULL,
    created TIMESTAMP NOT NULL,
    modifiedById INT UNSIGNED NOT NULL,
    modified TIMESTAMP NOT NULL
  ),
  audits (
    unique_values(columns := (id, uri, displayName), blocking := false)
  ),
  enabled true
);

WITH default_super_admin AS (
  SELECT id
  FROM intermediate.users
  WHERE role = 'SUPERADMIN'
  ORDER BY id DESC LIMIT 1
),

ror_orgs AS (
  SELECT
    ro.org_id,
    ro.ror_id,
    i.value AS ssoEntityId,
    ro.api_target,
    o.managed,
    o.contact_email,
    o.contact_name,
    o.logo_name,
    o.logo_uid,
    o.feedback_enabled,
    o.feedback_msg,
    o.links
  FROM source_db.registry_orgs ro
  INNER JOIN source_db.orgs o ON ro.org_id = o.id
  LEFT JOIN source_db.identifiers i ON i.identifiable_type = 'Org' AND i.identifiable_id = o.id AND i.identifier_scheme_id = 2
  WHERE ro.org_id IS NOT NULL -- Selects only ROR records we are using
),

non_ror_orgs AS (
  SELECT
    o.*,
    i.value AS ssoEntityId
  FROM source_db.orgs o
  LEFT JOIN source_db.registry_orgs ro ON o.id = ro.org_id
  LEFT JOIN source_db.identifiers i ON i.identifiable_type = 'Org' AND i.identifiable_id = o.id AND i.identifier_scheme_id = 2
  WHERE ro.id IS NULL -- Where no ROR org was mapped to orgs table
),

---- ROR based affiliations
ror_affiliations AS (
  SELECT
    rs.uri AS uri,
    rs.provenance AS provenance,
    rs.name AS name,
    rs.displayName AS displayName,
    rs.searchName AS searchName,
    IF(rs.funder=1, TRUE, FALSE) AS funder,
    rs.fundrefId AS fundrefId,
    rs.homepage AS homepage,
    CAST(rs.acronyms AS JSON) AS acronyms,
    CAST(rs.aliases AS JSON) AS aliases,
    CAST(rs.types AS JSON) AS types,
    ro.logo_uid AS logoURI,
    ro.logo_name AS logoName,
    ro.contact_name AS contactName,
    ro.contact_email AS contactEmail,
    ro.ssoEntityId AS ssoEntityId,
    ro.feedback_enabled AS feedbackEnabled,
    ro.feedback_msg AS feedbackMessage,
    JSON_ARRAY() AS feedbackEmails,
    ro.managed,
    TRUE AS active,
    ro.api_target AS apiTarget,
    (SELECT id FROM default_super_admin) AS createdById,
    CURRENT_TIMESTAMP AS created,
    (SELECT id FROM default_super_admin) AS modifiedById,
    CURRENT_TIMESTAMP AS modified
  FROM migration.ror_staging rs
    LEFT JOIN ror_orgs ro ON rs.uri = ro.ror_id
),

-- Non ROR based affiliations
non_ror_affiliations AS (
  SELECT
    CONCAT('https://dmptool.org/affiliations/', nro.id) AS uri,
    'DMPTOOL' AS provenance,
    TRIM(nro.name) AS name,
    TRIM(nro.name) AS displayName,
    SUBSTRING(CONCAT_WS(' | ', TRIM(nro.name), TRIM(nro.abbreviation), TRIM(nro.target_url)), 1, 512) AS searchName,
    nro.org_type IN (2, 3, 6, 7) AS funder,
    NULL AS fundrefId,
    TRIM(nro.target_url) AS homepage,
    IF(nro.abbreviation IS NOT NULL, JSON_ARRAY(TRIM(nro.abbreviation)), JSON_ARRAY()) AS acronyms,
    JSON_ARRAY() AS aliases,
    CASE
      WHEN nro.org_type = 2 THEN '["GOVERNMENT"]'
      WHEN nro.org_type = 3 THEN '["EDUCATION", "GOVERNMENT"]'
      WHEN (nro.org_type = 4 AND LOWER(nro.name) LIKE '%college%' OR LOWER(nro.name) LIKE '%university%' OR LOWER(nro.name) LIKE '%school%') THEN '["EDUCATION"]'
      WHEN (nro.org_type = 4 AND LOWER(nro.name) NOT LIKE '%college%' AND LOWER(nro.name) NOT LIKE '%university%' AND LOWER(nro.name) NOT LIKE '%school%') THEN '["OTHER"]'
      WHEN nro.org_type IN (5, 6) THEN '["NONPROFIT"]'
      WHEN nro.org_type = 7 THEN '["EDUCATION", "GOVERNMENT", "OTHER"]'
      ELSE '["EDUCATION"]'
    END AS types,
    TRIM(nro.logo_uid) AS logoURI,
    TRIM(nro.logo_name) AS logoName,
    TRIM(nro.contact_name) AS contactName,
    TRIM(nro.contact_email) AS contactEmail,
    TRIM(nro.ssoEntityId) AS ssoEntityId,
    nro.feedback_enabled AS feedbackEnabled,
    TRIM(nro.feedback_msg) AS feedbackMessage,
    JSON_ARRAY() AS feedbackEmails,
    nro.managed,
    TRUE AS active,
    NULL AS apiTarget,
    (SELECT id FROM default_super_admin) AS createdById,
    CAST(nro.created_at AS TIMESTAMP) AS created,
    (SELECT id FROM default_super_admin) AS modifiedById,
    CAST(nro.updated_at AS TIMESTAMP) AS modified
  FROM non_ror_orgs nro
)

-- Build final table
SELECT
  ROW_NUMBER() OVER (ORDER BY a.modified ASC) AS id,
  a.*
FROM (
  SELECT * FROM ror_affiliations

  UNION ALL

  SELECT * FROM non_ror_affiliations
  WHERE NOT EXISTS (
    SELECT 1
    FROM ror_affiliations ra
    WHERE LOWER(ra.displayName) = LOWER(TRIM(non_ror_affiliations.name))
  )
) AS a;
