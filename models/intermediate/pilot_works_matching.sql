MODEL (
  name intermediate.pilot_works_matching,
  kind FULL,
  columns (
    dmpId VARCHAR(255),
    workId VARCHAR(255),
    isPilotPlan BOOLEAN,
    affiliationId VARCHAR(255),
    status VARCHAR(255),
    weightedScore INT,
    notes TEXT,
    provenance VARCHAR(255),
    workType VARCHAR(255),
    publisher VARCHAR(255),
    container JSON,
    publicationDate DATE,
    title VARCHAR(512),
    location VARCHAR(255),
    authors JSON
  ),
  enabled true
);

SELECT
  gwm.dmp_id AS dmpId,
  (pd.dmp_id IS NOT NULL) AS isPilotPlan,
  CASE gwm.affiliation_name
    WHEN 'Arizona State University' THEN 'https://ror.org/03efmqc40'
    WHEN 'Northwestern University' THEN 'https://ror.org/000e0be47'
    WHEN 'University of California, Berkeley' THEN 'https://ror.org/01an7q238'
    WHEN 'University of California, Riverside' THEN 'https://ror.org/03nawhv43'
    WHEN 'University of California, Santa Barbara' THEN 'https://ror.org/02t274463'
    WHEN 'University of Colorado Boulder' THEN 'https://ror.org/02ttsq026'
    ELSE 'FOO'
  END AS affiliationId,
  gwm.related_work AS workId,
  CASE LOWER(TRIM(gwm.is_a_match))
    WHEN 'no' THEN 'rejected'
    WHEN 'yes' THEN 'accepted'
    WHEN 'unsure' THEN 'pending'
    ELSE UPPER(gwm.is_a_match)
  END AS status,
  gwm.weighted_score AS weightedScore,
  gwm.notes,
  gwm.provenance,
  gwm.type AS workType,
  gwm.publisher,
  CASE
    WHEN gwm.container IS NULL OR TRIM(gwm.container) = '' THEN '[]'
    WHEN gwm.container LIKE '[%' THEN gwm.container
    ELSE CONCAT('["', gwm.container, '"]')
  END AS container,
  gwm.publication_date AS publicationDate,
  gwm.title,
  gwm.location,
  JSON_EXTRACT(
    CONCAT(
      '["',
      REGEXP_REPLACE(gwm.authors, ' \\| ', '", "'),
      '"]'
    ),
    '$'
  ) AS authors
FROM seeds.gt_works_matching gwm
  LEFT JOIN intermediate.pilot_drafts pd ON gwm.dmp_id = pd.dmp_id;
