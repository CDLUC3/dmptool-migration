/*
 * Data quality audit for user email validation
 * Ensures all users have valid email addresses
 */

AUDIT (
  name dmptool_migration.users_email_validation,
  description "Validate that all users have properly formatted email addresses"
);

SELECT *
FROM dmptool_migration.target_users
WHERE email IS NULL 
   OR email = '' 
   OR email NOT LIKE '%@%'
   OR email NOT LIKE '%.%';