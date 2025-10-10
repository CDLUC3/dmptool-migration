MODEL (
  name migration.projects,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    title VARCHAR(255) NOT NULL,
    abstractText TEXT,
    researchDomainId VARCHAR(255),
    startDate VARCHAR(16),
    endDate VARCHAR(16),
    isTestProject TINYINT(1) NOT NULL DEFAULT 0,
    createdById INT UNSIGNED NOT NULL,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modifiedById INT UNSIGNED NOT NULL,
    modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ),
  enabled true
);

SELECT
  p.id,
  p.title,
  p.description AS abstractText,
  rdm.new_id AS researchDomainId,
  DATE_FORMAT(p.start_date, '%Y-%m-%d') AS startDate,
  DATE_FORMAT(p.end_date, '%Y-%m-%d') AS endDate,
  p.is_test_plan AS isTestProject,
  u.id AS createdById,
  p.created_at AS created,
  u.id AS modifiedById,
  p.updated_at AS modified
FROM intermediate.plans p
LEFT JOIN intermediate.users u ON p.owner_email = u.email
LEFT JOIN intermediate.research_domains_mapping rdm ON p.research_domain_id = rdm.old_id;