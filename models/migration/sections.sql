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
    templateId INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    introduction MEDIUMTEXT,
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
  tmplt.id AS templateId,
  TRIM(s.title) AS name,
  TRIM(s.description) AS introduction,
  ROW_NUMBER() OVER (
    PARTITION BY tmplt.id
    ORDER BY s.number ASC
  ) AS displayOrder,
  tmplt.bestPractice AS bestPractice,
  tmplt.isDirty AS isDirty,
  s.created_at AS created,
  tmplt.createdById,
  s.updated_at AS modified,
  tmplt.modifiedById
FROM dmp.sections AS s
  INNER JOIN dmp.phases AS p ON s.phase_id = p.id
    INNER JOIN dmp.templates AS t ON p.template_id = t.id
      LEFT JOIN migration.templates AS tmplt ON t.family_id = tmplt.family_id
WHERE t.customization_of IS NULL
  AND t.id = (SELECT MAX(temp.id) FROM dmp.templates AS temp WHERE temp.family_id = t.family_id)
ORDER BY s.created_at ASC;

-- Reconciliation queries:
-- SELECT COUNT(id) from migration.sections; #2,366
--
-- SELECT COUNT(DISTINCT s.id)
-- FROM dmp.templates t INNER JOIN dmp.phases p ON t.id = p.template_id INNER JOIN dmp.sections s ON p.id = s.phase_id
-- WHERE t.customization_of IS NULL
--   AND t.id = (SELECT MAX(tmplt.id) FROM dmp.templates AS tmplt WHERE tmplt.family_id = t.family_id); #2,366