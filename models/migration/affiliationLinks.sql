-- Target schema:
--  `id` int NOT NULL AUTO_INCREMENT,
--  `affiliationId` int NOT NULL,
--  `url` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `text` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `createdById` int NOT NULL,
--  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `modifiedById` int NOT NULL,
--  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,

MODEL (
  name migration.affiliation_links,
  kind FULL,
  columns (
    id INT NOT NULL,
    affiliationId INT NOT NULL,
    url VARCHAR(255),
    text VARCHAR(255),
    createdById INT NOT NULL,
    created TIMESTAMP NOT NULL,
    modifiedById INT NOT NULL,
    modified TIMESTAMP NOT NULL
  ),
  audits (
    unique_values(columns := (id), blocking := false)
  ),
  enabled true
);

SELECT
  ROW_NUMBER() OVER (ORDER BY o.id ASC, links.link_order ASC) AS id,
  o.id AS affiliationId,
  links.link AS url,
  links.text AS text,
  @VAR('super_admin_id') AS createdById,
  o.created_at AS created,
  @VAR('super_admin_id') AS modifiedById,
  o.updated_at AS modified
FROM dmp.orgs o,
JSON_TABLE(
  o.links,
  '$.org[*]'
  COLUMNS(
    link_order FOR ORDINALITY,
    link VARCHAR(255) PATH '$.link',
    text VARCHAR(255) PATH '$.text'
  )
) AS links
