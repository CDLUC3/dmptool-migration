/*
 * Source table mapping for Rails ActiveRecord Organizations table
 * This model extracts organization data from the legacy Rails system
 */

MODEL (
  name dmptool_migration.source_organizations,
  kind FULL,
  description "Extract organizations from legacy Rails DMP Tool system",
  dialect "duckdb"
);

SELECT
  id,
  name,
  abbreviation,
  target_url,
  created_at,
  updated_at,
  is_other,
  sort_name,
  region_id,
  language_id,
  logo_uid,
  logo_name,
  contact_email,
  contact_name,
  managed,
  parent_id
FROM read_csv_auto('seeds/organizations.csv')
WHERE name IS NOT NULL
  AND name != '';