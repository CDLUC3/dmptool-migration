MODEL (
  name intermediate.plan_owners,
  kind FULL,
  columns (
    projectId INT UNSIGNED NOT NULL,
    old_plan_id INT UNSIGNED NOT NULL,
    affiliationId VARCHAR(255),
    givenName VARCHAR(255),
    surName VARCHAR(255),
    orcid VARCHAR(255),
    email VARCHAR(255),
    createdById INT UNSIGNED NOT NULL,
    created DATETIME NOT NULL DEFAULT CURRENT_DATE,
    modifiedById INT UNSIGNED NOT NULL,
    modified DATETIME NOT NULL DEFAULT CURRENT_DATE,
    add_to_members BOOLEAN NOT NULL DEFAULT FALSE
  ),
  enabled true
);

-- Get all the project owners as members
SELECT
  p.id AS projectId,
  ip.id AS old_plan_id,
  u.org_id AS affiliationId,
  u.firstname AS givenName,
  u.surname AS surName,
  u.orcid AS orcid,
  ip.owner_email AS email,
  u.id AS createdById,
  ip.created_at AS created,
  u.id AS modifiedById,
  ip.updated_at AS modified,
  (c.id IS NULL) AS add_to_members
FROM migration.projects AS p
  JOIN intermediate.plans AS ip ON p.old_plan_id = ip.id
    LEFT JOIN intermediate.users AS u ON ip.owner_email = u.email
      LEFT JOIN intermediate.contributors AS c
        ON ip.owner_email = c.email
        OR u.orcid = c.orcid
        OR (u.firstname = c.first_name AND u.surname = c.last_name);
