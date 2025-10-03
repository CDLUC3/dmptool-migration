# Data Migration Plan
This document outlines the plan to migrate data from the existing Rails-based DMP Tool system to the
new Node.js-based DMP Tool system.

**These migrations cannot be run until [TEMPLATES migration](Templates.md)**

### SECTIONS (2,366 rows)
---
The migration of sections from the old system to the new is fairly straightforward.

SQL to extract sections from the old system:
```sql
SELECT templates.family_id, CONCAT('v', templates.version) AS version,
       sections.id, sections.title, sections.description, sections.number,
       sections.created_at, sections.updated_at
FROM sections
         INNER JOIN phases ON sections.phase_id = phases.id
         INNER JOIN templates ON phases.template_id = templates.id
WHERE templates.customization_of IS NULL
  AND templates.id = (SELECT MAX(t.id) FROM templates AS t WHERE t.family_id = templates.family_id)
ORDER BY templates.family_id, templates.id, sections.number;
```

These records can be mapped to the `templates` table as:
```
- name ----> sections.name
- description ----> sections.introduction
- number ----> sections.displayOrder
- created_at ----> sections.created
- updated_at ----> sections.modified
```

Special handling:
```
-- templateId -- (can be looked up from the templates mapping table via family_id and version)
-- createdById -- (we can set this to the same value in the template record)
-- modifiedById -- (we can set this to the same value in the template record)
```

### VERSIONED SECTIONS (5,615 rows)
---

We then need to move the old versions of the sections to the new `versionedSections` table.
SQL to extract versioned sections from the old system:
```sql
SELECT templates.family_id, CONCAT('v', templates.version) AS version,
       sections.id, sections.title, sections.description, sections.number,
       sections.created_at, sections.updated_at
FROM sections
         INNER JOIN phases ON sections.phase_id = phases.id
         INNER JOIN templates ON phases.template_id = templates.id
WHERE templates.customization_of IS NULL
  AND templates.id NOT IN (
    SELECT t.id FROM templates AS t WHERE t.customization_of IS NULL
                                      AND t.id = (SELECT MAX(tmp.id) FROM templates AS tmp WHERE tmp.family_id = t.family_id AND tmp.published = 0)
)
ORDER BY templates.family_id, templates.id, sections.number;
```

These records can be mapped to the `versionedSections` table as:
```
- name ----> versionedSections.name
- description ----> versionedSections.introduction
- number ----> versionedSections.displayOrder
- created_at ----> versionedSections.created
- updated_at ----> versionedSections.modified
```

Special handling:
```
-- versionedTemplateId -- (can be looked up from the templates mapping table via family_id and version)
-- sectionId -- (can be looked up from the sections mapping table via id)
-- createdById -- (we can set this to the same value in the template record)
-- modifiedById -- (we can set this to the same value in the template record)
```

#### Post processing
We may want to run a script to clean up the `displayOrder` on all of these tables. They are numerically correct in the old system but we may want to clean scenarios like `1, 2, 3, 11, 48` to `1, 2, 3, 4, 5`

