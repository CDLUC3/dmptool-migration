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
  name migration.users,
  kind FULL,
  audits (
    assert_row_count(dmp_table:='users', blocking := false),
  ),
  enabled true
);

SELECT
  u.id,
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
    WHEN ro.id IS NULL THEN CONCAT('https://dmptool.org/affiliations/', o.id)
    ELSE ro.ror_id
  END AS org_id,
  CASE
    WHEN (SELECT up.perm_id FROM dmp.users_perms AS up WHERE up.user_id = u.id AND up.perm_id = 10) THEN 'SUPERADMIN'
    WHEN (SELECT COUNT(up.perm_id) FROM dmp.users_perms AS up WHERE up.user_id = u.id AND up.perm_id != 10) THEN 'ADMIN'
    ELSE 'RESEARCHER'
  END AS role
FROM dmp.users AS u
  LEFT JOIN dmp.languages AS l ON u.language_id = l.id
  INNER JOIN dmp.orgs AS o ON u.org_id = o.id
  	LEFT JOIN dmp.registry_orgs AS ro ON o.id = ro.org_id
  LEFT JOIN dmp.identifiers orc ON orc.identifiable_type = 'User' AND orc.identifiable_id = u.id AND orc.identifier_scheme_id = 1
  LEFT JOIN dmp.identifiers sso ON sso.identifiable_type = 'User' AND sso.identifiable_id = u.id AND sso.identifier_scheme_id = 2;
