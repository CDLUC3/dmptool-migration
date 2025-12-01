MODEL (
  name migration.plans,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    old_plan_id INT UNSIGNED NOT NULL,
    projectId INT UNSIGNED NOT NULL,
    versionedTemplateId INT UNSIGNED NOT NULL,
    title VARCHAR(255),
    visibility VARCHAR(16),
    status VARCHAR(16),
    dmpId VARCHAR(255),
    registeredById INT,
    registered DATETIME,
    languageId CHAR(5) NOT NULL DEFAULT 'en-US',
    featured TINYINT(1) NOT NULL DEFAULT 0,
    createdById INT UNSIGNED NOT NULL,
    created DATETIME NOT NULL DEFAULT CURRENT_DATE,
    modifiedById INT UNSIGNED NOT NULL,
    modified DATETIME NOT NULL DEFAULT CURRENT_DATE,
  ),
  enabled true,
);

WITH default_super_admin AS (
  SELECT id
  FROM intermediate.users
  WHERE role = 'SUPERADMIN'
  ORDER BY id DESC LIMIT 1
)

SELECT
  ROW_NUMBER() OVER (ORDER BY p.id ASC) AS id,
  p.id AS old_plan_id,
  prj.id AS projectId,
  map.new_versioned_template_id AS versionedTemplateId,
  TRIM(p.title) AS title,
  p.visibility,
  p.status,
  COALESCE(p.dmp_id, CONCAT('TEMP-', p.id)) AS dmpId,
  CASE WHEN p.dmp_id IS NOT NULL THEN u.id ELSE NULL END AS registeredById,
  CASE WHEN p.dmp_id IS NOT NULL THEN p.updated_at ELSE NULL END AS registered,
  p.language AS languageId,
  p.featured AS featured,
  COALESCE(u.id, (SELECT id FROM default_super_admin)) AS createdById,
  p.created_at AS created,
  COALESCE(u.id, (SELECT id FROM default_super_admin)) AS modifiedById,
  p.updated_at AS modified
FROM intermediate.plans p
  JOIN intermediate.template_mappings map ON p.template_id = map.old_template_id
  LEFT JOIN intermediate.users u ON p.owner_email = u.email
  LEFT JOIN migration.projects prj ON p.id = prj.old_plan_id;