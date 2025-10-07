--   Target schema (table `researchDomains`):
--  `id` int NOT NULL AUTO_INCREMENT,
--  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `uri` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `description` varchar(255) COLLATE utf8mb4_unicode_ci,
--  `parentResearchId` int,
--  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `createdById` int DEFAULT NULL,
--  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `modifiedById` int DEFAULT NULL,

MODEL (
  name migration.research_domains,
  kind FULL,
  audits (
    assert_row_count(dmp_table:='research_domains', blocking := false),
  ),
  enabled true
);

SELECT
  CAST(rd.identifier AS SIGNED) AS id,
  NULL AS parent_id,
  REPLACE(LOWER(rd.label), ' ', '-') AS name,
  CONCAT('https://dmptool.org/research_domains/', REPLACE(LOWER(rd.label), ' ', '-')) AS uri,
  rd.label AS description
FROM dmp.research_domains AS rd
WHERE rd.parent_id IS NULL

UNION

SELECT
  NULL AS id,
  parent.id AS parent_id,
  REPLACE(LOWER(rd.label), ' ', '-') AS name,
  CONCAT('https://dmptool.org/research_domains/', REPLACE(LOWER(rd.label), ' ', '-')) AS uri,
  rd.label AS description
FROM dmp.research_domains AS rd
  LEFT JOIN dmp.research_domains AS parent ON rd.parent_id = parent.id
WHERE rd.parent_id IS NOT NULL;
