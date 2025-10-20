--  Question ID mappings
MODEL (
  name intermediate.question_mappings,
  kind FULL,
  columns (
    old_section_id INT NOT NULL,
    new_section_id INT,
    new_versioned_section_id INT,
    old_question_id INT NOT NULL,
    new_question_id INT,
    new_versioned_question_id INT
  ),
  enabled: true
);

SELECT
    q.section_id AS old_section_id,
    ns.id AS new_section_id,
    nvs.id AS new_versioned_section_id,
    q.id AS old_question_id,
    nq.id AS new_question_id,
    nvq.id AS new_versioned_question_id
FROM dmp.questions q
  LEFT JOIN migration.sections ns ON q.section_id = ns.old_section_id
  LEFT JOIN migration.versioned_sections nvs ON q.section_id = nvs.old_section_id
  LEFT JOIN migration.questions nq ON q.id = nq.old_question_id
  LEFT JOIN migration.versioned_questions nvq ON q.id = nvq.old_question_id;
