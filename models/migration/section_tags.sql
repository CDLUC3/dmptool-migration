--  Target schema (table `sectionTags`):
--  `id` int NOT NULL AUTO_INCREMENT,
--  `sectionId` int NOT NULL,
--  `tagId` int NOT NULL,
--  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `createdById` int NOT NULL,
--  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `modifiedById` int NOT NULL,

MODEL (
  name migration.section_tags,
  kind FULL,
  columns (
    id INT UNSIGNED PRIMARY KEY,
    sectionId INT NOT NULL,
    tagId INT NOT NULL,
    created DATETIME NOT NULL,
    createdById INT UNSIGNED NOT NULL,
    modified DATETIME NOT NULL,
    modifiedById INT UNSIGNED NOT NULL
  ),
  audits (
    -- unique_combination_of_columns(columns := (sectionId, tagId)),
    not_null(columns := (sectionId, tagId, created, createdById, modified, modifiedById))
  ),
  enabled true
);

SELECT DISTINCT
  ROW_NUMBER() OVER (ORDER BY s.id) AS id,
  s.id AS sectionId,
  ints.tag_id AS tagId,
  s.created,
  s.createdById,
  s.modified,
  s.modifiedById
FROM migration.sections AS s
  JOIN intermediate.section_tags AS ints ON s.old_section_id = ints.old_section_id;
