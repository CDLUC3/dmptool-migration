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
FROM dmp.contributors c
  INNER JOIN dmp.plans p ON c.plan_id = p.id
  LEFT JOIN dmp.orgs o ON c.org_id = o.id
    LEFT JOIN dmp.registry_orgs ro ON o.id = ro.org_id
  LEFT JOIN dmp.identifiers orcid ON c.id = orcid.identifiable_id
      AND orcid.identifiable_type = 'Contributor' AND orcid.identifier_scheme_id = 1;