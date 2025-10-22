--  This model matches templates from the old system to the new system based on their order
--  within templates.
MODEL (
  name intermediate.templates,
  kind FULL,
  columns (
    family_id INT NOT NULL,
    old_template_id INT NOT NULL,
    old_org_id INT,
    old_created_at DATETIME,
    customization_of_family_id INT,
    best_practice BOOLEAN,
    visibility INT,
    version INT,
    old_updated_at DATETIME,
    is_published BOOLEAN,
    was_published BOOLEAN,
    is_current_template BOOLEAN,
    new_created_by_id INT
  )
);

WITH org_creator AS (
  SELECT
    u.org_id,
    COALESCE(mu.id, @VAR('super_admin_id')) AS user_id
  FROM dmp.users AS u
    INNER JOIN dmp.users_perms AS up ON u.id = up.user_id AND up.perm_id = 6
      LEFT JOIN intermediate.users AS mu ON u.email = mu.email
  WHERE u.org_id IS NOT NULL
  QUALIFY ROW_NUMBER() OVER (PARTITION BY u.org_id ORDER BY u.created_at DESC) = 1
),

current_ids AS (
  SELECT t.family_id, MAX(t.id) AS current_id
  FROM dmp.templates AS t
  GROUP BY t.family_id
)

SELECT
  t.family_id,
  t.id AS old_template_id,
  t.org_id AS old_org_id,
  t.created_at AS old_created_at,
  t.customization_of AS customization_of_family_id,
  t.is_default AS best_practice,
  t.visibility AS visibility,
  t.version AS version,
  t.updated_at AS old_updated_at,
  t.published AS is_published,
  CASE
    WHEN t.published = 1 THEN FALSE
    WHEN t.published = 0
      AND t.id != (SELECT ci.current_id FROM current_ids AS ci WHERE ci.family_id = t.family_id) THEN TRUE
    ELSE FALSE
  END AS was_published,
  (t.id = (SELECT ci.current_id
            FROM current_ids AS ci
            WHERE ci.family_id = t.family_id)) AS is_current_template,
  oc.user_id AS new_created_by_id
FROM dmp.templates t
  LEFT JOIN org_creator oc ON t.org_id = oc.org_id
