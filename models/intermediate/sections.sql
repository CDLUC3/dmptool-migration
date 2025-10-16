--  This model matches sections from the old system to the new system based on their order
--  within templates.
MODEL (
  name intermediate.sections,
  kind FULL,
  columns (
    new_template_id INT,
    old_section_id INT,
    old_created_at DATETIME,
    new_section_id INT,
    publishable BOOLEAN,
    matchConfidence DECIMAL(3,2),
    unmatchedFlag BOOLEAN
  )
);

WITH ordered_old AS (
  SELECT
    s.id AS old_section_id,
    s.created_at AS old_created_at,
    LOWER(TRIM(s.title)) AS title,
    it.new_template_id AS template_id,
    CASE WHEN it.is_published = 1 OR it.was_published = 1 THEN TRUE ELSE FALSE END AS publishable,
    ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY s.number, s.number) AS order_rank
  FROM dmp.sections s
    JOIN dmp.phases p ON s.phase_id = p.id
      JOIN dmp.templates t ON p.template_id = t.id
        LEFT JOIN intermediate.templates it ON t.id = it.old_template_id
),
ordered_new AS (
  SELECT
    s.id AS new_section_id,
    LOWER(TRIM(s.name)) AS title,
    t.id AS template_id,
    ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY s.displayOrder, s.displayOrder) AS order_rank
  FROM migration.sections s
    JOIN migration.templates t ON s.templateId = t.id
)

SELECT
  o.template_id AS new_template_id,
  o.old_section_id,
  o.old_created_at,
  n.new_section_id,
  o.publishable,
  CASE
    WHEN n.new_section_id IS NOT NULL THEN 0.8
    ELSE 0.0
  END AS matchConfidence,
  CASE
    WHEN n.new_section_id IS NULL THEN TRUE
    ELSE FALSE
  END AS unmatchedFlag
FROM ordered_old o
  LEFT JOIN ordered_new n
  ON o.template_id = n.template_id AND (o.order_rank = n.order_rank OR o.title = n.title);
