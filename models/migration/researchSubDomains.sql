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
  name migration.researchSubDomains,
  kind FULL,
  columns (
    id INT AUTO_INCREMENT PRIMARY KEY,
    parentResearchDomain VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    uri VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    created TIMESTAMP NOT NULL,
    createdById INT,
    modified TIMESTAMP NOT NULL,
    modifiedById INT
  ),
  audits (
    assert_row_count(dmp_table:='research_domains', blocking := false),
    unique_values(columns := (name, uri)),
    not_null(columns := (name, uri, parentResearchDomain, created, createdById, modified, modifiedById))
  ),
  enabled true
);

SELECT
    ROW_NUMBER() OVER (ORDER BY dmp.research_domains.created_at) AS id,
    REPLACE(LOWER(parent_rd.label), ' ', '-') AS parentResearchDomain,
    REPLACE(LOWER(rd.label), ' ', '-') AS name,
    CONCAT('https://dmptool.org/research_domains/', REPLACE(LOWER(rd.label), ' ', '-')) AS uri,
    rd.label AS description,
    rd.created_at AS created,
    @VAR('super_admin_id') AS createdById,
    rd.updated_at AS modified,
    @VAR('super_admin_id') AS modifiedById
FROM dmp.research_domains AS rd
  INNER JOIN dmp.research_domains AS parent_rd ON rd.parent_id = parent_rd.id
WHERE rd.parent_id IS NOT NULL;
