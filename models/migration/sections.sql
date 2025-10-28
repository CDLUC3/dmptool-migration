--  Target schema (table `sections`):
--  `id` int NOT NULL AUTO_INCREMENT,
--  `templateId` int NOT NULL,
--  `sourceSectionId` int DEFAULT NULL,
--  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `introduction` mediumtext COLLATE utf8mb4_unicode_ci,
--  `requirements` mediumtext COLLATE utf8mb4_unicode_ci,
--  `guidance` mediumtext COLLATE utf8mb4_unicode_ci,
--  `displayOrder` int NOT NULL,
--  `bestPractice` tinyint(1) NOT NULL DEFAULT '0',
--  `isDirty` tinyint(1) NOT NULL DEFAULT '1',
--  `createdById` int NOT NULL,
--  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `modifiedById` int NOT NULL,
--  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP

MODEL (
  name migration.sections,
  kind FULL,
  columns (
    id INT UNSIGNED PRIMARY KEY,
    old_section_id INT,
    templateId INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    introduction MEDIUMTEXT,
    old_display_order INT,
    displayOrder INT NOT NULL,
    bestPractice BOOLEAN NOT NULL DEFAULT 0,
    isDirty BOOLEAN NOT NULL DEFAULT 1,
    created TIMESTAMP NOT NULL,
    createdById INT,
    modified TIMESTAMP NOT NULL,
    modifiedById INT
  ),
  audits (
    unique_combination_of_columns(columns := (templateId, displayOrder), blocking := false),
    not_null(columns := (templateId, name, displayOrder, created, createdById, modified, modifiedById))
  ),
  enabled true
);

SELECT
  ROW_NUMBER() OVER (ORDER BY s.created_at ASC) AS id,
  s.id AS old_section_id,
  t.id AS templateId,
  TRIM(s.title) AS name,
  TRIM(s.description) AS introduction,
  s.number AS old_display_order,
  ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY s.number ASC) AS displayOrder,
  t.bestPractice AS bestPractice,
  t.isDirty AS isDirty,
  s.created_at AS created,
  t.createdById,
  s.updated_at AS modified,
  t.modifiedById
FROM source_db.sections AS s
  JOIN intermediate.sections AS ints ON s.id = ints.old_section_id
    JOIN migration.templates AS t ON ints.old_template_id = t.old_template_id
ORDER BY s.created_at ASC;

-- Reconciliation queries:
-- SELECT COUNT(id) from migration.sections; #2,366
--
-- SELECT COUNT(DISTINCT s.id)
-- FROM source_db.templates t INNER JOIN source_db.phases p ON t.id = p.template_id INNER JOIN source_db.sections s ON p.id = s.phase_id
-- WHERE t.customization_of IS NULL
--   AND t.id = (SELECT MAX(tmplt.id) FROM source_db.templates AS tmplt WHERE tmplt.family_id = t.family_id); #2,366