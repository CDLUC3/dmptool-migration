AUDIT (
  name organizations_name_validation
);

SELECT *
FROM dmptool_migration.target_organizations
WHERE name IS NULL 
   OR name = '' 
   OR LENGTH(TRIM(name)) < 2;