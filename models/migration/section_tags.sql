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
    created TIMESTAMP NOT NULL,
    createdById INT UNSIGNED NOT NULL,
    modified TIMESTAMP NOT NULL,
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
  ints.new_section_id AS sectionId,
  ints.tag_id AS tagId,
  sec.created,
  sec.createdById,
  sec.modified,
  sec.modifiedById
FROM dmp.sections AS s
  JOIN intermediate.section_tags AS ints ON s.id = ints.old_section_id
  JOIN migration.sections AS sec ON ints.new_section_id = sec.id;
