/*
 * Data quality audit for plan title validation
 * Ensures all plans have meaningful titles
 */

AUDIT (
  name dmptool_migration.plans_title_validation,
  description "Validate that all plans have non-empty titles"
);

SELECT *
FROM dmptool_migration.target_plans
WHERE title IS NULL 
   OR title = '' 
   OR LENGTH(TRIM(title)) < 3;