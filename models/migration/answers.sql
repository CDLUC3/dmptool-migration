MODEL (
  name migration.answers,
  kind FULL,
  columns (
    planId INT UNSIGNED NOT NULL,
    versionedSectionId INT UNSIGNED NOT NULL,
    versionedQuestionId INT UNSIGNED NOT NULL,
    json json DEFAULT NULL,
    createdById INT UNSIGNED NOT NULL,
    created TIMESTAMP NOT NULL,
    modifiedById INT UNSIGNED NOT NULL,
    modified TIMESTAMP NOT NULL
  ),
  enabled true
);

JINJA_QUERY_BEGIN;

SELECT
  pl.id AS planId,
  vs.id AS versionedSectionId,
  vq.id AS versionedQuestionId,
  aj.json,
  pl.createdById,
  a.created_at AS created,
  pl.modifiedById,
  a.updated_at AS modified
FROM {{ var('source_db') }}.answers AS a
  JOIN intermediate.answer_jsons AS aj ON aj.answer_id = a.id
  LEFT JOIN migration.plans AS pl ON a.plan_id = pl.old_plan_id
  JOIN migration.versioned_questions AS vq ON a.question_id = vq.old_question_id
    JOIN migration.versioned_sections AS vs ON vq.versionedSectionId = vs.id;

JINJA_END;
