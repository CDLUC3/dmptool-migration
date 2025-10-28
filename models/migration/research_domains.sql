--   Target schema (table `researchDomains`):
--  `id` int NOT NULL AUTO_INCREMENT,
--  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `uri` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `description` varchar(255) COLLATE utf8mb4_unicode_ci,
--  `parentResearchDomainId` int,
--  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `createdById` int DEFAULT NULL,
--  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `modifiedById` int DEFAULT NULL,

MODEL (
  name migration.research_domains,
  kind FULL,
  columns (
    id INT UNSIGNED PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    uri VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    parentResearchDomainId INT,
    created TIMESTAMP NOT NULL,
    createdById INT,
    modified TIMESTAMP NOT NULL,
    modifiedById INT
  ),
  audits (
    unique_values(columns := (name, uri)),
    not_null(columns := (name, uri, created, createdById, modified, modifiedById))
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
  rd.id,
  REPLACE(LOWER(TRIM(rd.label)), ' ', '-') AS name,
  CONCAT('https://dmptool.org/research_domains/', REPLACE(LOWER(TRIM(rd.label)), ' ', '-')) AS uri,
  TRIM(rd.label) AS description,
  rd.parent_id AS parentResearchDomainId,
  rd.created_at AS created,
  (SELECT id FROM default_super_admin) AS createdById,
  rd.updated_at AS modified,
  (SELECT id FROM default_super_admin) AS modifiedById
FROM source_db.research_domains AS rd;
