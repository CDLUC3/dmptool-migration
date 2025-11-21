MODEL (
  name migration.projects,
  kind FULL,
  columns (
    id INT UNSIGNED NOT NULL,
    old_plan_id INT UNSIGNED,
    title VARCHAR(255) NOT NULL,
    abstractText TEXT,
    researchDomainId VARCHAR(255),
    startDate VARCHAR(16),
    endDate VARCHAR(16),
    isTestProject TINYINT(1) NOT NULL DEFAULT 0,
    createdById INT UNSIGNED NOT NULL,
    created DATETIME NOT NULL DEFAULT CURRENT_DATE,
    modifiedById INT UNSIGNED NOT NULL,
    modified DATETIME NOT NULL DEFAULT CURRENT_DATE,
  ),
  enabled true
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
  TRIM(p.title) AS title,
  TRIM(p.description) AS abstractText,
  rdm.new_id AS researchDomainId,
  DATE_FORMAT(p.start_date, '%Y-%m-%d') AS startDate,
  DATE_FORMAT(p.end_date, '%Y-%m-%d') AS endDate,
  p.is_test_plan AS isTestProject,
  COALESCE(u.id, (SELECT id FROM default_super_admin)) AS createdById,
  p.created_at AS created,
  COALESCE(u.id, (SELECT id FROM default_super_admin)) AS modifiedById,
  p.updated_at AS modified
FROM intermediate.plans p
LEFT JOIN intermediate.users u ON p.owner_email = u.email
LEFT JOIN intermediate.research_domains_mapping rdm ON p.research_domain_id = rdm.old_id;