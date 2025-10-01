# Data Migration Plan
This document outlines the plan to migrate data from the existing Rails-based DMP Tool system to the
new Node.js-based DMP Tool system. 

### USERS (98,781 rows)
---
The migration of user data is probably the most straightforward. We can run the following query to fetch the information we need:
```
SELECT users.id, users.firstname, users.surname, users.email, users.created_at, users.updated_at, 
  users.accept_terms, users.last_sign_in_at, languages.abbreviation AS language, 
  o.value AS orcid, s.value AS sso_id,
  CASE 
    WHEN users.org_id IS NULL THEN NULL
    WHEN registry_orgs.id IS NULL THEN CONCAT('https://dmptool.org/affiliations/', orgs.id)
    ELSE registry_orgs.ror_id
  END AS org_id,
  (SELECT perm_id FROM users_perms WHERE users_perms.user_id = users.id AND perm_id = 10) is_super,
  (SELECT COUNT(perm_id) FROM users_perms WHERE users_perms.user_id = users.id AND perm_id != 10) is_admin
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
- users.firstname ----> users.givenName
- users.surname ----> users.surName
users.email                                         ----> userEmails (email, isPrimary = true, isConfirmed = true)
- users.last_sign_in_at ----> users.last_sign_in
- users.accept_terms ----> users.acceptedTerms
- users.active ----> users.active
- users.created_at ----> users.created
- users.updated_at ----> users.modified
```

There are also some fields that will require special handling before they can be moved into the new system:
```
- users.locked -- (default to false)
- users.password -- (default to hardcoded value - same for all users so we can test)
- users.role -- if is_super is NOT null then "SUPERADMIN" 
                  else if is_admin > 0 then "ADMIN" 
                  else "RESEARCHER"
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
