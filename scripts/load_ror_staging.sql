SET enable_progress_bar = true;

-- Loads settings from environment variables: https://duckdb.org/docs/stable/core_extensions/mysql.html#configuration
ATTACH '' AS mysql (TYPE mysql);

CREATE OR REPLACE TABLE mysql.migration.ror_staging (
  uri VARCHAR,
  provenance VARCHAR,
  name VARCHAR,
  displayName VARCHAR,
  searchName VARCHAR,
  funder BOOLEAN,
  fundrefId VARCHAR,
  homepage VARCHAR,
  acronyms JSON,
  aliases JSON,
  types JSON
);

INSERT INTO mysql.migration.ror_staging
SELECT
  uri,
  provenance,
  name,
  displayName,
  searchName,
  funder,
  fundrefId,
  homepage,
  array_to_json(acronyms) AS acronyms,
  array_to_json(aliases) AS aliases,
  array_to_json(types) AS types
FROM read_json('./data/affiliations.json');
