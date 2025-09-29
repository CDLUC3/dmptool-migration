AUDIT (
  name plans_title_validation
);

SELECT *
FROM dmptool_migration.target_plans
WHERE title IS NULL 
   OR title = '' 
   OR LENGTH(TRIM(title)) < 3;