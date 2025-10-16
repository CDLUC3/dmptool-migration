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
WHERE t.customization_of IS NULL AND ints.publishable
GROUP BY tmplt.id, ints.new_section_id, s.title, s.description, s.number, tmplt.bestPractice,
  s.created_at, tmplt.createdById, s.updated_at, tmplt.modifiedById
ORDER BY s.created_at ASC;

-- Reconciliation queries:
-- SELECT COUNT(id) from migration.versioned_sections; #6,862
--
-- SELECT COUNT(DISTINCT s.id) FROM dmp.templates t INNER JOIN dmp.phases p ON t.id = p.template_id
-- 	INNER JOIN dmp.sections s ON p.id = s.phase_id WHERE t.customization_of IS NULL AND (t.published = 1
--   OR t.id != (SELECT MAX(tmplt.id) FROM dmp.templates AS tmplt WHERE tmplt.family_id = t.family_id)); #6,261