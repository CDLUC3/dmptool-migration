### CONTRIBUTORS (94,883 rows)
-------------------
The mapping for `contributors` in the old system to the `members` table in the new system is fairly straightforward.

We will use the `plans.createdById` (the Plan's owner) from the new system as the `createdById` and `modifiedById` for all of these records.

We can run the following query to retrieve the data:
```
SELECT contributors.id, plans.id AS plan_id, contributors.email, contributors.roles,
  contributors.created_at, contributors.updated_at,
  SUBSTRING_INDEX(contributors.name, ' ', 1) AS first_name,
  SUBSTRING_INDEX(contributors.name, ' ', -1) AS last_name,
  CASE 
    WHEN contributors.org_id IS NULL THEN NULL
    WHEN registry_orgs.id IS NULL THEN CONCAT('https://dmptool.org/affiliations/', contributors.org_id)
    ELSE registry_orgs.ror_id
  END AS affiliation_id
FROM contributors
  INNER JOIN plans ON contributors.plan_id = plans.id
  LEFT JOIN orgs ON contributors.org_id = orgs.id
    LEFT JOIN registry_orgs ON orgs.id = registry_orgs.org_id
  LEFT JOIN identifiers AS orcid ON contributors.id = orcid.identifiable_id 
      AND orcid.identifiable_type = 'Contributor' AND orcid.identifier_scheme_id = 1;
```

This record can be mapped to the `projectMembers` table as:
```
- projectId
- affiliation_id ----> projectMembers.affiliationId
- firstname ----> projectMembers.givenName
- surname ----> projectMembers.surName
- orcid ----> projectMembers.orcid
- email ----> projectMembers.email
- created_at ----> projectMembers.created
- updated_at ----> projectMembers.modified
```

Then the `role` from the old system can be used to populate the `projectMemberRoles` table and `planMemberRoles` tables. 
It is a bit flag and will require some special handling to determine what equivalent roles to assign in the new system. 

Based on the role id, we can add multiple entries in the `projectMemberRoles` table for each contributor.
For example if the `roles` value is `3` we would add 2 entries in the `projectMemberRoles` table.

Here is the bit flag mapping:
```
BASE_URL = 'https://credit.niso.org/contributor-roles'

VALUE ----> NEW SYSTEM ROLE(S)
------------------------------------------------------------------------------------------------------
- 1 --> <BASE_URL>/data-curation
- 2 --> <BASE_URL>/investigation
- 3 --> <BASE_URL>/data-curation + <BASE_URL>/investigation
- 4 --> <BASE_URL>/project-administration
- 5 --> <BASE_URL>/data-curation + <BASE_URL>/project-administration
- 6 --> <BASE_URL>/investigation + <BASE_URL>/project_administration
- 7 --> <BASE_URL>/data_curation + <BASE_URL>/investigation + <BASE_URL>/project_administration
- 8 --> http://dmptool.org/contributor_roles/other
- 9 --> <BASE_URL>/data_curation + http://dmptool.org/contributor_roles/other
- 10 --> <BASE_URL>/investigation + http://dmptool.org/contributor_roles/other
- 11 --> <BASE_URL>/data_curation + <BASE_URL>/investigation + http://dmptool.org/contributor_roles/other
- 12 --> <BASE_URL>/project_administration + http://dmptool.org/contributor_roles/other
- 13 --> <BASE_URL>/data_curation + <BASE_URL>/project_administration + http://dmptool.org/contributor_roles/other
- 14 --> <BASE_URL>/investigation + <BASE_URL>/project_administration + http://dmptool.org/contributor_roles/other
- 15 --> <BASE_URL>/data_curation + <BASE_URL>/investigation + <BASE_URL>/project_administration + http://dmptool.org/contributor_roles/other
```
