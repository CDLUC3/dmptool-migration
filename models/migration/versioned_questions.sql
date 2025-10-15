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
    not_null(columns := (versionedTemplateId, versionedSectionId, questionText, displayOrder, created, createdById, modified, modifiedById))
  ),
  enabled true
);

WITH never_published AS (
    SELECT tmplt.family_id, COUNT(t.id) nbr_versions
    FROM dmp.templates AS tmplt
             INNER JOIN dmp.templates AS t ON tmplt.family_id = t.family_id
    WHERE tmplt.version = 0 AND tmplt.published = 0
    GROUP BY tmplt.id, tmplt.family_id
    HAVING nbr_versions = 1
)

WITH unpublished_currents AS (
  SELECT t.id
  FROM dmp.templates AS t
  WHERE t.published = 0
    AND t.id IN (SELECT MAX(t2.id) FROM dmp.templates AS t2 GROUP BY t2.family_id)
)

SELECT
    ROW_NUMBER() OVER (ORDER BY s.created_at ASC) AS id,
    tmplt.id AS versionedTemplateId,
    sct.id AS versionedSectionId,
    intq.new_question_id AS questionId,
    TRIM(q.text) AS questionText,
    (SELECT GROUP_CONCAT(TRIM(a.text) SEPARATOR '<br>')
     FROM dmp.annotations a
     WHERE a.question_id = q.id AND a.org_id = t.org_id AND a.type = 0
    ) AS sampleText,
    (SELECT GROUP_CONCAT(TRIM(a.text) SEPARATOR '<br>')
     FROM dmp.annotations a
     WHERE a.question_id = q.id AND a.org_id = t.org_id AND a.type = 1
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
      PARTITION BY t.id, s.id
      ORDER BY q.number ASC
    ) AS displayOrder,
    s.created_at AS created,
    tmplt.createdById,
    s.updated_at AS modified,
    tmplt.modifiedById
FROM dmp.questions AS q
  LEFT JOIN dmp.question_formats AS qf ON q.question_format_id = qf.id
  LEFT JOIN dmp.question_options AS qo ON q.id = qo.question_id
  INNER JOIN dmp.sections AS s ON q.section_id = s.id
    INNER JOIN dmp.phases AS p ON s.phase_id = p.id
      INNER JOIN dmp.templates AS t ON p.template_id = t.id
        LEFT JOIN migration.versioned_templates AS tmplt ON t.family_id = tmplt.family_id
                                                    AND tmplt.version = CONCAT('v', t.version)
    LEFT JOIN intermediate.sections ints ON s.id = ints.old_section_id
      LEFT JOIN migration.versioned_sections AS sct ON ints.new_section_id = sct.sectionId
                                                    AND sct.versionedTemplateId = tmplt.id
  LEFT JOIN intermediate.questions intq ON q.id = intq.old_question_id
WHERE t.customization_of IS NULL
  AND t.family_id NOT IN (SELECT DISTINCT family_id FROM never_published)
  AND t.id NOT IN (SELECT id FROM unpublished_currents)
GROUP BY t.family_id, t.version, s.id, q.id, q.number,
         q.text, q.question_format_id, q.created_at, q.updated_at,
         tmplt.id, tmplt.createdById, tmplt.modifiedById, sct.id
ORDER BY q.created_at ASC;
