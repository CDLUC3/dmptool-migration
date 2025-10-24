--  Template ID mappings
MODEL (
  name intermediate.template_mappings,
  kind FULL,
  columns (
    old_family_id INT,
    old_template_id INT NOT NULL,
    new_template_id INT,
    new_versioned_template_id INT
  ),
  enabled: true
);

SELECT
  t.family_id AS old_family_id,
  t.id AS old_template_id,
  nt.id AS new_template_id,
  nvt.id AS new_versioned_template_id
FROM source_db.templates t
  LEFT JOIN migration.templates nt ON t.id = nt.old_template_id
  LEFT JOIN migration.versioned_templates nvt ON t.id = nvt.old_template_id;
