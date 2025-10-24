MODEL (
  name migration.user_emails,
  kind FULL,
  columns (
    id INT UNSIGNED PRIMARY KEY,
    userId INT UNSIGNED NOT NULL,
    email VARCHAR(255) NOT NULL,
    isPrimary TINYINT(1) NOT NULL DEFAULT 0,
    isConfirmed TINYINT(1) NOT NULL DEFAULT 0,
    created TIMESTAMP NOT NULL,
    createdById INT UNSIGNED,
    modified TIMESTAMP NOT NULL,
    modifiedById INT UNSIGNED
  ),
  audits (
    unique_combination_of_columns(columns := (userId, email), blocking := false),
    not_null(columns := (id, userId, email, isPrimary, isConfirmed, created, modified))
  ),
  enabled true
);

SELECT
  ROW_NUMBER() OVER (ORDER BY u.created_at ASC) AS id,
  u.id AS userId,
  TRIM(u.email) AS email,
  true AS isPrimary,
  true AS isConfirmed,
  u.created_at AS created,
  u.id AS createdById,
  u.updated_at AS modified,
  u.id AS modifiedById
FROM intermediate.users AS u
ORDER BY u.id;
