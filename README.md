# dmptool-migration
SQLMesh code to facilitate data migration from the old Rails DMP Tool to the new JS system

## Overview

The current Rails system has a single `plans` table, a related `contributors` table, a related `answers` table and a related polymorphic `identifiers` table.

The `plans` table also has several foreign keys to tables that we will need to move first: `research_domains`, `orgs` and `users` and `templates`.

**PREP WORK:**
- Create `affiliationDepartments` table in new system with `affiliationId`, `name` and `abbreviation`
- Create a `templateLinks` and `versionedTemplateLinks` table in the new system with `templateId`, `versionedTemplateId`, ' `url` and `text`
- Clean up users attached to the "Non Partner Institution" org (id=1). See the [Users doc](docs/Users.md) for more details.
```
- Clean up `registry_orgs` table which has a few duplicate `org_id` entries. Run the following query, the orgs in the `orgs` table likely need to be merged and the registry_org table updated to map to the merged org only:
```
SELECT * FROM registry_orgs WHERE org_id IS NOT NULL AND org_id IN (
  SELECT DISTINCT org_id
  FROM registry_orgs
  WHERE org_id IS NOT NULL
  GROUP BY org_id
  HAVING COUNT(*) > 1
);
```

### Mapping tables to link ids from the old system to the new system

We will likely need the following ID mapping tables:
- templates -> templates
- plans -> projects
- research_domains -> researchDomains (see below for mapping)
- users (we can just use the email address for to map)
- affiliations (we will use the affiliations.uri for this, so no need to map)

### Templates with Phases

We do not have a concept of "Template Phases" in the new system. There are 55 templates in the old system that have multiple phases. These templates are used by 152 plans in the old system.

There are 71 of these templates that have no plans associated with them.
```sql
SELECT orgs.id, orgs.name, templates.id, templates.title, templates.created_at, phases.template_id,
  COUNT(DISTINCT plans.id) AS plan_count,
  COUNT(phases.id) AS phase_count
FROM phases
  INNER JOIN templates ON phases.template_id = templates.id
    LEFT JOIN plans ON templates.id = plans.id
    LEFT JOIN orgs ON templates.org_id = orgs.id
GROUP BY phases.template_id, templates.title, templates.created_at, phases.template_id
HAVING phase_count > 1 AND plan_count < 1
ORDER BY phase_count desc;
```

We have some options for how to handle these multi-phase templates and their associated plans:
1. Make each phase a template in its own right and then for any plans that are using the template (with phase) we create a single project and then a plan for each of the phases (new templates). So for example:
  - Template A has 3 phases
  - We create Template A1, A2 and A3 in the new system
  - Plan 123 is based on Template A 
  - We create a single Project with 3 plans in the new system for Templates A1, A2 and A3
2. Make the phases sections in the new system. We would need to determine how to flatten the phase-section relationship though. So for example:
  - Template A has 3 phases
  - We create Template A in the new system
  - Each phase in Template A becomes a section in Template A
  - Plan 123 is based on Template A 
  - We create a single Project with a single plan in the new system for Template A

Here is a query to see templates with multiple phases:
```
SELECT orgs.id, orgs.name, templates.id, templates.title, templates.created_at, phases.template_id,
  COUNT(DISTINCT plans.id) AS plan_count,
  COUNT(phases.id) AS phase_count
FROM phases
 INNER JOIN templates ON phases.template_id = templates.id
   LEFT JOIN plans ON templates.id = plans.id
   LEFT JOIN orgs ON templates.org_id = orgs.id
GROUP BY phases.template_id, templates.title, templates.created_at, phases.template_id
HAVING phase_count > 1
AND plan_count > 0
ORDER BY phase_count desc;
```

The migrations should be run in the following order:
1. [MISCELLANEOUS](docs/Misc.md)
2. [USERS](docs/Users.md)
2. [AFFILIATIONS](docs/Affiliations.md)
3. [TEMPLATES](docs/Templates.md)
4. [SECTIONS AND QUESTIONS](docs/SectionsAndQuestions.md)
5. [PROJECTS, PLANS, ANSWERS](docs/Projects.md)
6. [CONTRIBUTORS](docs/Contributors.md)
