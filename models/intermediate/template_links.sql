
MODEL (
  name intermediate.template_links,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    old_template_id INT,
    linkType VARCHAR(10) NOT NULL DEFAULT 'FUNDER',
    url VARCHAR(255),
    text VARCHAR(255)
  ),
  audits (
    not_null(columns := (old_template_id, linkType, url, text))
  ),
  enabled true
);

SELECT
  ROW_NUMBER() OVER (ORDER BY t.id ASC, links.link_order ASC) AS id,
  t.id AS old_template_id,
  'FUNDER' AS linkType,
  TRIM(links.link) AS url,
  CASE WHEN links.text IS NULL OR TRIM(links.text) = '' THEN TRIM(links.link) ELSE TRIM(links.text) END AS text
FROM dmp.templates t
  JOIN JSON_TABLE(
    t.links,
    '$.funder[*]'
    COLUMNS(
      link_order FOR ORDINALITY,
      link VARCHAR(255) PATH '$.link',
      text VARCHAR(255) PATH '$.text'
    )
  ) AS links
WHERE t.customization_of IS NULL

UNION ALL

SELECT
  ROW_NUMBER() OVER (ORDER BY t.id ASC, links.link_order ASC) AS id,
  t.id AS old_template_id,
  'SAMPLE_PLAN' AS linkType,
  TRIM(links.link) AS url,
  CASE WHEN links.text IS NULL OR TRIM(links.text) = '' THEN TRIM(links.link) ELSE TRIM(links.text) END AS text
FROM dmp.templates t
  JOIN JSON_TABLE(
    t.links,
    '$.sample_plan[*]'
    COLUMNS(
      link_order FOR ORDINALITY,
      link VARCHAR(255) PATH '$.link',
      text VARCHAR(255) PATH '$.text'
    )
  ) AS links
WHERE t.customization_of IS NULL;
