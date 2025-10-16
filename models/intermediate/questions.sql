--  This model matches questions from the old system to the new system based on their order
--  and/or text within sections.
MODEL (
  name intermediate.questions,
  kind FULL,
  columns (
    old_template_id INT,
    old_section_id INT,
    old_question_id INT,
    old_created_at DATETIME,
    publishable BOOLEAN
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

)

SELECT
  s.old_template_id,
  s.old_section_id,
  q.id AS old_question_id,
  q.created_at AS old_created_at,
  s.publishable
FROM dmp.questions q
  JOIN intermediate.sections s ON q.section_id = s.old_section_id;
