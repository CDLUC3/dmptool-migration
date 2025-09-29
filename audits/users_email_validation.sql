AUDIT (
  name users_email_validation
);

SELECT *
FROM dmptool_migration.target_users
WHERE email IS NULL 
   OR email = '' 
   OR email NOT LIKE '%@%'
   OR email NOT LIKE '%.%';