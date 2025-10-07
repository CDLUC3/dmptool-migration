--   Target schema (table `tags`):
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
  name migration.themes,
  kind FULL,
  audits (
    assert_row_count(dmp_table:='themes', blocking := false),
  ),
  enabled true
);

SELECT
  dmp.themes.id,
  dmp.themes.title,
  dmp.themes.description,
  dmp.themes.created_at,
  dmp.themes.updated_at
FROM dmp.themes;
