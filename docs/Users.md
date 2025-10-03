# Data Migration Plan
This document outlines the plan to migrate data from the existing Rails-based DMP Tool system to the
new Node.js-based DMP Tool system. 

---
**Important:**
We will need to decide how to handle users of the "Non Partner Institution" org which contains:
- 13,404 users
    - 4 admins, all the rest are researchers (see queries below to re-attached them)
    - 3,025 of those users have no plans. The most recent was created on 9/25/2025. They range back to the original migration from DMP Tool v2 to the DMPRoadmap codebase in 2016. We can probably safely cut these off at specific date and not migrate them over. (see query below)
    - 10,379 of those users have at least 1 plan. The most recent was created on 9/29/2025

Query to reattach those users to a real org:
```sql
# Find ADMIN users connected to the "Non Partner Institution" org (org_id = 0)
SELECT DISTINCT id, email FROM users INNER JOIN users_perms on users.id = users_perms.user_id WHERE org_id = 0;

# Update those users to be connected to a real org (e.g. Univ. of Glasgow, UCOP, etc.)
UPDATE users SET org_id = 2117 WHERE id = 391;
UPDATE users SET org_id = 15 WHERE id in (9006, 9007, 9349);

# Find RESEARCHER users who are connected to the "Non Partner Institution" org (org_id = 0)
# that have no plans
SELECT users.id, users.email, users.created_at, users.last_sign_in_at, COUNT(DISTINCT roles.plan_id) plan_count
FROM users LEFT JOIN roles ON users.id = roles.user_id
WHERE users.org_id = 0
GROUP BY users.id, users.email
HAVING plan_count < 1
ORDER BY users.created_at ASC;
```
---

### USERS (98,781 rows)
---
The migration of user data is probably the most straightforward. We can run the following query to fetch the information we need:
```
SELECT users.id, users.firstname, users.surname, users.email, users.created_at, users.updated_at, 
  users.accept_terms, users.last_sign_in_at, languages.abbreviation AS language, 
  o.value AS orcid, s.value AS sso_id,
  false AS locked,
  '$2a$10$f3wCBdUVt/2aMcPOb.GX1OBO9WMGxDXx5HKeSBBnrMhat4.pis4Pe' AS `password`,
  CASE 
    WHEN users.org_id IS NULL THEN NULL
    WHEN registry_orgs.id IS NULL THEN CONCAT('https://dmptool.org/affiliations/', orgs.id)
    ELSE registry_orgs.ror_id
  END AS org_id,
  CASE 
    WHEN (SELECT up.perm_id FROM users_perms AS up WHERE up.user_id = users.id AND up.perm_id = 10) THEN 'SUPERADMIN'
    WHEN (SELECT COUNT(up.perm_id) FROM users_perms AS up WHERE up.user_id = users.id AND up.perm_id != 10) THEN 'ADMIN'
    ELSE 'RESEARCHER'
  END AS role
FROM users 
  LEFT JOIN languages ON users.language_id = languages.id
  INNER JOIN orgs ON users.org_id = orgs.id
  	LEFT JOIN registry_orgs ON orgs.id = registry_orgs.org_id
  LEFT JOIN identifiers o ON o.identifiable_type = 'User' AND o.identifiable_id = users.id AND o.identifier_scheme_id = 1
  LEFT JOIN identifiers s ON s.identifiable_type = 'User' AND s.identifiable_id = users.id AND s.identifier_scheme_id = 2;
```

We will need to run this in 2 stages.

#### Stage 1: Create user records
In the initial stage we will create the `users` and `userEmails` without affiliation information. We will also leave the `createdById` and `modifiedById` blank on this pass

These records can be mapped to the `users` table as:
```
- orcid ----> users.orcid
- sso_id ----> users.ssoId
- firstname ----> users.givenName
- surname ----> users.surName
- last_sign_in_at ----> users.last_sign_in
- accept_terms ----> users.acceptedTerms
- active ----> users.active
- language ----> users.languageId
- role ----> users.role
- password ----> users.password
- locked ----> users.locked
- created_at ----> users.created
- updated_at ----> users.modified
```

User emails are stored in a separate table in the new system, so we need to add them as a second pass once the user records have been moved.
```
- userId
- email ----> userEmails.email
- true ----> userEmails.isConfirmed
- true ----> userEmails.isPrimary
- userId ----> users.createdById (use the id of the newly created user)
- userId ----> users.modifiedById (use the id of the newly created user)
```

#### Step2: Add affiliation ids
We will then need to wait until the [AFFILIATIONS migration](Affiliations.md) have been successfully loaded. Once they are in place, we can attach the affiliationIds to the user record and also set the createdById and modifiedById.
Update the following on the `users` table
```
- org_id ----> users.affiliationId
- userId ----> users.createdById (use the id of the newly created user)
- userId ----> users.modifiedById (use the id of the newly created user)
```
