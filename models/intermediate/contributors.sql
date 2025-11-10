MODEL (
  name intermediate.contributors,
  kind FULL,
  columns (
    id INT,
    plan_id INT,
    email VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    orcid VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    roles INT,
    created_at DATETIME,
    updated_at DATETIME,
    first_name VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    last_name VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    affiliation_id VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci
  ),
  enabled true
);

JINJA_QUERY_BEGIN;

SELECT
  c.id,
  p.id AS plan_id,
  c.email,
  orcid.value AS orcid,
  c.roles,
  c.created_at,
  c.updated_at,
  SUBSTRING_INDEX(c.name, ' ', 1) AS first_name,
  SUBSTRING_INDEX(c.name, ' ', -1) AS last_name,
  CASE
    WHEN c.org_id IS NULL THEN NULL
    WHEN ro.id IS NULL THEN CONCAT('https://dmptool.org/affiliations/', c.org_id)
    ELSE ro.ror_id
  END AS affiliation_id
FROM {{ var('source_db') }}.contributors c
  INNER JOIN {{ var('source_db') }}.plans p ON c.plan_id = p.id
  LEFT JOIN {{ var('source_db') }}.orgs o ON c.org_id = o.id
    LEFT JOIN {{ var('source_db') }}.registry_orgs ro ON o.id = ro.org_id
  LEFT JOIN {{ var('source_db') }}.identifiers orcid ON c.id = orcid.identifiable_id
      AND orcid.identifiable_type = 'Contributor' AND orcid.identifier_scheme_id = 1

JINJA_END;