# Data Migration Plan
This document outlines the plan to migrate data from the existing Rails-based DMP Tool system to the
new Node.js-based DMP Tool system.

**These migrations cannot be run until [TEMPLATES migration](Templates.md)**

### SECTIONS (2,366 rows)
---
The migration of sections from the old system to the new is fairly straightforward.

SQL to extract sections from the old system:
```sql
SELECT templates.family_id template_family_id, CONCAT('v', templates.version) AS template_version,
  sections.id, sections.title, sections.description, sections.number,
  GROUP_CONCAT(themes.id) AS tag_ids,
  sections.created_at, sections.updated_at
FROM sections
  INNER JOIN phases ON sections.phase_id = phases.id
    INNER JOIN templates ON phases.template_id = templates.id
  LEFT JOIN questions ON sections.id = questions.section_id
    LEFT JOIN questions_themes ON questions.id = questions_themes.question_id
      LEFT JOIN themes ON questions_themes.theme_id = themes.id
WHERE templates.customization_of IS NULL
  AND templates.id = (SELECT MAX(t.id) FROM templates AS t WHERE t.family_id = templates.family_id)
GROUP BY templates.family_id, templates.version, sections.id, sections.title, sections.description,
  sections.number, sections.created_at, sections.updated_at
ORDER BY templates.family_id, templates.id, sections.number;
```

These records can be mapped to the `templates` table as:
```
- name ----> sections.name
- description ----> sections.introduction
- number ----> sections.displayOrder
- created_at ----> sections.created
- updated_at ----> sections.modified
```

Special handling:
```
-- templateId -- (can be looked up from the templates mapping table via family_id and version)
-- isDirty -- (set to the isDirty value on the template record)
-- createdById -- (we can set this to the same value in the template record)
-- modifiedById -- (we can set this to the same value in the template record)
```

### SECTION TAGS
For each tag id in `tag_ids` (comma separated) we need to look up the corresponding Tag id from the mapping table and insert a `sectionTags` record for each tag.

```
- sectionId
- tagId -- (looked up from the tag id mapping table)
- created -- (set to the section created date)
- modified -- (set to the section modified date)
- createdById -- (we can set this to the same value in the section record)
- modifiedById -- (we can set this to the same value in the section record)
```

### VERSIONED SECTIONS (5,615 rows)
---

We then need to move the old versions of the sections to the new `versionedSections` table.
SQL to extract versioned sections from the old system:
```sql
SELECT templates.family_id template_family_id, CONCAT('v', templates.version) AS template_version,
  sections.id, sections.title, sections.description, sections.number,
  GROUP_CONCAT(themes.id) AS tag_ids,
  sections.created_at, sections.updated_at
FROM sections
  INNER JOIN phases ON sections.phase_id = phases.id
  INNER JOIN templates ON phases.template_id = templates.id
  LEFT JOIN questions ON sections.id = questions.section_id
    LEFT JOIN questions_themes ON questions.id = questions_themes.question_id
      LEFT JOIN themes ON questions_themes.theme_id = themes.id
WHERE templates.customization_of IS NULL
  AND templates.id NOT IN (
    SELECT t.id FROM templates AS t WHERE t.customization_of IS NULL
    AND t.id = (SELECT MAX(tmp.id) FROM templates AS tmp WHERE tmp.family_id = t.family_id 
    AND tmp.published = 0)
)
GROUP BY templates.family_id, templates.version, sections.id, sections.title, sections.description,
  sections.number, sections.created_at, sections.updated_at
ORDER BY templates.family_id, templates.id, sections.number;
```

These records can be mapped to the `versionedSections` table as:
```
- name ----> versionedSections.name
- description ----> versionedSections.introduction
- number ----> versionedSections.displayOrder
- created_at ----> versionedSections.created
- updated_at ----> versionedSections.modified
```

Special handling:
```
-- versionedTemplateId -- (can be looked up from the templates mapping table via family_id and version)
-- sectionId -- (can be looked up from the sections mapping table via id)
-- createdById -- (we can set this to the same value in the template record)
-- modifiedById -- (we can set this to the same value in the template record)
```

### VERSIONED SECTION TAGS
For each tag id in `tag_ids` (comma separated) we need to look up the corresponding Tag id from the mapping table and insert a `versionedSectionTags` record for each tag.

```
- versionedSectionId
- tagId -- (looked up from the tag id mapping table)
- created -- (set to the section created date)
- modified -- (set to the section modified date)
- createdById -- (we can set this to the same value in the section record)
- modifiedById -- (we can set this to the same value in the section record)
```

### QUESTIONS (5,698 rows)
---
The migration of questions from the old system to the new is fairly straightforward. We need to convert the question text though into a JSON format based on the question type. See the [dmptool-types repo](https://github.com/CDLUC3/dmptool-types/tree/main/src/questions)

SQL to extract questions from the old system:
```sql


SELECT templates.family_id AS template_family_id, CONCAT('v', templates.version) AS template_version,
  sections.id AS section_id, questions.id, questions.number, questions.default_value, questions.text,
  CASE questions.question_format_id
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
                question_options.text, 
                CONCAT(
                  '","value":"', 
                  CONCAT(
                    question_options.text, 
                    CONCAT(
                      '","selected":',
                      CONCAT(
                        CASE WHEN question_options.is_default = 1 THEN true ELSE false END,
                        '}'
                      )
                    )
                  )
                )
              )
            )
          ),
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
                question_options.text, 
                CONCAT(
                  '","value":"', 
                  CONCAT(
                    question_options.text, 
                    CONCAT(
                      '","checked":',
                      CONCAT(
                        CASE WHEN question_options.is_default = 1 THEN true ELSE false END,
                        '}'
                      )
                    )
                  )
                )
              )
            )
          ),
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
                question_options.text, 
                CONCAT(
                  '","value":"', 
                  CONCAT(
                    question_options.text, 
                    CONCAT(
                      '","selected":',
                      CONCAT(
                        CASE WHEN question_options.is_default = 1 THEN true ELSE false END,
                        '}'
                      )
                    )
                  )
                )
              )
            )
          ),
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
                question_options.text, 
                CONCAT(
                  '","value":"', 
                  CONCAT(
                    question_options.text, 
                    CONCAT(
                      '","selected":',
                      CONCAT(
                        CASE WHEN question_options.is_default = 1 THEN true ELSE false END,
                        '}'
                      )
                    )
                  )
                )
              )
            )
          ),
          '],"meta":{"schemaVersion":"1.0"}}'
        )
      )
    ELSE
      '{"type":"textArea","attributes":{"cols":20,"rows":2,"asRichText":true},"meta":{"schemaVersion":"1.0"}}'
  END AS question_json,
  questions.created_at, questions.updated_at
FROM questions
  LEFT JOIN question_formats ON questions.question_format_id = question_formats.id
  LEFT JOIN question_options ON questions.id = question_options.question_id
  INNER JOIN sections ON questions.section_id = sections.id
    INNER JOIN phases ON sections.phase_id = phases.id
      INNER JOIN templates ON phases.template_id = templates.id
WHERE templates.customization_of IS NULL
  AND templates.id = (SELECT MAX(t.id) FROM templates AS t WHERE t.family_id = templates.family_id)
GROUP BY templates.family_id, templates.version, sections.id, questions.id, questions.number,
  questions.default_value, questions.text, questions.question_format_id, questions.created_at, questions.updated_at;
```

These records can be mapped to the `questions` table as:
```
- text ----> questions.text,
- question_json ----> question.json
- number ----> questions.displayOrder
- default_value ----> questions.sampleText
```

Special handling:
```
-- templateId -- (can be looked up from the templates mapping table via family_id and version)
-- sectionId -- (can be looked up from the sections mapping table via section_id)
-- isDirty -- (set to the isDirty value on the section record)
-- createdById -- (we can set this to the same value in the sections record)
-- modifiedById -- (we can set this to the same value in the sections record)
```

### VERSIONED QUESTIONS (9,749 rows)
---
We then need to move the old versions of the questions to the new `versionedQuestions` table.
SQL to extract versioned questions from the old system:
```sql


SELECT templates.family_id AS template_family_id, CONCAT('v', templates.version) AS template_version,
  sections.id AS section_id, questions.id, questions.number, questions.default_value, questions.text,
  CASE questions.question_format_id
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
                question_options.text, 
                CONCAT(
                  '","value":"', 
                  CONCAT(
                    question_options.text, 
                    CONCAT(
                      '","selected":',
                      CONCAT(
                        CASE WHEN question_options.is_default = 1 THEN true ELSE false END,
                        '}'
                      )
                    )
                  )
                )
              )
            )
          ),
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
                question_options.text, 
                CONCAT(
                  '","value":"', 
                  CONCAT(
                    question_options.text, 
                    CONCAT(
                      '","checked":',
                      CONCAT(
                        CASE WHEN question_options.is_default = 1 THEN true ELSE false END,
                        '}'
                      )
                    )
                  )
                )
              )
            )
          ),
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
                question_options.text, 
                CONCAT(
                  '","value":"', 
                  CONCAT(
                    question_options.text, 
                    CONCAT(
                      '","selected":',
                      CONCAT(
                        CASE WHEN question_options.is_default = 1 THEN true ELSE false END,
                        '}'
                      )
                    )
                  )
                )
              )
            )
          ),
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
                question_options.text, 
                CONCAT(
                  '","value":"', 
                  CONCAT(
                    question_options.text, 
                    CONCAT(
                      '","selected":',
                      CONCAT(
                        CASE WHEN question_options.is_default = 1 THEN true ELSE false END,
                        '}'
                      )
                    )
                  )
                )
              )
            )
          ),
          '],"meta":{"schemaVersion":"1.0"}}'
        )
      )
    ELSE
      '{"type":"textArea","attributes":{"cols":20,"rows":2,"asRichText":true},"meta":{"schemaVersion":"1.0"}}'
  END AS question_json,
  questions.created_at, questions.updated_at
FROM questions
  LEFT JOIN question_formats ON questions.question_format_id = question_formats.id
  LEFT JOIN question_options ON questions.id = question_options.question_id
  INNER JOIN sections ON questions.section_id = sections.id
    INNER JOIN phases ON sections.phase_id = phases.id
      INNER JOIN templates ON phases.template_id = templates.id
WHERE templates.customization_of IS NULL
  AND templates.id NOT IN (
    SELECT t.id FROM templates AS t WHERE t.customization_of IS NULL
    AND t.id = (SELECT MAX(tmp.id) FROM templates AS tmp WHERE tmp.family_id = t.family_id 
    AND tmp.published = 0)
)
GROUP BY templates.family_id, templates.version, sections.id, questions.id, questions.number,
  questions.default_value, questions.text, questions.question_format_id, questions.created_at, questions.updated_at;
```

These records can be mapped to the `versionedQuestions` table as:
```
- text ----> versionedQuestions.questionText
- question_json ----> versionedQuestions.json
- number ----> versionedQuestions.displayOrder
- default_value ----> versionedQuestions.sampleText
```

Special handling:
```
-- versionedTemplateId -- (can be looked up from the templates mapping table via family_id and version)
-- versionedSectionId -- (can be looked up from the sections mapping table via the section_id and versionedTemplateId)
-- questionId -- (can be looked up from the questions mapping table via id)
-- createdById -- (we can set this to the same value in the template record)
-- modifiedById -- (we can set this to the same value in the template record)
```

#### Post processing
We may want to run a script to clean up the `displayOrder` on all of these tables. They are numerically correct in the old system but we may want to clean scenarios like `1, 2, 3, 11, 48` to `1, 2, 3, 4, 5`

