MODEL (
  name migration.users,
  kind FULL,
  enabled true,
  audits (
    assert_row_count(dmp_table:='users', blocking := false),
  )
);

SELECT
  dmp.users.id,
  dmp.users.firstname,
  dmp.users.surname,
  dmp.users.email,
  dmp.users.created_at,
  dmp.users.updated_at,
  dmp.users.accept_terms,
  dmp.users.last_sign_in_at,
  dmp.languages.abbreviation AS language,
  o.value AS orcid,
  s.value AS sso_id,
  CASE
    WHEN dmp.users.org_id IS NULL THEN NULL
    WHEN dmp.registry_orgs.id IS NULL THEN CONCAT('https://dmptool.org/affiliations/', dmp.orgs.id)
    ELSE dmp.registry_orgs.ror_id
  END AS org_id,
  (SELECT perm_id FROM dmp.users_perms WHERE dmp.users_perms.user_id = dmp.users.id AND perm_id = 10) is_super,
  (SELECT COUNT(perm_id) FROM dmp.users_perms WHERE dmp.users_perms.user_id = dmp.users.id AND perm_id != 10) is_admin
FROM dmp.users
  LEFT JOIN dmp.languages ON dmp.users.language_id = dmp.languages.id
  INNER JOIN dmp.orgs ON dmp.users.org_id = dmp.orgs.id
  LEFT JOIN dmp.registry_orgs ON dmp.orgs.id = dmp.registry_orgs.org_id
  LEFT JOIN dmp.identifiers o ON o.identifiable_type = 'User' AND o.identifiable_id = dmp.users.id AND o.identifier_scheme_id = 1
  LEFT JOIN dmp.identifiers s ON s.identifiable_type = 'User' AND s.identifiable_id = dmp.users.id AND s.identifier_scheme_id = 2;
