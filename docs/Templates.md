# Data Migration Plan
This document outlines the plan to migrate data from the existing Rails-based DMP Tool system to the
new Node.js-based DMP Tool system.

**These migrations cannot be run until [USERS migration](Users.md) and [AFFILIATIONS migration](Affiliations.md) have been completed.**

---
**Important:**
We will need to decide how to handle the templates attached to the "Non Partner Institution" org:
- 6 templates
  - 2 have plans so we will need to re-attach them to a real org (e.g. UCOP)
  - the others have no plans and were created prior to 2018 so we can likely delete them
    
Query to reattach those templates and delete the others:
```sql
# See the templates attached to the "Non Partner Institution" org (org_id = 0)
SELECT id, title, created_at, org_id FROM templates WHERE org_id = 0;

# Reattach the templates that have plans to UCOP
UPDATE templates SET org_id = 15 WHERE id in (
    SELECT DISTINCT templates.id 
    FROM templates
      LEFT JOIN plans ON templates.id = plans.template_id
    WHERE templates.org_id = 0 AND plans.id IS NOT NULL    
);

# Delete the templates that have no plans and are attached to the "Non Partner Institution" org
DELETE FROM templates WHERE org_id = 0 AND id IN (
  SELECT DISTINCT templates.id
  FROM templates
    LEFT JOIN plans ON templates.id = plans.template_id
  WHERE templates.org_id = 0 AND plans.id IS NULL
);
```
---

### TEMPLATES (477 rows)
---

The templating system is quite different in the new system. Some import things to note: 
- The new system does not have a concept of "Template Phases" 
- The old system made entire copies of `templates->phases->sections->questions` each time the template was published or customized.
- The new system has a single template record that always represents the current state of a template regardless of its publication status. When a template is published, a snapshot of the template, its sections and questions are created in the `versionedTemplate`, `versionedSection` and `versionedQuestion` tables.
- The old system does not store a language on the template

**Use the family_id when building the id mapping table for templates.**

#### Language Considerations
Here are a list of template `family_id` that are are written in `pt-BR`: 
- 1577024021
- 1316548433
- 1709021214
- 639302930
- 1709119945
- 1574045256
- 1704331608
- 299352315
- 1966612522

We can use the following query to find the data for the `templates` table:
```sql
SELECT templates.family_id, templates.id, templates.title, templates.description, templates.links,
  CASE WHEN templates.is_default = 1 THEN true ELSE false END AS best_practice,
  CASE WHEN templates.visibility = 0 THEN 'ORGANIZATIONAL' ELSE 'PUBLIC' END AS visibility,
  CASE WHEN templates.published = 0 THEN true ELSE false END AS is_dirty,
  CASE WHEN templates.published = 1 THEN CONCAT('v', templates.version) ELSE NULL END AS version,
  CASE WHEN templates.published = 1 THEN templates.updated_at ELSE NULL END AS published_at,
  CASE 
  WHEN templates.org_id IS NULL THEN NULL
  WHEN registry_orgs.id IS NULL THEN CONCAT('https://migration.org/affiliations/', orgs.id) 
  ELSE registry_orgs.ror_id 
  END AS owner_id,
  (SELECT users.email
   FROM users
     INNER JOIN users_perms ON users.id = users_perms.user_id AND users_perms.perm_id = 6
   WHERE users.org_id = orgs.id ORDER BY users.created_at DESC LIMIT 1
  ) created_by,  
  templates.created_at, templates.updated_at
FROM templates
  INNER JOIN orgs ON templates.org_id = orgs.id
    LEFT OUTER JOIN registry_orgs ON orgs.id = registry_orgs.org_id
WHERE templates.customization_of IS NULL
AND templates.id = (SELECT MAX(t.id) FROM templates AS t WHERE t.family_id = templates.family_id);
```

These records can be mapped to the `templates` table as:
```
- title ----> templates.name
- description ----> templates.description
- owner_id ----> templates.ownerId
- version ----> templates.latestPublishedVersion
- published_at ----> templates.latestPublishedDate
- is_dirty ----> templates.isDirty
- best_practice ----> templates.bestPractice
- templates.languageId
- created_at ----> templates.created
- updated_at ----> templates.modified
```

We need to perform some special handling for the following fields:
```
- languageId -- (see list of `pt-BR` templates above, all others should be `en-US`)
- templates.latestPublishVisibility -- (if `version` is not null use `visibility` else NULL)
- templates.createdById -- (lookup user by email in `created_by` field, should NOT be null)
- templates.modifiedById -- (use same value as `createdById`)
- if templates.createdById is null then use a SUPERADMIN user id!
```

### Template Links table
---
The `links` field in the old system is a serialized array of objects with `url` and `text` fields. We need to extract these and put them into the `templateLinks` table.
Use the query results from above. Ignore entries where the `links` field is NULL or an empty array.
Skip any entries that are missing the `url` value. 

```
- templateId
- url ----> templateLinks.url
- text ----> templateLinks.text (if null use the url value)
``` 

#### Versioned Templates table (851 rows)
---
We can use the following query to find the data for the `templates` table:
```sql
SELECT vt.family_id, vt.id, vt.title, vt.description, vt.links,
  CASE WHEN vt.is_default = 1 THEN true ELSE false END AS best_practice,
  CASE WHEN vt.visibility = 0 THEN 'ORGANIZATIONAL' ELSE 'PUBLIC' END AS visibility,
  CASE WHEN vt.published = 1 THEN true ELSE false END AS active,
  CONCAT('v', vt.version) AS version,
  vt.updated_at AS published_at,
  CASE 
  WHEN vt.org_id IS NULL THEN NULL
  WHEN registry_orgs.id IS NULL THEN CONCAT('https://migration.org/affiliations/', orgs.id) 
  ELSE registry_orgs.ror_id 
  END AS owner_id,
  (SELECT users.email
   FROM users
     INNER JOIN users_perms ON users.id = users_perms.user_id AND users_perms.perm_id = 6
   WHERE users.org_id = orgs.id ORDER BY users.created_at DESC LIMIT 1
  ) created_by,  
  vt.created_at, vt.updated_at
FROM templates AS vt
  INNER JOIN orgs ON vt.org_id = orgs.id
    LEFT OUTER JOIN registry_orgs ON orgs.id = registry_orgs.org_id
WHERE vt.customization_of IS NULL
AND vt.id NOT IN (
  SELECT t.id FROM templates AS t WHERE t.customization_of IS NULL
  AND t.id = (SELECT MAX(tmp.id) FROM templates AS tmp WHERE tmp.family_id = t.family_id AND tmp.published = 0)
)
ORDER BY vt.family_id, vt.version DESC;
```

These records can be mapped to the `versionedTemplates` table as:
```
- templateId
- active --> versionedTemplates.active
- version --> versionedTemplates.version
- visibility --> versionedTemplates.visibility
- title ----> versionedTemplates.name
- description ----> versionedTemplates.description
- owner_id ----> versionedTemplates.ownerId
- best_practice ----> versionedTemplates.bestPractice
- created_at ----> versionedTemplates.created
- updated_at ----> versionedTemplates.modified
```

We need to perform some special handling for the following fields:
```
- languageId -- (see list of `pt-BR` templates above, all others should be `en-US`)
- versionedTemplates.comment -- (default to NULL)
- versionedTemplates.versionType -- (default to 'PUBLISHED')
- versionedTemplates.versionedById -- (lookup user by email in `created_by` field from templates query, should NOT be null)
- versionedTemplates.createdById -- (use same value as `templates.createdById`)
- versionedTemplates.modifiedById -- (use same value as `templates.modifiedById`)
```

### Versioned Template Links table
---
The `links` field in the old system is a serialized array of objects with `url` and `text` fields. We need to extract these and put them into the `templateLinks` table.
Use the query results from above. Ignore entries where the `links` field is NULL or an empty array.
Skip any entries that are missing the `url` value.

```
- versionedTemplateId
- url ----> templateLinks.url
- text ----> templateLinks.text (if null use the url value)
``` 

### Template Customizations (865 rows)
---
The old system made clones of the entire `template->phase->section->question` chain and does not record the org_id for any of the sub components so it is very difficult to determine what changed between the base template and the customization. Because of this, we will only move over the current version of the customizations.

We can use the following query to find the data for the `templateCustomizations` table:
```sql
SELECT ct.customization_of AS family_id, ct.org_id,
  CASE 
  WHEN ct.org_id IS NULL THEN NULL
  WHEN registry_orgs.id IS NULL THEN CONCAT('https://migration.org/affiliations/', orgs.id) 
  ELSE registry_orgs.ror_id 
  END AS owner_id,
  CASE WHEN ct.published = 1 THEN CONCAT('v', ct.version) ELSE NULL END AS current_version,
  CASE WHEN ct.version >= 1 THEN CONCAT('v', ct.version - 1) ELSE NULL END AS prior_version,
  (SELECT users.email
    FROM users
      INNER JOIN users_perms ON users.id = users_perms.user_id AND users_perms.perm_id = 6
    WHERE users.org_id = orgs.id ORDER BY users.created_at DESC LIMIT 1
  ) created_by
FROM templates AS ct
  LEFT JOIN orgs ON ct.org_id = orgs.id
    LEFT OUTER JOIN registry_orgs ON orgs.id = registry_orgs.org_id
WHERE ct.id = (SELECT MAX(t.id) FROM templates AS t WHERE t.customization_of = ct.customization_of AND t.org_id = ct.org_id);
GROUP BY ct.customization_of, ct.published, ct.org_id, registry_orgs.id, registry_orgs.ror_id, orgs.id
ORDER BY ct.customization_of, owner_id;
```

These records can be mapped to the `templateCustomizations` table as:
```
- templateId
- owner_id ----> templateCustomizations.affiliationId
- created_at ----> versionedTemplates.created
- updated_at ----> versionedTemplates.modified
```

We need to perform some special handling for the following fields:
```
- templateCustomizations.status -- (current_version is not null then 'PUBLISHED' else 'DRAFT')
- templateCustomizations.migrationStatus -- (run query to see if current_version matches the template.publishedVersion, 
  if so then 'OK' else 'STALE')
 - createdById -- (lookup user by email in `created_by` field from templates query, should NOT be null)
 - modifiedById -- (use same value as `createdById`)
```

### Versioned Template Customizations (865 rows)
---

Use the same query from above to get the data for the `versionedTemplateCustomizations` table:
```
- templateCustomizationId
- owner_id ----> versionedTemplateCustomizations.affiliationId
- created_at ----> versionedTemplates.created
- updated_at ----> versionedTemplates.modified
```

We need to perform some special handling for the following fields:
```
- status -- (always 'PUBLISHED' here)
- active -- (if the current_version is not null then true else false)
- currentVersionedTemplateId -- (lookup the versionedTemplateCusomization.id using the current_version and family_id from the templates query)
- priorVersionedTemplateId -- (lookup the versionedTemplateCusomization.id using the prior_version and family_id from the templates query, can be null)
- createdById -- (lookup user by email in `created_by` field from templates query, should NOT be null)
- modifiedById -- (use same value as `createdById`)
```