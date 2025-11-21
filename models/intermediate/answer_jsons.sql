MODEL (
  name intermediate.answer_jsons,
  kind FULL,
  columns (
    answer_id INT UNSIGNED NOT NULL,
    json json DEFAULT NULL
  ),
  enabled true
);

JINJA_QUERY_BEGIN;

  WITH array_answers_agg AS (
    SELECT
      a.id AS answer_id,
      JSON_ARRAYAGG(COALESCE(qo.text, '')) AS answer_array
    FROM {{ var('source_db') }}.answers AS a
      JOIN {{ var('source_db') }}.questions AS q ON a.question_id = q.id
        LEFT JOIN {{ var('source_db') }}.answers_question_options AS ao ON a.id = ao.answer_id
          LEFT JOIN {{ var('source_db') }}.question_options AS qo ON ao.question_option_id = qo.id
    WHERE q.question_format_id IN (3, 4, 5, 6)
    GROUP BY a.id
  ),

  WITH answer_jsons AS (
    SELECT
      a.id AS answer_id,
      JSON_OBJECT(
        'type',
        CASE q.question_format_id
          WHEN 2 THEN 'text'
          WHEN 3 THEN 'radioButtons'
          WHEN 4 THEN 'checkBoxes'
          WHEN 5 THEN 'selectBox'
          WHEN 6 THEN 'multiselectBox'
          ELSE 'textArea'
        END,

        'answer',
        CASE q.question_format_id
          WHEN 7 THEN
            CASE
              -- Extract 'text' from JSON or use a.text if not valid JSON
              WHEN JSON_VALID(a.text) = 1 AND JSON_EXTRACT(a.text, '$.text') IS NOT NULL
                THEN JSON_UNQUOTE(JSON_EXTRACT(a.text, '$.text'))
              ELSE COALESCE(a.text, '')
            END
          -- Array-based answers (3, 4, 5, 6)
          WHEN 3 THEN aa.answer_array
          WHEN 4 THEN aa.answer_array
          WHEN 5 THEN aa.answer_array
          WHEN 6 THEN aa.answer_array
          -- Single-value answers aggregated via GROUP_CONCAT (3, 5)
          ELSE COALESCE(a.text, '') -- Default for non-text/array types (like simple textArea)
        END,

        'meta',
        JSON_OBJECT('schemaVersion', '1.0')
      ) AS json
    FROM {{ var('source_db') }}.answers AS a
      JOIN {{ var('source_db') }}.questions AS q ON a.question_id = q.id
      LEFT JOIN array_answers_agg AS aa ON a.id = aa.answer_id
  )

  SELECT
    a.id AS answer_id,
    aj.json
  FROM {{ var('source_db') }}.answers AS a
    JOIN answer_jsons AS aj ON a.id = aj.answer_id;

JINJA_END;
