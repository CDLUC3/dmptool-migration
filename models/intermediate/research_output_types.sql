--   Seed data for Research Output Types

MODEL (
  name intermediate.research_output_types,
  kind SEED (
    path '../../seeds/research_output_types.csv'
  ),
  columns (
    value VARCHAR(255),
    name VARCHAR(255),
    description TEXT
  ),
  audits (
    unique_values(columns := (value, name)),
  ),
  enabled true
);
