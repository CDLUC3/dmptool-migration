--  Section ID mappings
MODEL (
  name intermediate.section_mappings,
  kind FULL,
  columns (
    old_template_id INT NOT NULL,
    new_template_id INT,
    new_versioned_template_id INT,
    old_section_id INT NOT NULL,
    new_section_id INT,
    new_versioned_section_id INT
  ),
  enabled: true
);

JINJA_QUERY_BEGIN;

SELECT
  p.template_id AS old_template_id,
  nt.id AS new_template_id,
  nvt.id AS new_versioned_template_id,
  s.id AS old_section_id,
  ns.id AS new_section_id,
  nvs.id AS new_versioned_section_id
FROM {{ var('source_db') }}.sections s
  INNER JOIN {{ var('source_db') }}.phases p ON s.phase_id = p.id
  LEFT JOIN migration.templates nt ON p.template_id = nt.old_template_id
  LEFT JOIN migration.versioned_templates nvt ON p.template_id = nvt.old_template_id
  LEFT JOIN migration.sections ns ON s.id = ns.old_section_id
  LEFT JOIN migration.versioned_sections nvs ON s.id = nvs.old_section_id;

JINJA_END;
