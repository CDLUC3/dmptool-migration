--  Target schema (table `versionedTemplates`):
--  `id` int NOT NULL AUTO_INCREMENT,
--  `templateId` int NOT NULL,
--  `active` tinyint(1) NOT NULL DEFAULT '0',
--  `version` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `versionType` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
--  `versionedById` int NOT NULL,
--  `comment` mediumtext COLLATE utf8mb4_unicode_ci,
--  `name` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
--  `description` mediumtext COLLATE utf8mb4_unicode_ci,
--  `ownerId` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `visibility` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `bestPractice` tinyint(1) NOT NULL DEFAULT '0',
--  `languageId` char(5) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'en-US',
--  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `createdById` int NOT NULL,
--  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `modifiedById` int NOT NULL,

MODEL (
  name migration.versioned_templates,
  kind FULL,
  columns (
    id BIGINT UNSIGNED PRIMARY KEY,
    family_id INT,
    template_id INT,
    active BOOLEAN NOT NULL DEFAULT 0,
    version VARCHAR(16) NOT NULL,
    versionType VARCHAR(16) NOT NULL DEFAULT 'DRAFT',
    versionedById INT NOT NULL,
    comment MEDIUMTEXT,
    name VARCHAR(255) NOT NULL,
    description MEDIUMTEXT,
    ownerId VARCHAR(255) NOT NULL,
    visibility VARCHAR(16) NOT NULL,
    bestPractice BOOLEAN NOT NULL DEFAULT 0,
    languageId CHAR(5) NOT NULL DEFAULT 'en-US',
    created TIMESTAMP NOT NULL,
    createdById INT,
    modified TIMESTAMP NOT NULL,
    modifiedById INT
  ),
  audits (
    -- version number must be unique per template
    unique_combination_of_columns(columns := (template_id, version)),
    not_null(columns := (family_id, template_id, version, versionedById, name, ownerId,
             created, createdById, modified, modifiedById))
  ),
  enabled true
);

--  Custom audit to ensure each template has only one active version
AUDIT (name dmptool_only_one_active_version_per_template);
  SELECT template_id
  FROM migration.versioned_templates
  WHERE active = 1
  GROUP BY template_id
  HAVING COUNT(*) > 1;

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
  ROW_NUMBER() OVER (ORDER BY vt.created_at ASC) AS id,
  vt.family_id,
  t.id AS template_id,
  (vt.published = 1) AS active,
  CONCAT('v', vt.version) AS version,
  'PUBLISHED' AS versionType,
  COALESCE(oc.user_id, @VAR('super_admin_id')) AS versionedById,
  NULL AS comment,
  vt.title AS name,
  vt.description,
  CASE
    WHEN vt.org_id IS NULL THEN NULL
    WHEN ro.id IS NULL THEN CONCAT('https://dmptool.org/affiliations/', o.id)
    ELSE ro.ror_id
  END AS ownerId,
  CASE WHEN vt.visibility = 0 THEN 'ORGANIZATIONAL' ELSE 'PUBLIC' END AS visibility,
  (vt.is_default = 1) AS bestPractice,
  CASE
    WHEN vt.locale IN ('pt', 'pt-BR') OR vt.family_id IN (SELECT pt.family_id FROM migration.templates_pt_br AS pt) THEN 'pt-BR'
    ELSE 'en-US'
  END AS languageId,
  COALESCE(oc.user_id, @VAR('super_admin_id')) AS createdById,
  vt.created_at AS created,
  COALESCE(oc.user_id, @VAR('super_admin_id')) AS modifiedById,
  vt.updated_at AS modified
FROM dmp.templates AS vt
  INNER JOIN dmp.orgs AS o ON vt.org_id = o.id
    LEFT JOIN org_creator AS oc ON oc.org_id = o.id
    LEFT OUTER JOIN dmp.registry_orgs AS ro ON o.id = ro.org_id
  INNER JOIN migration.templates AS t ON vt.family_id = t.family_id
WHERE vt.customization_of IS NULL
ORDER BY vt.created_at ASC;
