MODEL (
  name migration.users,
  kind FULL,
  columns (
    id INT UNSIGNED PRIMARY KEY,
    password VARCHAR(255) NOT NULL,
    oldPasswordHash VARCHAR(255),
    role VARCHAR(16) NOT NULL DEFAULT 'RESEARCHER',
    givenName VARCHAR(255) NOT NULL,
    surName VARCHAR(255) NOT NULL,
    affiliationId VARCHAR(255),
    acceptedTerms TINYINT(1) NOT NULL DEFAULT 0,
    orcid VARCHAR(255),
    ssoId VARCHAR(255),
    locked TINYINT(1) NOT NULL DEFAULT 0,
    active TINYINT(1) NOT NULL DEFAULT 1,
    languageId CHAR(5) NOT NULL DEFAULT 'en-US',
    last_sign_in DATETIME,
    last_sign_in_via VARCHAR(10),
    failed_sign_in_attempts INT NOT NULL DEFAULT 0,
    notify_on_comment_added TINYINT(1) NOT NULL DEFAULT 1,
    notify_on_template_shared TINYINT(1) NOT NULL DEFAULT 1,
    notify_on_feedback_complete TINYINT(1) NOT NULL DEFAULT 1,
    notify_on_plan_shared TINYINT(1) NOT NULL DEFAULT 1,
    notify_on_plan_visibility_change TINYINT(1) NOT NULL DEFAULT 1,
    created DATETIME NOT NULL,
    createdById INT UNSIGNED,
    modified DATETIME NOT NULL,
    modifiedById INT UNSIGNED
  ),
  -- audits (
    -- unique_values(columns := (id, ssoId), blocking := false)
    -- not_null(columns := (id, role, password, affiliationId, created, modified))
  -- ),
  enabled true
);

SELECT
  id,
  password,
  password AS oldPasswordHash,
  role,
  TRIM(firstname) AS givenName,
  TRIM(surname) AS surName,
  org_id AS affiliationId,
  accept_terms AS acceptedTerms,
  TRIM(orcid) AS orcid,
  TRIM(sso_id) AS ssoId,
  locked,
  active,
  language AS languageId,
  last_sign_in_at AS last_sign_in,
  NULL AS last_sign_in_via,
  0 AS failed_sign_in_attempts,
  1 AS notify_on_comment_added,
  1 AS notify_on_template_shared,
  1 AS notify_on_feedback_complete,
  1 AS notify_on_plan_shared,
  1 AS notify_on_plan_visibility_change,
  created_at AS created,
  id AS createdById,
  updated_at AS modified,
  id AS modifiedById
FROM intermediate.users
ORDER BY id;
