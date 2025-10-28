--   Target schema:
--  `id` int NOT NULL AUTO_INCREMENT,
--  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `oldPasswordHash` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
--  `role` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'RESEARCHER',
--  `givenName` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `surName` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `affiliationId` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
--  `acceptedTerms` tinyint(1) NOT NULL DEFAULT '0',
--  `orcid` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
--  `ssoId` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
--  `locked` tinyint(1) NOT NULL DEFAULT '0',
--  `active` tinyint(1) NOT NULL DEFAULT '1',
--  `languageId` char(5) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'en-US',
--  `last_sign_in` timestamp NULL DEFAULT NULL,
--  `last_sign_in_via` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
--  `failed_sign_in_attempts` int NOT NULL DEFAULT '0',
--  `notify_on_comment_added` tinyint(1) NOT NULL DEFAULT '1',
--  `notify_on_template_shared` tinyint(1) NOT NULL DEFAULT '1',
--  `notify_on_feedback_complete` tinyint(1) NOT NULL DEFAULT '1',
--  `notify_on_plan_shared` tinyint(1) NOT NULL DEFAULT '1',
--  `notify_on_plan_visibility_change` tinyint(1) NOT NULL DEFAULT '1',
--  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `createdById` int DEFAULT NULL,
--  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `modifiedById` int DEFAULT NULL,

MODEL (
  name intermediate.users,
  kind FULL,
  audits (
    -- assert_row_count(dmp_table:='users', blocking := false),
    unique_values(columns := (id, email, sso_id), blocking := false),
  ),
  enabled true
);

SELECT
  ROW_NUMBER() OVER (ORDER BY u.created_at ASC) AS id,
  TRIM(u.firstname) AS firstname,
  TRIM(u.surname) AS surname,
  TRIM(u.email) AS email,
  u.created_at,
  u.updated_at,
  u.accept_terms,
  u.active,
  u.last_sign_in_at,
  l.abbreviation AS language,
  TRIM(orc.value) AS orcid,
  TRIM(sso.value) AS sso_id,
  false AS locked,
  TRIM(encrypted_password) AS `password`,
  CASE
    WHEN u.org_id IS NULL THEN NULL
    WHEN ro.id IS NULL and ron.id IS NULL THEN CONCAT('https://dmptool.org/affiliations/', o.id)
    WHEN ro.ror_id IS NOT NULL THEN ro.ror_id
    ELSE ron.ror_id
  END AS org_id,
  CASE
    WHEN (SELECT up.perm_id FROM source_db.users_perms AS up WHERE up.user_id = u.id AND up.perm_id = 10) THEN 'SUPERADMIN'
    WHEN (SELECT COUNT(up.perm_id) FROM source_db.users_perms AS up WHERE up.user_id = u.id AND up.perm_id != 10) THEN 'ADMIN'
    ELSE 'RESEARCHER'
  END AS role
FROM source_db.users AS u
  LEFT JOIN source_db.languages AS l ON u.language_id = l.id
  INNER JOIN source_db.orgs AS o ON u.org_id = o.id
  	LEFT JOIN source_db.registry_orgs AS ro ON o.id = ro.org_id
    LEFT JOIN source_db.registry_orgs AS ron ON o.name COLLATE utf8mb3_unicode_ci = ron.name
  LEFT JOIN source_db.identifiers orc ON orc.identifiable_type = 'User' AND orc.identifiable_id = u.id AND orc.identifier_scheme_id = 1
  LEFT JOIN source_db.identifiers sso ON sso.identifiable_type = 'User' AND sso.identifiable_id = u.id AND sso.identifier_scheme_id = 2;
