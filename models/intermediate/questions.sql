--  This model matches questions from the old system to the new system based on their order
--  and/or text within sections.
MODEL (
  name intermediate.questions,
  kind FULL,
  columns (
    old_section_id INT,
    new_section_id INT,
    old_question_id INT,
    old_created_at DATETIME,
    new_question_id INT,
    publishable BOOLEAN,
    matchConfidence DECIMAL(3,2),
    unmatchedFlag BOOLEAN
  )
);

WITH ordered_old AS (
  SELECT
    s.id AS old_section_id,
    q.id AS old_question_id,
    q.created_at AS old_created_at,
    LOWER(TRIM(q.text)) AS text,
    t.family_id AS family_id,
    ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY q.number) AS order_rank
  FROM dmp.questions q
    JOIN dmp.sections s ON q.section_id = s.id
      JOIN dmp.phases p ON s.phase_id = p.id
        JOIN dmp.templates t ON p.template_id = t.id
),

ordered_new AS (
  SELECT
    s.id AS new_section_id,
    q.id AS new_question_id,
    LOWER(TRIM(q.questionText)) AS text,
    t.family_id AS family_id,
    it.publishable AS publishable,
    ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY q.displayOrder) AS order_rank
  FROM migration.questions q
    JOIN migration.sections s ON q.sectionId = s.id
      JOIN intermediate.sections it ON s.id = it.new_section_id
      JOIN migration.templates t ON s.templateId = t.id
)

SELECT
  o.old_section_id,
  n.new_section_id,
  o.old_question_id,
  o.old_created_at,
  n.new_question_id,
  n.publishable,
  CASE
    WHEN n.new_question_id IS NOT NULL THEN 0.8
    ELSE 0.0
  END AS matchConfidence,
  CASE
    WHEN n.new_question_id IS NULL THEN TRUE
    ELSE FALSE
  END AS unmatchedFlag
FROM ordered_old o
  LEFT JOIN ordered_new n
    ON o.family_id = n.family_id AND (o.order_rank = n.order_rank OR o.text = n.text);
