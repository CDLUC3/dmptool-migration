# Data Migration Plan
This document outlines the plan to migrate data from the existing Rails-based DMP Tool system to the
new Node.js-based DMP Tool system.

**These migrations cannot be run until [USERS migration](Users.md), [AFFILIATIONS migration](Affiliations.md) and [TEMPLATE migration](Template.md) have been completed.**

After the migration we will need to run a script to generate the DMPHub JSON records

### PLANS (136,226 rows)
---
The new system consists of projects, plans and fundings. Every project may have multiple plans and multiple fundings and each plan has a selected subset of fundings from its parent project. The old system though only has the concept of plans.

For the migration we will make the following assumptions:
- Every plan in the old system will become a single project+plan+funding in the new system. Meaning that the single record in the old system will be split across a new project, and a plan and funding that belong to that project
- Every plan will use the project's funding
- We will ignore the Feedback information for now
- We will use the `users.id` (the Plan's owner) as the `createdById` and `modifiedById` for all of these tables. Use the `owner` in the query below to fetch the user's id from the table in the new system.

We can get this information with the following query:
```
SELECT plans.id, plans.dmp_id, plans.template_id, plans.title, plans.description, plans.research_domain_id,
  plans.start_date, plans.end_date, plans.featured, plans.created_at, plans.updated_at, 
  languages.abbreviation AS language, roles.user_id AS owner_id, users.email as owner,
  plans.grant_number AS opportunity_id, identifiers.value AS grant_id,
  CASE plans.visibility WHEN 0 THEN 'ORGANIZATIONAL' WHEN 1 THEN 'PUBLIC' ELSE 'PRIVATE' END AS visibility,
  CASE plans.complete WHEN 1 THEN 'COMPLETE' ELSE 'DRAFT' END AS status,
  CASE 
  WHEN plans.org_id IS NULL THEN NULL
  WHEN registry_orgs.id IS NULL THEN CONCAT('https://dmptool.org/affiliations/', orgs.id) 
  ELSE registry_orgs.ror_id 
  END AS org_id,
  CASE 
  WHEN plans.funder_id IS NULL THEN NULL
  WHEN funder_rors.id IS NULL THEN CONCAT('https://dmptool.org/affiliations/', funders.id) 
  ELSE funder_rors.ror_id 
  END AS funder_id
FROM plans 
  LEFT JOIN roles ON plans.id = roles.plan_id AND roles.access = 15 AND roles.active = 1
    LEFT JOIN users ON roles.user_id = users.id
  LEFT JOIN languages ON plans.language_id = languages.id
  INNER JOIN orgs ON plans.org_id = orgs.id
    LEFT OUTER JOIN registry_orgs ON orgs.id = registry_orgs.org_id
  LEFT JOIN identifiers ON identifiers.id = plans.grant_id
  LEFT JOIN orgs AS funders ON plans.funder_id = funders.id
    LEFT OUTER JOIN registry_orgs funder_rors ON funders.id = funder_rors.org_id
ORDER BY plans.id;
```

These records can be mapped to the `projects` table as:
```
- title ----> projects.title
- description ----> projects.abstractText
- start_date ----> projects.startDate
- end_date ----> projects.endDate
- created_at ----> projects.created
- updated_at ----> projects.modified
```

There are also some fields that will require special handling before they can be moved into the `projects` table:
```
- projects.research_domain_id -- projects.researchDomainId (use id mapping defined above in [RESEARCH DOMAINS](Misc.md) section)
- projects.isTestProject -- (if visibility == 2 then true else false)
```

These records can be mapped to the `plans` table as:
```
- templateId
- projectId
- title ----> projects.title
- featured ----> plans.featured
- language ----> plans.languageId
- created_at ----> plans.created
- updated_at ----> plans.modified
```

There are also some fields that will require special handling before they can be moved into the `plans` table:
```
- plans.dmpId -- (if `dmp_id` present, use as-is, otherwise we need to generate a placeholder 
            something like `CONCAT("TEMP#", id)`)
- plans.registered -- (if `dmp_id` is present use the `updated_at` value otherwise NULL)
- plans.registeredById -- (if `dmp_id` is present use the plan's owner id otherwise NULL)
- plans.status -- (if status == 1 then "COMPLETE" otherwise "DRAFT")
- plans.visibility -- (CASE WHEN visibility == 0 THEN "ORGANIZATIONAL" WHEN visibility == 1 "PUBLIC" ELSE "PRIVATE" END)
```

These records can be mapped to the `projectFundings` table as:
```
- projectId
- funder_id ----> projectFundings.affiliationId
- grant_number ----> projectFundings.funderOpportunityNumber
- grant_id ----> projectFundings.grantId
- created_at ----> projectFundings.created
- updated_at ----> projectFundings.modified
```

There are also some fields that will require special handling before they can be moved into the `projectFundings` table:
```
projectFundings.status -- (CASE WHEN funding_status = 2 THEN "DENIED" WHEN funding_status = 1 THEN "GRANTED" ELSE "PLANNED" END)
```

These records can be mapped to the `planFundings` table as:
```
- planId
- projectFundingId
- created_at ----> planFundings.created
- updated_at ----> planFundings.modified
```

We also need to create the initial `projectMembers` and `planMembers` records. The old system doesn't have these (it does it behind the scenes when generating the DOI records). To add them, we can use the owner information in our query combined with a query on the new system's `users` table.

This record can be mapped to the `projectMembers` table as:
```
- projectId
- owner_email ----> projectMembers.email
- users.orcid ----> projectMembers.orcid
- users.givenName ----> projectMembers.givenName
- users.surName ----> projectMembers.surName
- users.affiliationId ----> projectMembers.affiliationId
- created_at ----> projectMembers.created
- updated_at ----> projectMembers.modified
- isPrimaryContact -- (default to true)
```

Then map the following in the `projectMemberRoles` table:
```
projectMemberId
memberRoleId -- (default to 15 "Other")
```

Then create the `planMemberRoles` table entry as:
```
planId
projectMemberId
```

Then map the following in the `planMemberRoles` table:
```
planMemberId
memberRoleId -- (default to 15 "Other")
```

#### Post migration

We will need to auto generate/reserve DMP Ids for the ones we have added a temporary id for. To do this we will need to:
- Run script to auto-generate DMP Ids

#### Issues
There are 36 plans with a NULL `org_id`. We could run an additional pass/query to derive the affiliation information from the plan's owner. The records however are older than 2020, have not been registered, and are mostly test plans (11 are private). `SELECT id, title, visibility, updated_at FROM plans WHERE org_id IS NULL order by updated_at desc;`

Suggest we ignore these.


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

Then the `role` from the old system can be used to populate the `projectMemberRoles` table and `planMemberRoles` tables. It is a bit flag and will require some special handling to determine what equivalent roles to assign in the new system. Here is the bit flag mapping:
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

### ANSWERS (308,909 rows)
---

***TBD - Once we've mapped out all of the template content***

FK: answers.plan_id
FK: answers.question_id
FK: answers.user_id

answers.text
answers.created_at
answers.updated_at

### ANSWERS_QUESTION_OPTIONS (13,897 rows)
---

***TBD - Once we've mapped out all of the template content***

FK: answers_question_options.answer_id
FK: answers_question_options.question_option_id

### DRAFTS (77 rows)
---

***There fewer than 100 Plans in this table in the old system. They are "uploaded" DMPs from the pilot project. We will hold off on these for now***

These will be good candidates for testing out the new system's API since the data is stored as JSON.

FK: drafts.userId

drafts.draft_id
drafts.dmp_id
drafts.metadata
drafts.created_at  
drafts.updated_at

Do NOT migrate over "pending" related works.
