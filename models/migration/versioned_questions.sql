--  Target schema (table `versionedQuestions`):
--  `id` int NOT NULL AUTO_INCREMENT,
--  `versionedTemplateId` int NOT NULL,
--  `versionedSectionId` int NOT NULL,
--  `questionId` int NOT NULL,
--  `questionText` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
--  `json` json DEFAULT NULL,
--  `requirementText` mediumtext COLLATE utf8mb4_unicode_ci,
--  `guidanceText` mediumtext COLLATE utf8mb4_unicode_ci,
--  `sampleText` mediumtext COLLATE utf8mb4_unicode_ci,
--  `required` tinyint(1) NOT NULL DEFAULT '0',
--  `displayOrder` int NOT NULL,
--  `useSampleTextAsDefault` tinyint(1) NOT NULL DEFAULT '0',
--  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `createdById` int NOT NULL,
--  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `modifiedById` int NOT NULL,

MODEL (
  name migration.versioned_questions,
  kind FULL,
  columns (
    id INT UNSIGNED PRIMARY KEY,
    versionedTemplateId INT NOT NULL,
    versionedSectionId INT NOT NULL,
    questionId INT NOT NULL,
    questionText MEDIUMTEXT NOT NULL,
    json JSON,
    guidanceText MEDIUMTEXT NOT NULL,
    sampleText MEDIUMTEXT NOT NULL,
    displayOrder INT NOT NULL,
    created TIMESTAMP NOT NULL,
    createdById INT,
    modified TIMESTAMP NOT NULL,
    modifiedById INT
  ),
  audits (
    unique_combination_of_columns(columns := (versionedSectionId, displayOrder), blocking := false),
    -- not_null(columns := (versionedTemplateId, versionedSectionId, questionText, displayOrder, created, createdById, modified, modifiedById))
  ),
  enabled true
);

-- Some JSON is really big because the options are wordy for some option based question types
-- so we temporarily increase the group concat limit
SET SESSION group_concat_max_len = 1048576;

SELECT
    ROW_NUMBER() OVER (ORDER BY q.created_at ASC) AS id,
    s.versionedTemplateId AS versionedTemplateId,
    s.id AS versionedSectionId,
    iq.new_question_id AS questionId,
    TRIM(q.text) AS questionText,
    (SELECT GROUP_CONCAT(TRIM(a.text) SEPARATOR '<br>')
     FROM dmp.annotations a
     WHERE a.question_id = q.id AND a.org_id = torg.org_id AND a.type = 0
    ) AS sampleText,
    (SELECT GROUP_CONCAT(TRIM(a.text) SEPARATOR '<br>')
     FROM dmp.annotations a
     WHERE a.question_id = q.id AND a.org_id = torg.org_id AND a.type = 1
    ) AS guidanceText,
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
    ROW_NUMBER() OVER (
      PARTITION BY it.new_template_id, s.id
      ORDER BY q.number ASC
    ) AS displayOrder,
    q.created_at AS created,
    s.createdById,
    q.updated_at AS modified,
    s.modifiedById
FROM dmp.questions AS q
  LEFT JOIN dmp.question_formats AS qf ON q.question_format_id = qf.id
  LEFT JOIN dmp.question_options AS qo ON q.id = qo.question_id
  INNER JOIN intermediate.questions AS iq ON q.id = iq.new_question_id
                                            AND q.section_id = iq.old_section_id
    INNER JOIN intermediate.sections AS intq ON iq.new_section_id = intq.new_section_id
      INNER JOIN migration.versioned_sections AS s ON intq.new_section_id = s.id
      INNER JOIN intermediate.templates AS it ON intq.new_template_id = it.new_template_id
        INNER JOIN dmp.templates torg ON it.old_template_id = torg.id
WHERE intq.publishable
GROUP BY q.id, q.number, q.text, q.question_format_id, q.created_at, q.updated_at,
         s.versionedTemplateId, s.createdById, s.modifiedById, s.id, torg.org_id,
         iq.new_question_id
ORDER BY q.created_at ASC;
