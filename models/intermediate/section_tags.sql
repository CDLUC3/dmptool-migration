MODEL (
  name intermediate.section_tags,
  kind FULL,
  columns (
    id INT PRIMARY KEY,
    old_section_id INT,
    tag_id INT
  ),
  enabled true
);

SELECT DISTINCT
  ROW_NUMBER() OVER (ORDER BY s.id ASC) AS id,
  ints.old_section_id,
  tags.id AS tag_id
FROM source_db.sections s
  JOIN intermediate.sections AS ints ON s.id = ints.old_section_id
  LEFT JOIN source_db.questions AS q ON s.id = q.section_id
    LEFT JOIN source_db.questions_themes AS qt ON q.id = qt.question_id
      LEFT JOIN source_db.themes AS th ON qt.theme_id = th.id
        LEFT JOIN migration.tags AS tags ON LOWER(REPLACE(th.title, ' ', '-')) = tags.slug
WHERE tags.id IS NOT NULL;
