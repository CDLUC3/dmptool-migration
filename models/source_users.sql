/*
 * Source table mapping for Rails ActiveRecord Users table
 * This model extracts user data from the legacy Rails system
 */

MODEL (
  name dmptool_migration.source_users,
  kind FULL,
  description "Extract users from legacy Rails DMP Tool system",
  dialect "duckdb"
);

SELECT
  id,
  email,
  first_name,
  last_name,
  created_at,
  updated_at,
  active,
  confirmed_at,
  invitation_accepted_at,
  org_id,
  language_id,
  role_id
FROM read_csv_auto('seeds/users.csv')
WHERE email IS NOT NULL
  AND email != '';