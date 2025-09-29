/*
 * Source table mapping for Rails ActiveRecord Plans table
 * This model extracts DMP plans from the legacy Rails system
 */

MODEL (
  name dmptool_migration.source_plans,
  kind FULL,
  description "Extract DMP plans from legacy Rails DMP Tool system",
  dialect "duckdb"
);

SELECT
  id,
  title,
  template_id,
  created_at,
  updated_at,
  identifier,
  description,
  principal_investigator,
  principal_investigator_identifier,
  data_contact,
  data_contact_identifier,
  funder_id,
  grant_id,
  visibility,
  complete,
  feedback_requested,
  start_date,
  end_date
FROM read_csv_auto('seeds/plans.csv')
WHERE title IS NOT NULL
  AND title != '';