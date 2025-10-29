MODEL (
  name migration.related_works,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    plan_id INT UNSIGNED NOT NULL,
    identifier_type VARCHAR(255) NOT NULL,
    value VARCHAR(255),
    is_valid TINYINT(1) NOT NULL DEFAULT 0,
    old_identifier_type VARCHAR(255),
    old_value VARCHAR(255)
  ),
  enabled: true
);

WITH related_works_processed AS (
  SELECT
    rw.id,
    rw.plan_id,
    REGEXP_SUBSTR(LOWER(TRIM(rw.value)), '(10\\.[0-9]+/.*)', 1, 1) AS value,
    CASE
      WHEN REGEXP_SUBSTR(LOWER(TRIM(rw.value)), '(10\\.[0-9]+/.*)', 1, 1) IS NOT NULL THEN 'DOI'
      ELSE NULL
    END AS identifier_type,
    rw.value AS old_value,
    rw.identifier_type AS old_identifier_type
  FROM intermediate.related_works rw
)

SELECT
  rwp.id,
  rwp.plan_id,
  COALESCE(rws.identifier_type, rwp.identifier_type) AS identifier_type,
  COALESCE(rws.value, rwp.value) AS value,
  CASE
    WHEN COALESCE(rws.value, rwp.value) IS NOT NULL THEN 1
    ELSE 0
  END AS is_valid,
  rwp.old_value,
  rwp.old_identifier_type
FROM related_works_processed rwp
LEFT JOIN seeds.related_works AS rws ON rwp.id = rws.id
ORDER BY rwp.plan_id DESC, rwp.id DESC;