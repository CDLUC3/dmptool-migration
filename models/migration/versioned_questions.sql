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
    old_question_id INT,
    versionedTemplateId INT NOT NULL,
    versionedSectionId INT NOT NULL,
    questionId INT NOT NULL,
    questionText MEDIUMTEXT NOT NULL,
    json JSON,
    guidanceText MEDIUMTEXT NOT NULL,
    sampleText MEDIUMTEXT NOT NULL,
    old_display_order INT NOT NULL,
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

WITH root_questions AS (
  SELECT
    sectionId,
    id AS questionId,
    LOWER(TRIM(questionText)) as text,
    old_display_order,
    displayOrder
  FROM migration.questions
)

SELECT
    ROW_NUMBER() OVER (ORDER BY vq.created_at ASC) AS id,
    vs.versionedTemplateId AS versionedTemplateId,
    vq.id AS old_question_id,
    vs.id AS versionedSectionId,
    rq.questionId AS questionId,
    TRIM(vq.text) AS questionText,
    (SELECT GROUP_CONCAT(TRIM(a.text) SEPARATOR '<br>')
     FROM dmp.annotations a
     WHERE a.question_id = vq.id AND a.org_id = intt.old_org_id AND a.type = 0
    ) AS sampleText,
    (SELECT GROUP_CONCAT(TRIM(a.text) SEPARATOR '<br>')
     FROM dmp.annotations a
     WHERE a.question_id = vq.id AND a.org_id = intt.old_org_id AND a.type = 1
    ) AS guidanceText,
    CASE vq.question_format_id
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
    vq.number AS old_display_order,
    ROW_NUMBER() OVER (PARTITION BY vs.id ORDER BY vq.number ASC) AS displayOrder,
    vq.created_at AS created,
    vs.createdById,
    vq.updated_at AS modified,
    vs.modifiedById
FROM dmp.questions AS vq
  LEFT JOIN dmp.question_options AS qo ON vq.id = qo.question_id
  JOIN intermediate.questions AS intq ON vq.id = intq.old_question_id
    JOIN intermediate.sections AS ints ON ints.old_section_id = intq.old_section_id
      JOIN intermediate.templates AS intt ON ints.old_template_id = intt.old_template_id
      JOIN migration.versioned_sections AS vs ON ints.old_section_id = vs.old_section_id
        JOIN root_questions AS rq ON vs.sectionId = rq.sectionId
                                    AND (rq.text = LOWER(TRIM(vq.text))
                                          OR (vq.number = rq.old_display_order))
GROUP BY vq.created_at, vs.versionedTemplateId, vq.id, vs.id, rq.questionId, vq.text,
         vq.number, intt.old_org_id, vq.question_format_id,
         vs.createdById, vs.modifiedById, vq.updated_at
ORDER BY vq.created_at ASC;
