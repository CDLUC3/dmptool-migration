MODEL (
  name intermediate.related_works,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    plan_id INT UNSIGNED NOT NULL,
    work_type VARCHAR(255),
    relation_type VARCHAR(255),
    id_typ INT UNSIGNED NOT NULL,
    identifier_type VARCHAR(255),
    value VARCHAR(255),
    citation TEXT
  ),
  enabled: true
);

SELECT
  works.id,
  works.identifiable_id AS plan_id,
  CASE works.work_type
   WHEN 0 THEN 'ARTICLE'
   WHEN 2 THEN 'PREPRINT'
   WHEN 3 THEN 'SOFTWARE'
   WHEN 4 THEN 'SUPPLEMENTARY_MATERIALS'
   WHEN 5 THEN 'DATA_PAPER'
   WHEN 6 THEN 'BOOK'
   WHEN 7 THEN 'PROTOCOL'
   WHEN 8 THEN 'PRE_REGISTRATION'
   WHEN 9 THEN 'TRADITIONAL_KNOWLEDGE'
   ELSE 'DATASET'
   END AS work_type,
  'CITES' AS relation_type,
  works.identifier_type AS id_typ,
  CASE
   WHEN works.identifier_type = 3 THEN 'DOI'
   WHEN works.identifier_type = 16 AND works.value LIKE '%ark:%' THEN 'ARK'
   WHEN works.identifier_type = 16 AND works.value LIKE '%handle.net%' THEN 'HANDLE'
   WHEN works.identifier_type = 16 AND works.value NOT LIKE '%handle.net%' THEN 'URL'
   ELSE CASE WHEN works.value LIKE 'http%' THEN 'URL' ELSE 'OTHER' END
   END AS identifier_type,
  works.value,
  works.citation
FROM dmp.related_identifiers AS works
ORDER BY works.identifiable_id ASC;