--  Target schema (table `templates`):
--  `id` int NOT NULL AUTO_INCREMENT,
--  `sourceTemplateId` int DEFAULT NULL,
--  `name` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
--  `description` mediumtext COLLATE utf8mb4_unicode_ci,
--  `ownerId` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `latestPublishVisibility` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `latestPublishVersion` varchar(16) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
--  `latestPublishDate` timestamp NULL DEFAULT NULL,
--  `isDirty` tinyint(1) NOT NULL DEFAULT '1',
--  `bestPractice` tinyint(1) NOT NULL DEFAULT '0',
--  `languageId` char(5) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'en-US',
--  `createdById` int NOT NULL,
--  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `modifiedById` int NOT NULL,
--  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP

MODEL (
  name migration.templates,
  kind FULL,
  columns (
    id INT UNSIGNED PRIMARY KEY,
    family_id INT,
    name VARCHAR(255) NOT NULL,
    description MEDIUMTEXT,
    ownerId VARCHAR(255) NOT NULL,
    latestPublishVisibility VARCHAR(16) NOT NULL,
    latestPublishVersion VARCHAR(16),
    latestPublishDate TIMESTAMP,
    isDirty BOOLEAN NOT NULL DEFAULT 1,
    bestPractice BOOLEAN NOT NULL DEFAULT 0,
    languageId CHAR(5) NOT NULL DEFAULT 'en-US',
    created TIMESTAMP NOT NULL,
    createdById INT,
    modified TIMESTAMP NOT NULL,
    modifiedById INT
  ),
  audits (
    unique_combination_of_columns(columns := (family_id)),
    not_null(columns := (family_id, name, ownerId, created, createdById, modified, modifiedById))
  ),
  enabled true
);

WITH org_creator AS (
  SELECT
    u.org_id,
    COALESCE(mu.id, @VAR('super_admin_id')) AS user_id
  FROM dmp.users AS u
    INNER JOIN dmp.users_perms AS up ON u.id = up.user_id AND up.perm_id = 6
      LEFT JOIN migration.users AS mu ON u.email = mu.email
  WHERE u.org_id IS NOT NULL
  QUALIFY ROW_NUMBER() OVER (PARTITION BY u.org_id ORDER BY u.created_at DESC) = 1
)

SELECT
  ROW_NUMBER() OVER (ORDER BY t.created_at ASC) AS id,
  t.family_id,
  t.title AS name,
  t.description,
  (t.is_default = 1) AS bestPractice,
  CASE WHEN t.visibility = 0 THEN 'ORGANIZATIONAL' ELSE 'PUBLIC' END AS latestPublishVisibility,
  (t.published = 0) AS isDirty,
  CASE
    WHEN t.published = 1 THEN CONCAT('v', t.version)
    WHEN t.published = 0 AND t.version > 0 THEN CONCAT('v', t.version - 1)
    ELSE NULL
  END AS latestPublishVersion,
  CASE WHEN t.published = 1 OR t.version > 0 THEN t.updated_at ELSE NULL END AS latestPublishDate,
  CASE
    WHEN t.org_id IS NULL THEN NULL
    WHEN ro.id IS NULL THEN CONCAT('https://dmptool.org/affiliations/', o.id)
    ELSE ro.ror_id
  END AS ownerId,
  CASE
    WHEN t.locale IN ('pt', 'pt-BR') OR t.family_id IN (SELECT pt.family_id FROM migration.templates_pt_br AS pt) THEN 'pt-BR'
    ELSE 'en-US'
  END AS languageId,
  COALESCE(oc.user_id, @VAR('super_admin_id')) AS createdById,
  t.created_at AS created,
  COALESCE(oc.user_id, @VAR('super_admin_id')) AS modifiedById,
  t.updated_at AS modified
FROM dmp.templates AS t
  INNER JOIN dmp.orgs AS o ON t.org_id = o.id
    LEFT OUTER JOIN dmp.registry_orgs AS ro ON o.id = ro.org_id
    LEFT JOIN org_creator AS oc ON oc.org_id = o.id
WHERE t.customization_of IS NULL
  AND t.id = (SELECT MAX(tmplt.id) FROM dmp.templates AS tmplt WHERE tmplt.family_id = t.family_id)
  AND t.family_id IS NOT NULL
  AND t.title IS NOT NULL
ORDER BY t.created_at ASC;
