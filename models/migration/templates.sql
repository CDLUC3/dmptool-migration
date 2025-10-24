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
    old_family_id INT,
    old_template_id INT,
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
    unique_values(columns := (old_family_id), blocking := false),
    not_null(columns := (old_family_id, name, ownerId, created, createdById, modified, modifiedById))
  ),
  enabled true
);

WITH default_super_admin AS (
  SELECT id
  FROM intermediate.users
  WHERE role = 'SUPERADMIN'
  ORDER BY id DESC LIMIT 1
),

latest_published AS (
  SELECT inttmplt.family_id,
         inttmplt.old_template_id,
         inttmplt.visibility,
         inttmplt.version,
         inttmplt.old_updated_at
  FROM intermediate.templates AS inttmplt
  WHERE inttmplt.is_published = 1
)

SELECT
  ROW_NUMBER() OVER (ORDER BY t.created_at ASC) AS id,
  t.family_id AS old_family_id,
  t.id AS old_template_id,
  TRIM(t.title) AS name,
  TRIM(t.description) AS description,
  intt.best_practice AS bestPractice,
  CASE WHEN intt.family_id == lp.family_id
    CASE WHEN lp.visibility = 0 THEN 'ORGANIZATIONAL' ELSE 'PUBLIC' END
    ELSE NULL
  END AS latestPublishVisibility,
  (intt.is_published = 0) AS isDirty,
  CASE WHEN intt.family_id == lp.family_id THEN CONCAT('v', lp.version) ELSE NULL END AS latestPublishVersion,
  CASE WHEN intt.family_id == lp.family_id THEN lp.old_updated_at ELSE NULL END AS latestPublishDate,
  CASE
    WHEN t.org_id IS NULL THEN NULL
    WHEN ro.id IS NULL THEN CONCAT('https://dmptool.org/affiliations/', t.org_id)
    ELSE ro.ror_id
  END AS ownerId,
  CASE
    WHEN t.locale IN ('pt', 'pt-BR') OR t.family_id IN (SELECT pt.family_id FROM intermediate.templates_pt_br AS pt) THEN 'pt-BR'
    ELSE 'en-US'
  END AS languageId,
  COALESCE(intt.new_created_by_id, (SELECT id FROM default_super_admin)) AS createdById,
  t.created_at AS created,
  COALESCE(intt.new_created_by_id, (SELECT id FROM default_super_admin)) AS modifiedById,
  t.updated_at AS modified
FROM source_db.templates AS t
  LEFT JOIN latest_published AS lp ON t.family_id = lp.family_id
  JOIN intermediate.templates AS intt ON t.id = intt.old_template_id
    LEFT JOIN source_db.registry_orgs AS ro ON t.org_id = ro.org_id
WHERE t.customization_of IS NULL
  AND intt.is_current_template
ORDER BY t.created_at ASC;

-- Reconciliation queries:
-- SELECT COUNT(id) from migration.templates; #477
--
-- SELECT COUNT(DISTINCT family_id) FROM source_db.templates WHERE customization_of IS NULL; #477