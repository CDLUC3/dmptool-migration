--   Target schema:
--  `id` int NOT NULL AUTO_INCREMENT,
--  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
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
  dmp.users.id,
  dmp.users.firstname,
  dmp.users.surname,
  dmp.users.email,
  dmp.users.created_at,
  dmp.users.updated_at,
  dmp.users.accept_terms,
  dmp.users.last_sign_in_at,
  dmp.languages.abbreviation AS language,
  o.value AS orcid,
  s.value AS sso_id,
  CASE
    WHEN dmp.users.org_id IS NULL THEN NULL
    WHEN dmp.registry_orgs.id IS NULL THEN CONCAT('https://dmptool.org/affiliations/', dmp.orgs.id)
    ELSE dmp.registry_orgs.ror_id
  END AS org_id,
  (SELECT perm_id FROM dmp.users_perms WHERE dmp.users_perms.user_id = dmp.users.id AND perm_id = 10) is_super,
  (SELECT COUNT(perm_id) FROM dmp.users_perms WHERE dmp.users_perms.user_id = dmp.users.id AND perm_id != 10) is_admin
FROM dmp.users
LEFT JOIN dmp.languages ON dmp.users.language_id = dmp.languages.id
INNER JOIN dmp.orgs ON dmp.users.org_id = dmp.orgs.id
LEFT JOIN dmp.registry_orgs ON dmp.orgs.id = dmp.registry_orgs.org_id
LEFT JOIN dmp.identifiers o ON o.identifiable_type = 'User' AND o.identifiable_id = dmp.users.id AND o.identifier_scheme_id = 1
LEFT JOIN dmp.identifiers s ON s.identifiable_type = 'User' AND s.identifiable_id = dmp.users.id AND s.identifier_scheme_id = 2;
