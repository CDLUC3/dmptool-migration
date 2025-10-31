MODEL (
  name intermediate.plans,
  kind FULL,
  columns (
    `id` int,
    `dmp_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    `template_id` int,
    `title` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    `research_domain_id` bigint,
    `start_date` datetime,
    `end_date` datetime,
    featured BOOLEAN,
    `created_at` datetime,
    `updated_at` datetime,
    `grant_number` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    `funding_status` int,
    `language` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    `owner_email` varchar(80) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    `opportunity_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    `grant_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    `visibility` varchar(14),
    `is_test_plan` int,
    `status` varchar(8),
    `org_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    `funder_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci
  ),
  enabled true
);

WITH owner_emails AS (
  SELECT
    oe.id,
    oe.owner_email
  FROM (
    SELECT
      p.id,
      TRIM(u.email) AS owner_email,
      ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY r.created_at DESC) AS row_num,
    FROM dmp.users u
    INNER JOIN dmp.roles r ON r.user_id = u.id AND r.access = 15 AND r.active = 1
    INNER JOIN dmp.plans p ON r.plan_id = p.id
  ) AS oe
  WHERE oe.row_num = 1
)

SELECT
  p.id,
  p.dmp_id,
  p.template_id, -- could use this to query dmp.templates to get the id and version
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
FROM dmp.plans p
LEFT JOIN dmp.roles r ON p.id = r.plan_id AND r.access = 15 AND r.active = 1
LEFT JOIN dmp.users u ON r.user_id = u.id
LEFT JOIN dmp.languages l ON p.language_id = l.id
INNER JOIN dmp.orgs o ON p.org_id = o.id
LEFT OUTER JOIN dmp.registry_orgs ro ON o.id = ro.org_id
LEFT JOIN dmp.identifiers i ON i.id = p.grant_id
LEFT JOIN dmp.orgs AS funders ON p.funder_id = funders.id
LEFT OUTER JOIN dmp.registry_orgs funder_rors ON funders.id = funder_rors.org_id
LEFT JOIN owner_emails oe ON p.id = oe.id
ORDER BY p.id;
