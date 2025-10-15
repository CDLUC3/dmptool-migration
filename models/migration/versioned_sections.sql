--  Target schema (table `versionedSections`):
--  `id` int NOT NULL AUTO_INCREMENT,
--  `versionedTemplateId` int NOT NULL,
--  `sectionId` int NOT NULL,
--  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `introduction` mediumtext COLLATE utf8mb4_unicode_ci,
--  `requirements` mediumtext COLLATE utf8mb4_unicode_ci,
--  `guidance` mediumtext COLLATE utf8mb4_unicode_ci,
--  `displayOrder` int NOT NULL,
--  `bestPractice` tinyint(1) NOT NULL DEFAULT '0',
--  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `createdById` int NOT NULL,
--  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `modifiedById` int NOT NULL,

MODEL (
  name migration.versioned_sections,
  kind FULL,
  columns (
    id INT UNSIGNED PRIMARY KEY,
    versionedTemplateId INT NOT NULL,
    sectionId INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    introduction MEDIUMTEXT,
    displayOrder INT NOT NULL,
    bestPractice BOOLEAN NOT NULL DEFAULT 0,
    created TIMESTAMP NOT NULL,
    createdById INT,
    modified TIMESTAMP NOT NULL,
    modifiedById INT
  ),
  audits (
    unique_combination_of_columns(columns := (versionedTemplateId, displayOrder), blocking := false),
    not_null(columns := (versionedTemplateId, name, displayOrder, created, createdById, modified, modifiedById))
  ),
  enabled true
);

WITH never_published AS (
  SELECT tmplt.family_id, COUNT(t.id) nbr_versions
  FROM dmp.templates AS tmplt
    INNER JOIN dmp.templates AS t ON tmplt.family_id = t.family_id
  WHERE tmplt.version = 0 AND tmplt.published = 0
  GROUP BY tmplt.id, tmplt.family_id
  HAVING nbr_versions = 1
)

WITH unpublished_currents AS (
  SELECT t.id
  FROM dmp.templates AS t
  WHERE t.published = 0
    AND t.id IN (SELECT MAX(t2.id) FROM dmp.templates AS t2 GROUP BY t2.family_id)
)

SELECT
  ROW_NUMBER() OVER (ORDER BY s.created_at ASC) AS id,
  tmplt.id AS versionedTemplateId,
  ints.new_section_id AS sectionId,
  TRIM(s.title) AS name,
  TRIM(s.description) AS introduction,
  ROW_NUMBER() OVER (
    PARTITION BY tmplt.id
    ORDER BY s.number ASC
  ) AS displayOrder,
  tmplt.bestPractice AS bestPractice,
  s.created_at AS created,
  tmplt.createdById,
  s.updated_at AS modified,
  tmplt.modifiedById
FROM dmp.sections AS s
  INNER JOIN dmp.phases AS p ON s.phase_id = p.id
    INNER JOIN dmp.templates AS t ON p.template_id = t.id
      LEFT JOIN migration.versioned_templates AS tmplt ON t.family_id = tmplt.family_id
                                                    AND tmplt.version = CONCAT('v', t.version)
  LEFT JOIN intermediate.sections ints ON s.id = ints.old_section_id
WHERE t.customization_of IS NULL
  AND t.family_id NOT IN (SELECT DISTINCT family_id FROM never_published)
  AND t.id NOT IN (SELECT id FROM unpublished_currents)
ORDER BY s.created_at ASC;
