--  This model matches templates from the old system to the new system based on their order
--  within templates.
MODEL (
  name intermediate.templates,
  kind FULL,
  columns (
    family_id INT NOT NULL,
    customization_of_family_id INT,
    best_practice BOOLEAN,
    creator_user_id INT,
    is_published BOOLEAN,
    was_published BOOLEAN,
    old_template_id INT NOT NULL,
    new_template_id INT,
    matchConfidence DECIMAL(3,2),
    unmatchedFlag BOOLEAN
  )
);

WITH never_published AS (
  SELECT tmplt.family_id, COUNT(t.id) nbr_versions
  FROM dmp.templates AS tmplt
    INNER JOIN dmp.templates AS t ON tmplt.family_id = t.family_id
  WHERE tmplt.version = 0 AND tmplt.published = 0
  GROUP BY tmplt.id, tmplt.family_id
  HAVING nbr_versions = 1
)

WITH unpublished_currents (
  SELECT t.id
  FROM dmp.templates AS t
  WHERE t.published = 0
    AND t.id IN (SELECT MAX(t2.id) FROM dmp.templates AS t2 GROUP BY t2.family_id)
)

WITH ordered_old AS (
  SELECT
    t.id AS old_template_id,
    t.is_default AS best_practice,
    LOWER(TRIM(t.title)) AS title,
    t.family_id AS family_id,
    t.customization_of AS customization_of_family_id,
    t.published AS is_published,
    CASE
      WHEN t.published = 1 THEN FALSE
      WHEN t.published = 0
        AND t.id != (SELECT MAX(t2.id) FROM dmp.templates AS t2 WHERE t2.family_id = t.family_id) THEN TRUE
      ELSE FALSE
    END AS was_published
  FROM dmp.templates t
    LEFT JOIN never_published np ON t.family_id = np.family_id
    LEFT JOIN unpublished_currents uc ON t.id = uc.id
),
ordered_new AS (
  SELECT
    t.id AS new_template_id,
    t.family_id AS family_id,
    t.createdById AS createdById,
  FROM migration.templates t
)

SELECT
  o.family_id,
  o.customization_of_family_id,
  o.best_practice,
  n.createdById AS creator_user_id,
  o.is_published,
  o.was_published,
  o.old_template_id,
  n.new_template_id,
  CASE
    WHEN n.new_template_id IS NOT NULL THEN 0.8
    ELSE 0.0
  END AS matchConfidence,
  CASE
    WHEN n.new_template_id IS NULL THEN TRUE
    ELSE FALSE
  END AS unmatchedFlag
FROM ordered_old o
  LEFT JOIN ordered_new n
  ON o.family_id = n.family_id;
