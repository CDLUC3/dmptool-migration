--  Target schema (table `versionedSections`):
--  `id` int NOT NULL AUTO_INCREMENT,
--  `versionedTemplateId` int NOT NULL,
--  `sectionId` int NOT NULL,
--  `name` varchar(255) COLLATE utf8mb4_0900_ai_ci NOT NULL,
--  `introduction` mediumtext COLLATE utf8mb4_0900_ai_ci,
--  `requirements` mediumtext COLLATE utf8mb4_0900_ai_ci,
--  `guidance` mediumtext COLLATE utf8mb4_0900_ai_ci,
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
    old_section_id INT,
    sectionId INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    introduction MEDIUMTEXT,
    old_display_order INT NOT NULL,
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

JINJA_QUERY_BEGIN;

WITH root_sections AS (
  SELECT
    templateId,
    id AS sectionId,
    LOWER(TRIM(name)) as name,
    old_display_order,
    displayOrder
  FROM migration.sections
)

SELECT
  ROW_NUMBER() OVER (ORDER BY vs.created_at ASC) AS id,
  vt.id AS versionedTemplateId,
  vs.id AS old_section_id,
  rs.sectionId,
  TRIM(vs.title) AS name,
  TRIM(vs.description) AS introduction,
  vs.number AS old_display_order,
  ROW_NUMBER() OVER (PARTITION BY vt.id ORDER BY vs.number ASC) AS displayOrder,
  vt.bestPractice AS bestPractice,
  vs.created_at AS created,
  vt.createdById,
  vs.updated_at AS modified,
  vt.modifiedById
FROM {{ var('source_db') }}.sections AS vs
  JOIN {{ var('source_db') }}.phases AS p ON vs.phase_id = p.id
  JOIN intermediate.sections AS ints ON vs.id = ints.old_section_id
  JOIN migration.versioned_templates AS vt ON p.template_id = vt.old_template_id
    JOIN root_sections AS rs ON vt.template_id = rs.templateId
                              AND (rs.name = LOWER(TRIM(vs.title))
                                      OR (vs.number = rs.old_display_order))
ORDER BY vs.created_at ASC;

JINJA_END;
