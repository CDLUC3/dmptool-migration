MODEL (
  name intermediate.project_members,
  kind FULL,
  audits (
    unique_values(columns := (id), blocking := false)
  ),
  enabled true
);

WITH default_super_admin AS (
  SELECT id
  FROM intermediate.users
  WHERE role = 'SUPERADMIN'
  ORDER BY id DESC LIMIT 1
),

primary_project_members AS (
  SELECT
    ROW_NUMBER() OVER () AS id,
    u.id AS userId,
    NULL AS oldRoleId,
    15 AS memberRoleId,
    p.id AS projectId,
    u.org_id AS affiliationId,
    u.firstname AS givenName,
    u.surname AS surName,
    u.orcid AS orcid,
    p.owner_email AS email,
    COALESCE(u.id, (SELECT id FROM default_super_admin)) AS createdById,
    u.created_at AS created,
    COALESCE(u.id, (SELECT id FROM default_super_admin)) AS modifiedById,
    u.updated_at AS modified,
    1 AS isPrimaryContact
  FROM intermediate.plans p
  INNER JOIN intermediate.users u ON p.owner_email = u.email
),

max_user_id AS (
  SELECT COALESCE(MAX(u.id), 0) AS max_id
  FROM primary_project_members u
),

default_member_role AS (
  SELECT id
  FROM migration.member_roles
  WHERE isDefault = 1
  LIMIT 1
),

other_project_members AS (
  SELECT
    m.max_id + ROW_NUMBER() OVER () AS id,
    NULL AS userId,
    c.roles AS oldRoleId,
    (SELECT id FROM default_member_role) AS memberRoleId,
    c.plan_id AS projectId,
    c.affiliation_id AS affiliationId,
    c.first_name AS givenName,
    c.last_name AS surName,
    c.orcid AS orcid,
    c.email AS email,
    ppm.userId AS createdById,
    c.created_at AS created,
    ppm.userId AS modifiedById,
    c.updated_at AS modified,
    0 AS isPrimaryContact
  FROM intermediate.contributors c
  LEFT JOIN primary_project_members ppm ON ppm.projectId = c.plan_id
  CROSS JOIN max_user_id m
)

SELECT * FROM primary_project_members
UNION ALL
SELECT * FROM other_project_members