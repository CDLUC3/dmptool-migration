-- Target schema:
--  `id` int NOT NULL AUTO_INCREMENT,
--  `affiliationId` int NOT NULL,
--  `url` varchar(255) COLLATE utf8mb4_0900_ai_ci NOT NULL,
--  `text` varchar(255) COLLATE utf8mb4_0900_ai_ci NOT NULL,
--  `createdById` int NOT NULL,
--  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `modifiedById` int NOT NULL,
--  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,

MODEL (
  name migration.affiliation_links,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    affiliationId VARCHAR(255) NOT NULL,
    url VARCHAR(255),
    text VARCHAR(255),
    createdById INT UNSIGNED NOT NULL,
    created TIMESTAMP NOT NULL,
    modifiedById INT UNSIGNED NOT NULL,
    modified TIMESTAMP NOT NULL
  ),
  audits (
    unique_values(columns := (id), blocking := false)
  ),
  enabled true
);

JINJA_QUERY_BEGIN;

WITH default_super_admin AS (
  SELECT id
  FROM intermediate.users
  WHERE role = 'SUPERADMIN'
  ORDER BY id DESC LIMIT 1
)

SELECT
  ROW_NUMBER() OVER (ORDER BY o.id ASC, links.link_order ASC) AS id,
  CASE
    WHEN ro.org_id IS NULL THEN CONCAT('https://dmptool.org/affiliations/', o.id)
    ELSE ro.ror_id
  END AS affiliationId,
  TRIM(links.link) AS url,
  TRIM(links.text) AS text,
  (SELECT id FROM default_super_admin) AS createdById,
  o.created_at AS created,
  (SELECT id FROM default_super_admin) AS modifiedById,
  o.updated_at AS modified
FROM {{ var('source_db') }}.orgs o
LEFT JOIN {{ var('source_db') }}.registry_orgs ro ON o.id = ro.org_id
JOIN JSON_TABLE(
  o.links,
  '$.org[*]'
  COLUMNS(
    link_order FOR ORDINALITY,
    link VARCHAR(255) PATH '$.link',
    text VARCHAR(255) PATH '$.text'
  )
) AS links;

JINJA_END;
