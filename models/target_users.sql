/*
 * Target transformation for Apollo GraphQL Users schema
 * This model transforms legacy user data to the new Node Apollo format
 */

MODEL (
  name dmptool_migration.target_users,
  kind FULL,
  description "Transform legacy users to Apollo GraphQL format",
  dialect "duckdb"
);

SELECT
  CONCAT('user_', CAST(id AS VARCHAR)) AS apollo_id,
  email,
  COALESCE(first_name, '') AS firstName,
  COALESCE(last_name, '') AS lastName,
  created_at AS createdAt,
  updated_at AS updatedAt,
  CASE 
    WHEN active = 1 THEN true 
    ELSE false 
  END AS isActive,
  CASE 
    WHEN confirmed_at IS NOT NULL THEN true 
    ELSE false 
  END AS isConfirmed,
  CASE 
    WHEN invitation_accepted_at IS NOT NULL THEN true 
    ELSE false 
  END AS invitationAccepted,
  CONCAT('org_', CAST(org_id AS VARCHAR)) AS organizationId,
  CONCAT('lang_', CAST(language_id AS VARCHAR)) AS languageId,
  CONCAT('role_', CAST(role_id AS VARCHAR)) AS roleId,
  -- Generate Apollo-style metadata
  CURRENT_TIMESTAMP AS migratedAt,
  'rails_migration' AS migratedFrom
FROM dmptool_migration.source_users
WHERE email IS NOT NULL;