--  Target schema (table `questions`):
--  `id` int NOT NULL AUTO_INCREMENT,
--  `templateId` int NOT NULL,
--  `sectionId` int NOT NULL,
--  `sourceQuestionId` int DEFAULT NULL,
--  `displayOrder` int NOT NULL,
--  `isDirty` tinyint(1) NOT NULL DEFAULT '1',
--  `questionText` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
--  `json` json DEFAULT NULL,
--  `requirementText` mediumtext COLLATE utf8mb4_unicode_ci,
--  `guidanceText` mediumtext COLLATE utf8mb4_unicode_ci,
--  `sampleText` mediumtext COLLATE utf8mb4_unicode_ci,
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
    templateId INT NOT NULL,
    sectionId INT NOT NULL,
    questionText MEDIUMTEXT NOT NULL,
    json JSON,
    sampleText MEDIUMTEXT,
    guidanceText MEDIUMTEXT,
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

SELECT
  ROW_NUMBER() OVER (ORDER BY s.created_at ASC) AS id,
  t.id AS templateId,
  s.id AS sectionId,
  TRIM(q.text) AS questionText,
  (SELECT GROUP_CONCAT(TRIM(a.text) SEPARATOR '<br>')
   FROM dmp.annotations a
   WHERE a.question_id = q.id AND a.org_id = o.id AND a.type = 0
  ) AS sampleText,
  (SELECT GROUP_CONCAT(TRIM(a.text) SEPARATOR '<br>')
   FROM dmp.annotations a
   WHERE a.question_id = q.id AND a.org_id = o.id AND a.type = 1
  ) AS guidanceText,
  ROW_NUMBER() OVER (
    PARTITION BY t.id, s.id
    ORDER BY q.number ASC
  ) AS displayOrder,
  tmplt.isDirty AS isDirty,
  CASE q.question_format_id
    WHEN 2 THEN
      '{"type":"text","attributes":{"pattern":"^.+$","maxLength":1000,"minLength":0},"meta":{"schemaVersion":"1.0"}}'
    WHEN 3 THEN
      CONCAT(
        '{"type":"radioButtons","options":[',
        CONCAT(
          GROUP_CONCAT(
            CONCAT(
              '{"label":"',
              CONCAT(
                REPLACE(qo.text, '"', '\"'),
                CONCAT(
                  '","value":"',
                  CONCAT(
                    REPLACE(qo.text, '"', '\"'),
                    CONCAT(
                      '","selected":',
                      CONCAT(
                        CASE WHEN qo.is_default = 1 THEN true ELSE false END,
                        '}'
                      )
                    )
                  )
                )
              )
            )
          ORDER BY qo.number),
          '],"meta":{"schemaVersion":"1.0"}}'
        )
      )
    WHEN 4 THEN
      CONCAT(
        '{"type":"checkBoxes","options":[',
        CONCAT(
          GROUP_CONCAT(
            CONCAT(
              '{"label":"',
              CONCAT(
                REPLACE(qo.text, '"', '\"'),
                CONCAT(
                  '","value":"',
                  CONCAT(
                    REPLACE(qo.text, '"', '\"'),
                    CONCAT(
                      '","checked":',
                      CONCAT(
                        CASE WHEN qo.is_default = 1 THEN true ELSE false END,
                        '}'
                      )
                    )
                  )
                )
              )
            )
          ORDER BY qo.number),
          '],"meta":{"schemaVersion":"1.0"}}'
        )
      )
    WHEN 5 THEN
      CONCAT(
        '{"type":"selectBox","attributes":{"multiple":0},"options":[',
        CONCAT(
          GROUP_CONCAT(
            CONCAT(
              '{"label":"',
              CONCAT(
                REPLACE(qo.text, '"', '\"'),
                CONCAT(
                  '","value":"',
                  CONCAT(
                    REPLACE(qo.text, '"', '\"'),
                    CONCAT(
                      '","selected":',
                      CONCAT(
                        CASE WHEN qo.is_default = 1 THEN true ELSE false END,
                        '}'
                      )
                    )
                  )
                )
              )
            )
          ORDER BY qo.number),
          '],"meta":{"schemaVersion":"1.0"}}'
        )
      )
    WHEN 6 THEN
      CONCAT(
        '{"type":"multiselectBox","attributes":{"multiple":1},"options":[',
        CONCAT(
          GROUP_CONCAT(
            CONCAT(
              '{"label":"',
              CONCAT(
                REPLACE(qo.text, '"', '\"'),
                CONCAT(
                  '","value":"',
                  CONCAT(
                    REPLACE(qo.text, '"', '\"'),
                    CONCAT(
                      '","selected":',
                      CONCAT(
                        CASE WHEN qo.is_default = 1 THEN true ELSE false END,
                        '}'
                      )
                    )
                  )
                )
              )
            )
          ORDER BY qo.number),
          '],"meta":{"schemaVersion":"1.0"}}'
        )
      )
    ELSE
      '{"type":"textArea","attributes":{"cols":20,"rows":2,"asRichText":true},"meta":{"schemaVersion":"1.0"}}'
  END AS json,
  tmplt.createdById,
  q.created_at AS created,
  tmplt.modifiedById,
  q.updated_at AS modified
FROM dmp.questions AS q
  LEFT JOIN dmp.question_formats AS qf ON q.question_format_id = qf.id
  LEFT JOIN dmp.question_options AS qo ON q.id = qo.question_id
  INNER JOIN dmp.sections AS s ON q.section_id = s.id
    INNER JOIN dmp.phases AS p ON s.phase_id = p.id
      INNER JOIN dmp.templates AS t ON p.template_id = t.id
        INNER JOIN dmp.orgs AS o ON t.org_id = o.id
        LEFT JOIN migration.templates AS tmplt ON t.family_id = tmplt.family_id
WHERE t.customization_of IS NULL
  AND t.id = (SELECT MAX(t2.id) FROM dmp.templates AS t2 WHERE t.family_id = t2.family_id)
GROUP BY t.family_id, t.version, s.id, q.id, q.number,
         q.text, q.question_format_id, q.created_at, q.updated_at,
         tmplt.createdById, tmplt.modifiedById;
