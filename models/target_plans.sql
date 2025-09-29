/*
 * Target transformation for Apollo GraphQL Plans schema
 * This model transforms legacy DMP plans to the new Node Apollo format
 */

MODEL (
  name dmptool_migration.target_plans,
  kind FULL,
  description "Transform legacy DMP plans to Apollo GraphQL format",
  dialect "duckdb"
);

SELECT
  CONCAT('plan_', CAST(id AS VARCHAR)) AS apollo_id,
  title,
  COALESCE(description, '') AS description,
  CONCAT('template_', CAST(template_id AS VARCHAR)) AS templateId,
  created_at AS createdAt,
  updated_at AS updatedAt,
  identifier,
  principal_investigator AS principalInvestigator,
  principal_investigator_identifier AS principalInvestigatorId,
  data_contact AS dataContact,
  data_contact_identifier AS dataContactId,
  CONCAT('funder_', CAST(funder_id AS VARCHAR)) AS funderId,
  grant_id AS grantId,
  visibility,
  CASE 
    WHEN complete = 1 THEN true 
    ELSE false 
  END AS isComplete,
  CASE 
    WHEN feedback_requested = 1 THEN true 
    ELSE false 
  END AS feedbackRequested,
  start_date AS startDate,
  end_date AS endDate,
  -- Generate Apollo-style metadata
  CURRENT_TIMESTAMP AS migratedAt,
  'rails_migration' AS migratedFrom
FROM dmptool_migration.source_plans
WHERE title IS NOT NULL;