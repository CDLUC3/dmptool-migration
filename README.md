# dmptool-migration
SQLMesh code to facilitate data migration from the old Rails DMP Tool to the new JS system

## Overview

The current Rails system has a single `plans` table, a related `contributors` table, a related `answers` table and a related polymorphic `identifiers` table.

The `plans` table also has several foreign keys to tables that we will need to move first: `research_domains`, `orgs` and `users` and `templates`.

**PREP WORK:**
- Create `affiliationDepartments` table in new system with `affiliationId`, `name` and `abbreviation`
- Clean up `registry_orgs` table which has a few duplicate `org_id` entries. Run the following query, the orgs in the `orgs` table likely need to be merged and the registry_org table updated to map to the merged org only:
```
SELECT * FROM registry_orgs WHERE org_id IS NOT NULL AND org_id IN (
  SELECT org_id
  FROM registry_orgs
  GROUP BY org_id
  HAVING COUNT(*) > 1
);
```

We will likely need the following ID mapping tables:
- templates -> templates
- plans -> projects
- research_domains -> researchDomains (see below for mapping)
- users (we can likely just use the email address for to map)
- affiliations (we will use the affiliations.uri for this, so no need to map)

We do not have a concept of "Template Phases" in the new system, so lets ignore the plans that are based on templates that have phases for now.

Here is a query to see templates with multiple phases:
```
SELECT phases.template_id, COUNT(phases.id) AS phase_count
FROM phases
GROUP BY phases.template_id
HAVING phase_count > 1
ORDER BY phase_count desc;
```

The migrations should be run in the following order:
1. [USERS](docs/Users.md)
2. [AFFILIATIONS](docs/Affiliations.md)
3. [TEMPLATES](docs/Templates.md)
4. [PROJECTS](docs/Projects.md)
