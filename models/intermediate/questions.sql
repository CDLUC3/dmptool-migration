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

JINJA_QUERY_BEGIN;

SELECT
  s.old_template_id,
  s.old_section_id,
  q.id AS old_question_id,
  q.created_at AS old_created_at,
  s.publishable
FROM {{ var('source_db') }}.questions q
  JOIN intermediate.sections s ON q.section_id = s.old_section_id;

JINJA_END;
