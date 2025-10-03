# Data Migration Plan
This document outlines the plan to migrate data from the existing Rails-based DMP Tool system to the
new Node.js-based DMP Tool system.

**These migrations cannot be run until [USERS migration](Users.md), [AFFILIATIONS migration](Affiliations.md) and [TEMPLATE migration](Template.md) have been completed.**


After the migration we will need to run scripts to assign a DMP ID to all the plans with a `TEMP#<id>` placeholder value. We then need to generate the DynamoDB common standard JSON records.

---
**IMPORTANT:**
There are 36 plans with a NULL `org_id`. We could run an additional pass/query to derive the affiliation information from the plan's owner. 
The records however are older than 2020, have not been registered and are mostly test plans (11 are private). 
Suggest we ignore these:
`SELECT id, title, visibility, updated_at FROM plans WHERE org_id IS NULL order by updated_at desc;`
---

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
  CASE WHEN plans.visibility = 2 THEN true ELSE false END as is_test_plan,
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
- is_test_plan ----> projects.isTestProject
- start_date ----> projects.startDate
- end_date ----> projects.endDate
- created_at ----> projects.created
- updated_at ----> projects.modified
```

There are also some fields that will require special handling before they can be moved into the `projects` table:
```
- projects.research_domain_id -- projects.researchDomainId (use id mapping defined above in [RESEARCH DOMAINS](Misc.md) section)
```

These records can be mapped to the `plans` table as:
```
- templateId
- projectId
- dmp_id ----> plans.dmpId
- title ----> projects.title
- featured ----> plans.featured
- language ----> plans.languageId
- status ----> plans.status
- visibility ----> plans.visibility
- registered_at ----> plans.registered
- created_at ----> plans.created
- updated_at ----> plans.modified
```

There are also some fields that will require special handling before they can be moved into the `plans` table:
```
- plans.registeredById -- (user the registered_by email to lookup the id in the new system)
```

These records can be mapped to the `projectFundings` table as:
```
- projectId
- funding_status ----> projectFundings.status
- funder_id ----> projectFundings.affiliationId
- grant_number ----> projectFundings.funderOpportunityNumber
- grant_id ----> projectFundings.grantId
- created_at ----> projectFundings.created
- updated_at ----> projectFundings.modified
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

***There are 77 Uploaded Plans in this table in the old system. They are "uploaded" DMPs from the pilot project. We will hold off on these for now***

These will be good candidates for testing out the new system's API since the data is stored as JSON.

FK: drafts.userId

drafts.draft_id
drafts.dmp_id
drafts.metadata
drafts.created_at  
drafts.updated_at

Do NOT migrate over "pending" related works.