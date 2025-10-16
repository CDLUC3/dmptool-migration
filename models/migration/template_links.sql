-- Target schema:
--  `id` int NOT NULL AUTO_INCREMENT,
--  `templateId` int NOT NULL,
--  `url` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `text` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `createdById` int NOT NULL,
--  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `modifiedById` int NOT NULL,
--  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,

MODEL (
  name migration.template_links,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    templateId INT NOT NULL,
    linkType VARCHAR(10) NOT NULL DEFAULT 'FUNDER',
    url VARCHAR(255),
    text VARCHAR(255),
    createdById INT UNSIGNED NOT NULL,
    created TIMESTAMP NOT NULL,
    modifiedById INT UNSIGNED NOT NULL,
    modified TIMESTAMP NOT NULL
  ),
  audits (
    -- unique_combination_of_columns(columns := (templateId, url, text)),
    not_null(columns := (templateId, linkType, url, text, created, createdById, modified, modifiedById))
  ),
  enabled true
);

SELECT
  ROW_NUMBER() OVER (ORDER BY links.id ASC) AS id,
  tmplt.id AS templateId,
  links.linkType,
  links.url,
  links.text,
  tmplt.createdById,
  tmplt.created,
  tmplt.modifiedById,
  tmplt.modified
FROM migration.templates AS tmplt
  JOIN intermediate.template_links AS links ON tmplt.id = links.new_template_id;
