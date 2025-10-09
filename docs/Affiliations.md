# Data Migration Plan
This document outlines the plan to migrate data from the existing Rails-based DMP Tool system to the
new Node.js-based DMP Tool system.

**These migrations cannot be run until [USERS migration](Users.md) has been completed.**

---
**IMPORTANT:**
We will want to do a manual pass through of the non-ROR orgs to see if they are duplicates. We should then merge those orgs through the tool so that all associations are updates (e.g. users, templates, etc.) prior to the final run!
---

**Once these tasks are complete be sure to process Step 2 of the [USERS migration](Users.md)!**

### AFFILIATIONS (6,871 ROR rows + 7,512 non-ROR rows)
---
The Rails system has a combination of tables that store Org information: `orgs` and `registry_orgs`. The original `orgs` table contains all of the affiliations currently used in the system. The `registry_orgs` table is a copy of the latest ROR database (not every ROR field). The `registry_orgs.org_id` is a foreign key joining the two tables together. When users create contributors, funders, accounts a typeahead queries all of the ROR entries in the `registry_orgs` table and then the `orgs` records that have no match in the `registry_orgs` table (for example "Company XYZ" has DMP Tool users but isn't listed in ROR).

Use the `users.id` of a "SUPERADMIN" user for all of the `createdById` and `modifiedById` in these tables. The old system doesn't record that information anyway.

We will need to approach this in three passes.

#### Step 1: Load the ROR data into the new system's `affiliations` table from the ROR source file.
We can use the ROR source file (or DuckDB table) Jamie used for the related works. We can script this with a Lambda that can be executed manually (eventually triggered through the UI by a super admin) or via a scheduled event. The Lambda should add new records, update existing ones if they've changed, and mark any that were deleted as inactive.

If we want to start with a limited subset of the ROR database (6,871 records), we can use the following query to determine which ROR ids are currently in use. The following query also supplies us with some additional information we want but that does not exist on the ROR record: `SELECT ror_id FROM registry_orgs WHERE org_id IS NULL;`

#### Step 2: Amend the ROR records with additional data
Once the definitive ROR entries are in the `affiliations` table, we will want to migrate over additional information about the org that is not a part of that core ROR record. To fetch this information use this query:
```
SELECT registry_orgs.ror_id, identifiers.value AS ssoEntityId, registry_orgs.api_target, 
  orgs.managed, orgs.contact_email, orgs.contact_name, orgs.logo_name, orgs.logo_uid, 
  orgs.feedback_enabled,  orgs.feedback_msg, orgs.links
FROM registry_orgs 
  INNER JOIN orgs ON registry_orgs.org_id = orgs.id
    LEFT JOIN identifiers 
    ON identifiable_type = 'Org' AND identifiable_id = orgs.id AND identifier_scheme_id = 2;
```

#### Step 3: Load the Orgs that are not in ROR into the new system's `affiliations` table
We then need to migrate over the organizations that are in use but that are not a part of the ROR database (7,512 records). We can use the following query to fetch these records:
```
SELECT orgs.name, orgs.target_url, 
  REPLACE(
    SUBSTRING_INDEX(
      SUBSTRING_INDEX(
        SUBSTRING_INDEX(
          REPLACE(orgs.target_url, '://', '###'), 
        '/', 3), 
      '###', -1), 
    '/', 1),
  'www.', '') AS domain,
  orgs.logo_uid, orgs.logo_name, orgs.contact_email, orgs.contact_name,
  orgs.feedback_enabled, orgs.feedback_msg, orgs.managed, orgs.links,
  orgs.created_at, orgs.updated_at,
  true AS active,
  "DMPTOOL" AS provenance,
  CONCAT("https://dmptool.org/affiliations/", orgs.id) AS uri,
  CONCAT("[", CONCAT(orgs.abbreviation, "]")) AS acronym,
  CASE WHEN orgs.org_type IN (2, 3, 6, 7) THEN true ELSE false END AS funder,
  identifiers.value AS ssoEntityId,
  CONCAT(orgs.name, CONCAT(" | ", CONCAT(orgs.abbreviation, CONCAT(" | ", orgs.target_url)))) AS search_name,
  CASE 
    WHEN orgs.org_type = 2 THEN '["GOVERNMENT"]'
    WHEN orgs.org_type = 3 THEN '["EDUCATION", "GOVERNMENT"]'
    WHEN orgs.org_type = 4 
      AND (LOWER(orgs.name) LIKE '%college%' OR LOWER(orgs.name) LIKE '%university%' 
           OR LOWER(orgs.name) LIKE '%school%') THEN '["EDUCATION"]'
    WHEN orgs.org_type = 4 
    	AND LOWER(orgs.name NOT LIKE '%college%' AND LOWER(orgs.name) NOT LIKE '%university%' 
    	AND LOWER(orgs.name) NOT LIKE '%school%') THEN '["OTHER"]'
    WHEN orgs.org_type IN (5, 6) THEN '["NONPROFIT"]'
    WHEN orgs.org_type = 7 THEN '["EDUCATION", "GOVERNMENT", "OTHER"]'
    ELSE '["EDUCATION"]'
  END AS org_type
FROM orgs 
  LEFT JOIN registry_orgs ON orgs.id = registry_orgs.org_id 
  LEFT JOIN identifiers ON identifiable_type = 'Org' AND identifiable_id = orgs.id AND identifier_scheme_id = 2
WHERE registry_orgs.id IS NULL;
```

These records can be mapped to the `affiliations` table as:
```
- provenance ----> affiliations.provenance
- uri ----> affiliations.uri
- name ----> affiliations.name 
- name ----> affiliations.displayName
- search_name ----> affiliations.searchName
- acronym ----> affiliations.acronym
- org_type ----> affiliations.types
- target_url ----> affiliations.homepage
- logo_name ----> affiliations.logoName
- logo_uid ----> affiliations.logoURI
- contact_name ----> affiliations.contactName
- contact_email ----> affiliations.contactEmail
- feedback_enabled ----> affiliations.feedbackEnabled
- feedback_msg ----> affiliations.feedbackMessage
- managed ----> affiliations.managed
- active ----> affiliations.active
- funder ----> affiliations.funder
- ssoEntityId ----> affiliations.ssoEntityId
- created_at ----> affiliations.created
- updated_at ----> affiliations.modified
```

An affiliation has 3 additional tables in the new system that we also need to populate once the affiliation record is in the table.

**Affiliation Departments**
We need to move over the departmental information defined by some of our orgs. Run the following query to extract this information:
```
SELECT CASE 
  WHEN registry_orgs.id IS NULL THEN CONCAT('https://dmptool.org/affiliations/', orgs.id)
  ELSE registry_orgs.ror_id 
  END AS id,
  departments.name, departments.code, departments.created_at, departments.updated_at
FROM departments 
  INNER JOIN orgs ON departments.org_id = orgs.id 
  LEFT JOIN registry_orgs ON orgs.id = registry_orgs.org_id;
```

This information can then be mapped as:
```
- id ----> affiliationDepartments.affiliationId
- name ----> affiliationDepartments.name
- code ----> affiliationDepartments.abbreviation
- created_at ----> affiliationDepartments.created
- updated_at ----> affiliationDepartments.modified
```

**Affiliation Links**
The old system stores affiliation links (the links that appear in the sub header for the org's users) as a JSON array. The new system has its own table to store these values. Skip any entries that are missing the `link` value. If the `text` value is missing use the `link` value for both.
```
- link ----> affiliationLinks.url
- link_text ----> affiliationLinks.text
- created_at ----> affiliationLinks.created
- updated_at ----> affiliationLinks.modified
- affiliationId -- (the integer id of the affiliation record)
- affiliationLinks.createdById -- (use the createdById on the affiliation record)
- affiliationLinks.modifiedById - (use the modifiedById on the affiliation record)
```

**Email Domains**
The new system is going to store email domains that the org uses for SSO. The old system does not have this concept. We will want to extract the `domain` and `subdomain` (if applicable) from the org's `target_url` and add them to `affiliationEmailDomains.domain`

This information can be mapped as:
```
- domain ----> affiliationEmailDomains.domain
- created_at ----> affiliationEmailDomains.created
- updated_at ----> affiliationEmailDomains.modified
- affiliationId -- (the integer id of the affiliation record)
- affiliationEmailDomains.createdById -- (use the createdById on the affiliation record)
- affiliationEmailDomains.modifiedById -- (use the modifiedById on the affiliation record)
```
