--   Seed data for Project/Plan Member Roles

MODEL (
  name intermediate.member_roles,
  kind SEED (
    path '../../seeds/member_roles.csv'
  ),
  columns (
    label VARCHAR(255),
    uri VARCHAR(255),
    description VARCHAR(255),
    display_order INT,
    is_default BOOLEAN,
  ),
  audits (
    unique_values(columns := (uri, label)),
  ),
  enabled true
);
