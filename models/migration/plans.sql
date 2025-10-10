MODEL (
  name migration.plans,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    projectId INT UNSIGNED NOT NULL,
    versionedTemplateId INT UNSIGNED NOT NULL,
    title VARCHAR(255),
    visibility VARCHAR(16),
    status VARCHAR(16),
    dmpId VARCHAR(255),
    registeredById INT,
    registered TIMESTAMP,
    languageId CHAR(5) NOT NULL DEFAULT 'en-US',
    featured TINYINT(1) NOT NULL DEFAULT 0,
    createdById INT UNSIGNED NOT NULL,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifiedById INT UNSIGNED NOT NULL,
    modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ),
  enabled true,
);

SELECT
  p.id,
  p.id AS projectId,
  map.new_versioned_template_id AS versionedTemplateId,
  p.title,
  p.visibility,
  p.status,
  p.dmp_id AS dmpId,
  u.id AS registeredById,
  p.created_at AS registered, -- TODO: this was registered_at but that field doesn't exist
  p.language AS languageId,
  p.featured AS featured,
  u.id AS createdById,
  p.created_at AS created,
  u.id AS modifiedById,
  p.updated_at AS modified
FROM intermediate.plans p
LEFT JOIN intermediate.template_mappings map ON p.template_id = map.old_template_id
LEFT JOIN intermediate.users u ON p.owner_email = u.email;