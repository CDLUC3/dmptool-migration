--  Target schema (table `template_customizations`):
--  `id` int unsigned NOT NULL AUTO_INCREMENT,
--  `affiliationId` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
--  `templateId` int NOT NULL,
--  `status` varchar(8) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
--  `migrationStatus` varchar(8) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'OK',
--  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
--  `modifiedById` int NOT NULL,
--  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,

MODEL (
  name migration.template_customizations,
  kind FULL,
  columns (
    id INT UNSIGNED PRIMARY KEY,
    old_family_id INT NOT NULL,
    old_template_id INT NOT NULL,
    old_customization_of INT NOT NULL,
    affiliationId VARCHAR(255) NOT NULL,
    status VARCHAR(8) NOT NULL,
    migrationStatus VARCHAR(8) NOT NULL,
    created TIMESTAMP NOT NULL,
    createdById INT NOT NULL,
    modified TIMESTAMP NOT NULL,
    modifiedById INT NOT NULL
  ),
  audits (
    unique_values(columns := (affiliationId, templateId), blocking := false),
    not_null(columns := (old_family_id, old_template_id, old_customization_of,
                         affiliationId, templateId, status, migrationStatus,
                         created, createdById, modified, modifiedById))
  ),
  enabled true
);

WITH published_parent_templates AS (
  SELECT intt.family_id, MAX(intt.old_template_id) AS old_template_id
  FROM intermediate.templates AS intt
  WHERE intt.is_published = 1
  GROUP BY intt.family_id
)
SELECT
  ROW_NUMBER() OVER (ORDER BY intt.old_created_at ASC) AS id,
  intt.family_id AS old_family_id,
  intt.old_template_id,
  intt.customization_of_family_id AS old_customization_of,
  CASE
    WHEN intt.old_org_id IS NULL THEN NULL
    WHEN ro.id IS NULL THEN CONCAT('https://dmptool.org/affiliations/', intt.old_org_id)
    ELSE ro.ror_id
  END AS affiliationId,
  CASE WHEN intt.is_published = 0 THEN 'DRAFT' ELSE 'PUBLISHED' END AS status,
  CASE
    -- When the customized template has no published version the customization is orphaned
    WHEN pt.old_template_id IS NULL THEN 'ORPHANED'
    -- Otherwise the customization is stale by default because we want admins to review them
    ELSE 'STALE'
  END as migrationStatus,
  intt.old_created_at AS created,
  COALESCE(intt.new_created_by_id, @VAR('super_admin_id')) AS createdById,
  intt.old_updated_at AS modified,
  COALESCE(intt.new_created_by_id, @VAR('super_admin_id')) AS modifiedById
FROM intermediate.templates AS intt
  LEFT JOIN dmp.registry_orgs AS ro ON intt.old_org_id = ro.org_id
  LEFT JOIN published_templates AS pt ON intt.customization_of_family_id = pt.family_id
WHERE intt.customization_of_family_id IS NOT NULL AND intt.is_current_template = 1
ORDER BY intt.old_created_at ASC;
