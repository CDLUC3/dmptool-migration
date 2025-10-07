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
    uri VARCHAR(255) NOT NULL,
    provenance VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    displayName VARCHAR(255) NOT NULL,
    searchName VARCHAR(255),
    funder BOOLEAN NOT NULL DEFAULT 0,
    fundrefId VARCHAR(255),
    homepage VARCHAR(255),
    acronyms JSON,
    aliases JSON,
    types JSON,
    logoURI VARCHAR(255),
    logoName VARCHAR(255),
    contactName VARCHAR(255),
    contactEmail VARCHAR(255),
    ssoEntityId VARCHAR(255),
    feedbackEnabled BOOLEAN NOT NULL DEFAULT 0,
    feedbackMessage TEXT,
    feedbackEmails JSON,
    managed BOOLEAN NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT 1,
    apiTarget VARCHAR(255),
    createdById INT NOT NULL,
    created TIMESTAMP NOT NULL,
    modifiedById INT NOT NULL,
    modified TIMESTAMP NOT NULL
  ),
  enabled true
);

WITH ror_orgs AS (
  SELECT
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
  FROM dmp.registry_orgs ro
  INNER JOIN dmp.orgs o ON ro.org_id = o.id
  LEFT JOIN dmp.identifiers i ON i.identifiable_type = 'Org' AND i.identifiable_id = o.id AND i.identifier_scheme_id = 2
  WHERE ro.org_id IS NOT NULL -- Selects only ROR records we are using
),

non_ror_orgs AS (
  SELECT
    o.*,
    i.value AS ssoEntityId
  FROM dmp.orgs o
  LEFT JOIN dmp.registry_orgs ro ON o.id = ro.org_id
  LEFT JOIN dmp.identifiers i ON i.identifiable_type = 'Org' AND i.identifiable_id = o.id AND i.identifier_scheme_id = 2
  WHERE ro.id IS NULL -- Where no ROR org was mapped to orgs table
)

---- ROR based affiliations
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
  @VAR('super_admin_id') AS createdById,
  CURRENT_TIMESTAMP AS created,
  @VAR('super_admin_id') AS modifiedById,
  CURRENT_TIMESTAMP AS modified
FROM migration.ror_staging rs
INNER JOIN ror_orgs ro ON rs.uri = ro.ror_id -- Selects only ROR records we are using

UNION ALL

-- Non ROR based affiliations
SELECT
  CONCAT('https://dmptool.org/affiliations/', nro.id) AS uri,
  'DMPTOOL' AS provenance,
  nro.name AS name,
  nro.name AS displayName,
  CONCAT_WS(' | ', nro.name, nro.abbreviation, nro.target_url) AS searchName,
  nro.org_type IN (2, 3, 4, 5) AS funder,
  NULL AS fundrefId,
  nro.target_url AS homepage,
  IF(nro.abbreviation IS NOT NULL, JSON_ARRAY(nro.abbreviation), JSON_ARRAY()) AS acronyms,
  JSON_ARRAY() AS aliases,
  CASE
    WHEN nro.org_type = 1 THEN JSON_ARRAY('EDUCATION')
    WHEN nro.org_type = 2 THEN JSON_ARRAY('GOVERNMENT')
    WHEN nro.org_type = 3 THEN JSON_ARRAY('EDUCATION', 'GOVERNMENT')
    WHEN nro.org_type = 4 THEN JSON_ARRAY('OTHER')
    WHEN nro.org_type = 5 THEN JSON_ARRAY('EDUCATION', 'OTHER')
    WHEN nro.org_type = 6 THEN JSON_ARRAY('GOVERNMENT', 'OTHER')
    WHEN nro.org_type = 7 THEN JSON_ARRAY('EDUCATION', 'GOVERNMENT', 'OTHER')
    ELSE JSON_ARRAY('EDUCATION')
  END AS types,
  nro.logo_uid AS logoURI,
  nro.logo_name AS logoName,
  nro.contact_name AS contactName,
  nro.contact_email AS contactEmail,
  nro.ssoEntityId,
  nro.feedback_enabled AS feedbackEnabled,
  nro.feedback_msg AS feedbackMessage,
  JSON_ARRAY() AS feedbackEmails,
  nro.managed,
  TRUE AS active,
  NULL AS apiTarget,
  @VAR('super_admin_id') AS createdById,
  CAST(nro.created_at AS TIMESTAMP) AS created,
  @VAR('super_admin_id') AS modifiedById,
  CAST(nro.updated_at AS TIMESTAMP) AS modified
FROM non_ror_orgs nro
