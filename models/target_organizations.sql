/*
 * Target transformation for Apollo GraphQL Organizations schema
 * This model transforms legacy organization data to the new Node Apollo format
 */

MODEL (
  name dmptool_migration.target_organizations,
  kind FULL,
  description "Transform legacy organizations to Apollo GraphQL format",
  dialect "duckdb"
);

SELECT
  CONCAT('org_', CAST(id AS VARCHAR)) AS apollo_id,
  name,
  COALESCE(abbreviation, '') AS abbreviation,
  COALESCE(target_url, '') AS website,
  created_at AS createdAt,
  updated_at AS updatedAt,
  CASE 
    WHEN is_other = 1 THEN true 
    ELSE false 
  END AS isOther,
  COALESCE(sort_name, name) AS sortName,
  CONCAT('region_', CAST(region_id AS VARCHAR)) AS regionId,
  CONCAT('lang_', CAST(language_id AS VARCHAR)) AS languageId,
  COALESCE(logo_uid, '') AS logoUid,
  COALESCE(logo_name, '') AS logoName,
  COALESCE(contact_email, '') AS contactEmail,
  COALESCE(contact_name, '') AS contactName,
  CASE 
    WHEN managed = 1 THEN true 
    ELSE false 
  END AS isManaged,
  CASE 
    WHEN parent_id IS NOT NULL 
    THEN CONCAT('org_', CAST(parent_id AS VARCHAR))
    ELSE NULL
  END AS parentOrganizationId,
  -- Generate Apollo-style metadata
  CURRENT_TIMESTAMP AS migratedAt,
  'rails_migration' AS migratedFrom
FROM dmptool_migration.source_organizations
WHERE name IS NOT NULL;