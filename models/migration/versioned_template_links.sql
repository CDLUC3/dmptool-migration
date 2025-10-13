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
  ROW_NUMBER() OVER (ORDER BY t.id ASC, links.link_order ASC) AS id,
  tmplt.id AS versionedTemplateId,
  'FUNDER' AS linkType,
  links.link AS url,
  CASE WHEN links.text IS NULL OR links.text = '' THEN links.link ELSE links.text END AS text,
  @VAR('super_admin_id') AS createdById,
  t.created_at AS created,
  @VAR('super_admin_id') AS modifiedById,
  t.updated_at AS modified
FROM dmp.templates t
  LEFT JOIN migration.versioned_templates tmplt
    ON t.family_id = tmplt.family_id AND CONCAT('v', t.version) = tmplt.version
  JOIN JSON_TABLE(
    t.links,
    '$.funder[*]'
    COLUMNS(
      link_order FOR ORDINALITY,
      link VARCHAR(255) PATH '$.link',
      text VARCHAR(255) PATH '$.text'
    )
  ) AS links
WHERE t.customization_of IS NULL AND tmplt.id IS NOT NULL

UNION ALL

SELECT
  ROW_NUMBER() OVER (ORDER BY t.id ASC, links.link_order ASC) AS id,
  tmplt.id AS versionedTemplateId,
  'SAMPLE' AS linkType,
  links.link AS url,
  CASE WHEN links.text IS NULL OR links.text = '' THEN links.link ELSE links.text END AS text,
  @VAR('super_admin_id') AS createdById,
  t.created_at AS created,
  @VAR('super_admin_id') AS modifiedById,
  t.updated_at AS modified
FROM dmp.templates t
  LEFT JOIN migration.versioned_templates tmplt
    ON t.family_id = tmplt.family_id AND CONCAT('v', t.version) = tmplt.version
  JOIN JSON_TABLE(
    t.links,
    '$.sample_plan[*]'
    COLUMNS(
      link_order FOR ORDINALITY,
      link VARCHAR(255) PATH '$.link',
      text VARCHAR(255) PATH '$.text'
    )
  ) AS links
WHERE t.customization_of IS NULL AND tmplt.id IS NOT NULL;
