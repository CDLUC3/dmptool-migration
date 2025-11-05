MODEL (
  name intermediate.plans,
  kind FULL,
  columns (
    id INT,
    dmp_id VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    template_id INT,
    title VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    description text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    research_domain_id BIGINT,
    start_date DATETIME,
    end_date DATETIME,
    featured BOOLEAN,
    created_at DATETIME,
    updated_at DATETIME,
    grant_number VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    funding_status INT,
    language VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    owner_email VARCHAR(80) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    opportunity_id VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    grant_id VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    visibility VARCHAR(14),
    is_test_plan INT,
    status VARCHAR(8),
    org_id VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    funder_id VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci
  ),
  enabled true
);

JINJA_QUERY_BEGIN;

WITH owner_emails AS (
  SELECT
    oe.id,
    oe.owner_email
  FROM (
    SELECT
      p.id,
      TRIM(u.email) AS owner_email,
      ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY r.created_at DESC) AS row_num,
    FROM {{ var('source_db') }}.users u
    INNER JOIN {{ var('source_db') }}.roles r ON r.user_id = u.id AND r.access = 15 AND r.active = 1
    INNER JOIN {{ var('source_db') }}.plans p ON r.plan_id = p.id
  ) AS oe
  WHERE oe.row_num = 1
)

SELECT
  p.id,
  p.dmp_id,
  p.template_id, -- could use this to query source_db.templates to get the id and version
  p.title,
  p.description,
  p.research_domain_id,
  p.start_date,
  p.end_date,
  p.featured,
  p.created_at,
  p.updated_at,
  p.grant_number,
  p.funding_status,
  l.abbreviation AS language,
  oe.owner_email,
  p.grant_number AS opportunity_id,
  i.value AS grant_id,
  CASE
    p.visibility
    WHEN 0 THEN 'ORGANIZATIONAL'
    WHEN 1 THEN 'PUBLIC'
    ELSE 'PRIVATE'
  END AS visibility,
  CASE
    WHEN p.visibility = 2
    THEN true ELSE false
  END AS is_test_plan,
  CASE
    p.complete
    WHEN 1 THEN 'COMPLETE'
    ELSE 'DRAFT' END AS status,
  CASE
    WHEN p.org_id IS NULL THEN NULL
    WHEN ro.id IS NULL THEN CONCAT('https://dmptool.org/affiliations/', o.id)
    ELSE ro.ror_id
  END AS org_id,
  CASE
    WHEN p.funder_id IS NULL THEN NULL
    WHEN funder_rors.id IS NULL THEN CONCAT('https://dmptool.org/affiliations/', funders.id)
    ELSE funder_rors.ror_id
  END AS funder_id
FROM {{ var('source_db') }}.plans p
LEFT JOIN {{ var('source_db') }}.roles r ON p.id = r.plan_id AND r.access = 15 AND r.active = 1
LEFT JOIN {{ var('source_db') }}.users u ON r.user_id = u.id
LEFT JOIN {{ var('source_db') }}.languages l ON p.language_id = l.id
INNER JOIN {{ var('source_db') }}.orgs o ON p.org_id = o.id
LEFT OUTER JOIN {{ var('source_db') }}.registry_orgs ro ON o.id = ro.org_id
LEFT JOIN {{ var('source_db') }}.identifiers i ON i.id = p.grant_id
LEFT JOIN {{ var('source_db') }}.orgs AS funders ON p.funder_id = funders.id
LEFT OUTER JOIN {{ var('source_db') }}.registry_orgs funder_rors ON funders.id = funder_rors.org_id
LEFT JOIN owner_emails oe ON p.id = oe.id
ORDER BY p.id;

JINJA_END;
