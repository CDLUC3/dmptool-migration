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
    type VARCHAR(10) NOT NULL DEFAULT 'FUNDER',
    url VARCHAR(255),
    text VARCHAR(255),
    createdById INT UNSIGNED NOT NULL,
    created TIMESTAMP NOT NULL,
    modifiedById INT UNSIGNED NOT NULL,
    modified TIMESTAMP NOT NULL
  ),
  audits (
    unique_combination_of_columns(columns := (templateId, url)),
    not_null(columns := (templateId, type, url, text, created, createdById, modified, modifiedById))
  ),
  enabled true
);

SELECT
  ROW_NUMBER() OVER (ORDER BY o.id ASC, links.link_order ASC) AS id,
  tmplt.id AS templateId,
  'FUNDER' AS type,
  links.link AS url,
  links.text AS text,
  @VAR('super_admin_id') AS createdById,
  o.created_at AS created,
  @VAR('super_admin_id') AS modifiedById,
  o.updated_at AS modified
FROM dmp.templates t
  LEFT JOIN migration.templates tmplt ON t.family_id = tmplt.family_id
  JOIN JSON_TABLE(
    t.links,
    '$.funder[*]'
    COLUMNS(
      link_order FOR ORDINALITY,
      link VARCHAR(255) PATH '$.link',
      text VARCHAR(255) PATH '$.text'
    )
  ) AS links

UNION ALL

SELECT
  ROW_NUMBER() OVER (ORDER BY o.id ASC, links.link_order ASC) AS id,
  tmplt.id AS templateId,
  'SAMPLE' AS type,
  links.link AS url,
  links.text AS text,
  @VAR('super_admin_id') AS createdById,
  o.created_at AS created,
  @VAR('super_admin_id') AS modifiedById,
  o.updated_at AS modified
FROM dmp.templates t
  LEFT JOIN migration.templates tmplt ON t.family_id = tmplt.family_id
  JOIN JSON_TABLE(
    t.links,
    '$.sample_plan[*]'
    COLUMNS(
      link_order FOR ORDINALITY,
      link VARCHAR(255) PATH '$.link',
      text VARCHAR(255) PATH '$.text'
    )
  ) AS links;
