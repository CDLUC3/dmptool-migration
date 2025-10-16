--  Target schema (table `versionedSectionTags`):
--  `id` int NOT NULL AUTO_INCREMENT,
--  `versionedSectionId` int NOT NULL,
--  `tagId` int NOT NULL,
--  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `createdById` int NOT NULL,
--  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `modifiedById` int NOT NULL,

MODEL (
  name migration.versioned_section_tags,
  kind FULL,
  columns (
    id INT UNSIGNED PRIMARY KEY,
    versionedSectionId INT NOT NULL,
    tagId INT NOT NULL,
    created TIMESTAMP NOT NULL,
    createdById INT UNSIGNED NOT NULL,
    modified TIMESTAMP NOT NULL,
    modifiedById INT UNSIGNED NOT NULL
  ),
  audits (
    -- unique_combination_of_columns(columns := (sectionId, tagId)),
    not_null(columns := (versionedSectionId, tagId, created, createdById, modified, modifiedById))
  ),
  enabled true
);

SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY tags.id) AS id,
    vs.id AS versionedSectionId,
    tags.tag_id AS tagId,
    vs.created,
    vs.createdById,
    vs.modified,
    vs.modifiedById
FROM migration.versioned_sections AS vs
  JOIN intermediate.section_tags AS tags ON tags.old_section_id = vs.old_section_id;
