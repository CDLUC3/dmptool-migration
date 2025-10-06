# Data Migration Plan
This document outlines the plan to migrate data from the existing Rails-based DMP Tool system to the
new Node.js-based DMP Tool system.

**These migrations cannot be run until [USERS migration](Users.md), [AFFILIATIONS migration](Affiliations.md) and [TEMPLATE migration](Templates.md) have been completed.**


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

We can get this information with the following query:
```
SELECT plans.id, plans.dmp_id, plans.template_id, plans.title, plans.description, plans.research_domain_id,
  plans.start_date, plans.end_date, plans.featured, plans.created_at, plans.updated_at, 
  languages.abbreviation AS language, 
  (SELECT u.email
   FROM users AS u
     INNER JOIN roles ON roles.user_id = u.id AND roles.access = 15 AND roles.active = 1
       INNER JOIN plans ON roles.plan_id = plans.id
   WHERE plans.id = answers.plan_Id
   ORDER BY roles.created_at DESC
   LIMIT 1
  ) AS owner_email,
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
- createdById -- (use the owner_email to lookup the id in the new system)
- modifiedById -- (use the owner_email to lookup the id in the new system)
- research_domain_id -- projects.researchDomainId (use id mapping defined above in [RESEARCH DOMAINS](Misc.md) section)
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
- createdById -- (use the owner_email to lookup the id in the new system)
- modifiedById -- (use the owner_email to lookup the id in the new system)
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
- createdById -- (use the owner_email to lookup the id in the new system)
- modifiedById -- (use the owner_email to lookup the id in the new system)
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
- projectMemberId
- createdById -- (use the owner_email to lookup the id in the new system)
- modifiedById -- (use the owner_email to lookup the id in the new system)
- memberRoleId -- (default to 15 "Other")
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

### ANSWERS (542,904 rows)
---

We can get this information with the following query:
```sql
SELECT answers.plan_id, answers.question_id, sections.id = section_id,
  (SELECT u.email
   FROM users AS u
     INNER JOIN roles ON roles.user_id = u.id AND roles.access = 15 AND roles.active = 1
       INNER JOIN plans ON roles.plan_id = plans.id
   WHERE plans.id = answers.plan_Id
   ORDER BY roles.created_at DESC
   LIMIT 1
  ) AS user,
  CASE questions.question_format_id
    WHEN 2 THEN 
      CONCAT('{"type":"text","answer":', CONCAT(answers.text, '","meta":{"schemaVersion":"1.0"}}'))
    WHEN 3 THEN 
      CONCAT(
        '{"type":"radioButtons","answer":', 
        CONCAT(
          CONCAT(
            '"',
            CONCAT(
              GROUP_CONCAT(question_options.text),
              '"'
            )
          ),
          ',"meta":{"schemaVersion":"1.0"}}'
        )
      )
    WHEN 4 THEN 
      CONCAT(
        '{"type":"checkBoxes","answer":[', 
        CONCAT(
          GROUP_CONCAT(CONCAT('"', CONCAT(question_options.text, '"'))),
          '],"meta":{"schemaVersion":"1.0"}}'
        )
      )
    WHEN 5 THEN
      CONCAT(
        '{"type":"selectBox","answer":', 
        CONCAT(
          CONCAT(
            '"',
            CONCAT(
              GROUP_CONCAT(question_options.text),
              '"'
            )
          ),
          ',"meta":{"schemaVersion":"1.0"}}'
        )
      )
    WHEN 6 THEN
      CONCAT(
        '{"type":"multiselectBox","answer":[', 
        CONCAT(
          GROUP_CONCAT(CONCAT('"', CONCAT(question_options.text, '"'))),
          '],"meta":{"schemaVersion":"1.0"}}'
        )
      )
    ELSE
      CONCAT('{"type":"textArea","answer":"',CONCAT(answers.text, '","meta":{"schemaVersion":"1.0"}}'))
  END AS answer_json,
  answers.created_at, answers.updated_at
FROM answers
  LEFT JOIN answers_question_options ON answers.id = answers_question_options.answer_id
    LEFT JOIN question_options ON answers_question_options.question_option_id = question_options.id    
  INNER JOIN plans ON answers.plan_id = plans.id
  INNER JOIN users ON answers.user_id = users.id
  INNER JOIN questions ON answers.question_id = questions.id
    INNER JOIN sections ON questions.section_id = sections.id
GROUP BY answers.plan_id, answers.question_id, users.email, questions.question_format_id, 
  sections.id, answers.created_at, answers.updated_at;
```

These records can be mapped to the `answers` table as:
```
- answer_json ----> answers.json
- created_at ----> answers.created
- updated_at ----> answers.modified
```

There are also some fields that will require special handling before they can be moved into the `answers` table:
```
- planId -- (we can get this from the plans mapping table with the plan_id)
- versionedQuestionId -- (we can get this from the questions mapping table with the question_id)
- versionedSectionId -- (we can get this from the sections mapping table with the section_id)
- createdById -- (use the answer's user email to lookup the id in the new system)
- modifiedById -- (use the answer's user email to lookup the id in the new system)
```

### ANSWER COMMENTS (15,428 rows)
---
We can get this information with the following query:
```sql
SELECT answers.plan_id, notes.answer_id, users.email as commenter_email,
  (SELECT u.email
   FROM users AS u
     INNER JOIN roles ON roles.user_id = u.id AND roles.access = 15 AND roles.active = 1
       INNER JOIN plans ON roles.plan_id = plans.id
   WHERE plans.id = answers.plan_Id
   ORDER BY roles.created_at DESC
   LIMIT 1
  ) AS plan_owner,
  notes.id, notes.text, notes.created_at, notes.updated_at
FROM notes
  INNER JOIN users ON notes.user_id = users.id
    LEFT JOIN users_perms ON users.id = users_perms.user_id AND users_perms.perm_id = 6
  INNER JOIN answers ON notes.answer_id = answers.id
WHERE notes.archived = 0 AND users_perms.perm_id IS NULL
GROUP BY answers.plan_id, notes.answer_id, users.email, users_perms.perm_id,
  notes.id, notes.text, notes.created_at, notes.updated_at
ORDER BY notes.id DESC;
```

These records can be mapped to the `answerComments` table as:
```
- text ----> answerComments.commentText
- created_at ----> answerComments.created
- updated_at ----> answerComments.modified
```

There are also some fields that will require special handling before they can be moved into the `answerComments` table:
```
- answerId -- (we can get this from the answers mapping table with the answer_id)
- createdById -- (use the notes user commenter_email to lookup the id in the new system)
- modifiedById -- (use the notes user commenter_email to lookup the id in the new system)
```

### FEEDBACK COMMENTS (1,101 rows)
---

Feedback in the new system consists of a parent `feedbacks` record and one or more `feedbackComments` records. The old system only has the `notes` table which is used for both general comments and feedback comments.

We can get this information with the following query:
```sql
SELECT answers.plan_id, notes.answer_id, users.email as commenter,
  (SELECT u.email
   FROM users AS u
     INNER JOIN roles ON roles.user_id = u.id AND roles.access = 15 AND roles.active = 1
       INNER JOIN plans ON roles.plan_id = plans.id
   WHERE plans.id = answers.plan_Id
   ORDER BY roles.created_at DESC
   LIMIT 1
  ) AS plan_owner,
  notes.id, notes.text, notes.created_at, notes.updated_at
FROM notes
  INNER JOIN users ON notes.user_id = users.id
    LEFT JOIN users_perms ON users.id = users_perms.user_id AND users_perms.perm_id = 6
  INNER JOIN answers ON notes.answer_id = answers.id
WHERE notes.archived = 0 AND users_perms.perm_id IS NOT NULL AND plan_owner != commenter_email
GROUP BY answers.plan_id, notes.answer_id, users.email, users_perms.perm_id,
  notes.id, notes.text, notes.created_at, notes.updated_at
ORDER BY notes.id DESC;
```

We need to create a new entry in the `feedbacks` table first. The old system has no equivalent, so we will just group all feedback comments into a single feedback entry.

We can create a single `feedback` entry per plan with the following information:
```
- planId -- (we can get this from the plans mapping table with the plan_id)
- requestedById -- (use the plan_owner email to lookup the id in the new system)
- requested -- 
- completedById -- (use the first commenter_email to lookup the id in the new system)
- completed -- (set to the most recent updated_at value from the notes records for this plan)
- createdById -- (set to a super admin user id)
- modifiedById -- (set to a super admin user id)
- created_at -- (set to the earliest created_at value from the notes records for this plan)
- updated_at -- (set to the latest updated_at value from the notes records for this plan)
```

Then the records can be mapped to the `feedbackComments` table as:
```
- text ----> answerComments.commentText
- created_at ----> answerComments.created
- updated_at ----> answerComments.modified
```

There are also some fields that will require special handling before they can be moved into the `answerComments` table:
```
- answerId -- (we can get this from the answers mapping table with the answer_id)
- createdById -- (use the notes user commenter_email to lookup the id in the new system)
- modifiedById -- (use the notes user commenter_email to lookup the id in the new system)
```

### RELATED WORKS (561 rows)
---
Move over the related works that have been manually added.

We can get this information with the following query:
```sql
SELECT works.identifiable_id AS plan_id, 
  CASE works.work_type 
    WHEN 0 THEN 'ARTICLE'
    WHEN 2 THEN 'PREPRINT'
    WHEN 3 THEN 'SOFTWARE'
    WHEN 4 THEN 'SUPPLEMENTARY_MATERIALS'
    WHEN 5 THEN 'DATA_PAPER'
    WHEN 6 THEN 'BOOK'
    WHEN 7 THEN 'PROTOCOL'
    WHEN 8 THEN 'PRE_REGISTRATION'
    WHEN 9 THEN 'TRADITIONAL_KNOWLEDGE'
    ELSE 'DATASET'
  END AS work_type,
  'CITES' AS relation_type,
  works.identifier_type AS id_typ,
  CASE 
    WHEN works.identifier_type = 3 THEN 'DOI'
    WHEN works.identifier_type = 16 AND works.value LIKE '%ark:%' THEN 'ARK'
    WHEN works.identifier_type = 16 AND works.value LIKE '%handle.net%' THEN 'HANDLE'
    WHEN works.identifier_type = 16 AND works.value NOT LIKE '%handle.net%' THEN 'URL'
    ELSE CASE WHEN works.value LIKE 'http%' THEN 'URL' ELSE 'OTHER' END
  END AS identifier_type,
  works.value,
  works.citation
FROM related_identifiers AS works;
```

We need to figure out how to appropriately map this information to the new system's tables

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

