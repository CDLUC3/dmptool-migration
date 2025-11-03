--  Target schema (table `questions`):
--  `id` int NOT NULL AUTO_INCREMENT,
--  `templateId` int NOT NULL,
--  `sectionId` int NOT NULL,
--  `sourceQuestionId` int DEFAULT NULL,
--  `displayOrder` int NOT NULL,
--  `isDirty` tinyint(1) NOT NULL DEFAULT '1',
--  `questionText` mediumtext COLLATE utf8mb4_0900_ai_ci NOT NULL,
--  `json` json DEFAULT NULL,
--  `requirementText` mediumtext COLLATE utf8mb4_0900_ai_ci,
--  `guidanceText` mediumtext COLLATE utf8mb4_0900_ai_ci,
--  `sampleText` mediumtext COLLATE utf8mb4_0900_ai_ci,
--  `useSampleTextAsDefault` tinyint(1) NOT NULL DEFAULT '0',
--  `required` tinyint(1) NOT NULL DEFAULT '0',
--  `createdById` int NOT NULL,
--  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `modifiedById` int NOT NULL,
--  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP

MODEL (
  name migration.questions,
  kind FULL,
  columns (
    id INT UNSIGNED PRIMARY KEY,
    old_question_id INT,
    templateId INT NOT NULL,
    sectionId INT NOT NULL,
    questionText MEDIUMTEXT NOT NULL,
    json JSON,
    sampleText MEDIUMTEXT,
    guidanceText MEDIUMTEXT,
    old_display_order INT,
    displayOrder INT NOT NULL,
    isDirty BOOLEAN NOT NULL DEFAULT 1,
    created TIMESTAMP NOT NULL,
    createdById INT,
    modified TIMESTAMP NOT NULL,
    modifiedById INT
  ),
  audits (
    unique_combination_of_columns(columns := (templateId, sectionId, displayOrder), blocking := false),
    not_null(columns := (templateId, sectionId, questionText, displayOrder, created, createdById, modified, modifiedById))
  ),
  enabled true
);

-- Some JSON is really big because the options are wordy for some option based question types
-- so we temporarily increase the group concat limit
SET SESSION group_concat_max_len = 1048576;

JINJA_QUERY_BEGIN;

SELECT
  ROW_NUMBER() OVER (ORDER BY q.id ASC) AS id,
  q.id AS old_question_id,
  t.id AS templateId,
  s.id AS sectionId,
  TRIM(q.text) AS questionText,
  (SELECT GROUP_CONCAT(TRIM(a.text) SEPARATOR '<br>')
   FROM {{ var('source_db') }}.annotations a
   WHERE a.question_id = q.id AND a.org_id = intt.old_org_id AND a.type = 0
  ) AS sampleText,
  (SELECT GROUP_CONCAT(TRIM(a.text) SEPARATOR '<br>')
   FROM {{ var('source_db') }}.annotations a
   WHERE a.question_id = q.id AND a.org_id = intt.old_org_id AND a.type = 1
  ) AS guidanceText,
  q.number AS old_display_order,
  ROW_NUMBER() OVER (PARTITION BY s.old_section_id ORDER BY q.number ASC) AS displayOrder,
  t.isDirty AS isDirty,
  CASE q.question_format_id
    WHEN 2 THEN
      '{"type":"text","attributes":{"pattern":"^.+$","maxLength":1000,"minLength":0},"meta":{"schemaVersion":"1.0"}}'
    WHEN 3 THEN
      CONCAT(
        '{"type":"radioButtons","options":[',
        GROUP_CONCAT(
          '{"label":"',
          REPLACE(qo.text, '"', '\"'),
          '","value":"',
          REPLACE(qo.text, '"', '\"'),
          '","selected":',
          CASE WHEN qo.is_default = 1 THEN true ELSE false END,
          '}'
        ORDER BY qo.number),
        '],"meta":{"schemaVersion":"1.0"}}'
      )
    WHEN 4 THEN
      CONCAT(
        '{"type":"checkBoxes","options":[',
        GROUP_CONCAT(
          '{"label":"',
          REPLACE(qo.text, '"', '\"'),
          '","value":"',
          REPLACE(qo.text, '"', '\"'),
          '","checked":',
          CASE WHEN qo.is_default = 1 THEN true ELSE false END,
          '}'
        ORDER BY qo.number),
        '],"meta":{"schemaVersion":"1.0"}}'
      )
    WHEN 5 THEN
      CONCAT(
        '{"type":"selectBox","attributes":{"multiple":0},"options":[',
        GROUP_CONCAT(
          '{"label":"',
          REPLACE(qo.text, '"', '\"'),
          '","value":"',
          REPLACE(qo.text, '"', '\"'),
          '","selected":',
          CASE WHEN qo.is_default = 1 THEN true ELSE false END,
          '}'
        ORDER BY qo.number),
        '],"meta":{"schemaVersion":"1.0"}}'
      )
    WHEN 6 THEN
      CONCAT(
        '{"type":"multiselectBox","attributes":{"multiple":1},"options":[',
        GROUP_CONCAT(
          '{"label":"',
          REPLACE(qo.text, '"', '\"'),
          '","value":"',
          REPLACE(qo.text, '"', '\"'),
          '","selected":',
          CASE WHEN qo.is_default = 1 THEN true ELSE false END,
          '}'
        ORDER BY qo.number),
        '],"meta":{"schemaVersion":"1.0"}}'
      )
    ELSE
      '{"type":"textArea","attributes":{"cols":20,"rows":2,"asRichText":true},"meta":{"schemaVersion":"1.0"}}'
  END AS json,
  t.createdById,
  q.created_at AS created,
  t.modifiedById,
  q.updated_at AS modified
FROM {{ var('source_db') }}.questions AS q
  LEFT JOIN {{ var('source_db') }}.question_options AS qo ON q.id = qo.question_id
  JOIN intermediate.questions AS intq ON q.id = intq.old_question_id
    JOIN intermediate.sections AS ints ON intq.old_section_id = ints.old_section_id
      JOIN migration.sections AS s ON ints.old_section_id = s.old_section_id
      JOIN intermediate.templates AS intt ON intt.old_template_id = ints.old_template_id
        JOIN migration.templates AS t ON intt.old_template_id = t.old_template_id
GROUP BY q.id, t.id, s.id, s.old_section_id, q.text, q.number,
         intt.old_org_id, t.isDirty, q.question_format_id,
         t.createdById, t.modifiedById, q.created_at, q.updated_at
ORDER BY q.created_at ASC;

JINJA_END;
