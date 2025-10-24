--  This model matches sections from the old system to the new system based on their order
--  within templates.
MODEL (
  name intermediate.sections,
  kind FULL,
  columns (
    old_template_id INT,
    old_section_id INT,
    old_created_at DATETIME,
    publishable BOOLEAN
  )
);

SELECT
  t.id AS old_template_id,
  s.id AS old_section_id,
  s.created_at AS old_created_at,
  CASE WHEN it.is_published = 1 OR it.was_published = 1 THEN TRUE ELSE FALSE END AS publishable
FROM source_db.sections s
  JOIN source_db.phases p ON s.phase_id = p.id
    JOIN source_db.templates t ON p.template_id = t.id
      LEFT JOIN intermediate.templates it ON t.id = it.old_template_id;
