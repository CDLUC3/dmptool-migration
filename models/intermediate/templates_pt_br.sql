--   Seed data to tell us which templates are in pt-BR

MODEL (
  name intermediate.templates_pt_br,
  kind SEED (
    path '../../seeds/templates_pt_br.csv'
  ),
  columns (
    family_id INT
  ),
  audits (
    unique_values(columns := (family_id)),
  ),
  enabled true
);
