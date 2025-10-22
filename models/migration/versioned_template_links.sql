-- Target schema:
--  `id` int NOT NULL AUTO_INCREMENT,
--  `versionedTemplateId` int NOT NULL,
--  `url` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `text` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `createdById` int NOT NULL,
--  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `modifiedById` int NOT NULL,
--  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,

MODEL (
  name migration.versioned_template_links,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    versionedTemplateId INT NOT NULL,
    linkType VARCHAR(10) NOT NULL DEFAULT 'FUNDER',
    url VARCHAR(255),
    text VARCHAR(255),
    createdById INT UNSIGNED NOT NULL,
    created TIMESTAMP NOT NULL,
    modifiedById INT UNSIGNED NOT NULL,
    modified TIMESTAMP NOT NULL
  ),
  audits (
    -- unique_combination_of_columns(columns := (versionedTemplateId, url, text)),
    not_null(columns := (versionedTemplateId, linkType, url, text, created, createdById, modified, modifiedById))
  ),
  enabled true
);

SELECT
  ROW_NUMBER() OVER (ORDER BY links.id ASC) AS id,
  vt.id AS versionedTemplateId,
  links.linkType,
  links.url,
  links.text,
  vt.createdById,
  vt.created,
  vt.modifiedById,
  vt.modified
FROM migration.versioned_templates AS vt
  JOIN intermediate.template_links AS links ON vt.old_template_id = links.old_template_id;
