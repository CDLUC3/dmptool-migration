MODEL (
  name intermediate.pilot_drafts,
  kind FULL,
  columns (
    dmp_id VARCHAR(255),
    old_draft_id VARCHAR(255),
    title VARCHAR(512),
    description TEXT,
    start_date DATE,
    end_date DATE,
    contact_name VARCHAR(255),
    contact_email VARCHAR(255),
    contact_ror VARCHAR(255),
    funder_id VARCHAR(255),
    grant_id VARCHAR(255),
    funding_status VARCHAR(255),
    funder_project_id VARCHAR(255),
    funder_opportunity_id VARCHAR(255),
    members JSON,
    possible_works JSON,
    related_works JSON,
    visibility VARCHAR(255),
    created DATETIME,
    createdById INT,
    modified DATETIME,
    modifiedById INT
  ),
  enabled true
);

JINJA_QUERY_BEGIN;

SELECT
 d.dmp_id,
 d.draft_id as old_draft_id,
 JSON_UNQUOTE(JSON_EXTRACT(d.metadata, '$.dmp.title')) AS title,
 JSON_UNQUOTE(JSON_EXTRACT(d.metadata, '$.dmp.project[0].description')) AS description,
 JSON_UNQUOTE(JSON_EXTRACT(d.metadata, '$.dmp.project[0].start')) AS start_date,
 JSON_UNQUOTE(JSON_EXTRACT(d.metadata, '$.dmp.project[0].end')) AS end_date,
 JSON_UNQUOTE(JSON_EXTRACT(d.metadata, '$.dmp.contact.name')) AS contact_name,
 JSON_UNQUOTE(JSON_EXTRACT(d.metadata, '$.dmp.contact.mbox')) AS contact_email,
 JSON_UNQUOTE(JSON_EXTRACT(d.metadata, '$.dmp.contact.dmproadmap_affiliation.affiliation_id.identifier')) AS contact_ror,
 JSON_UNQUOTE(JSON_EXTRACT(d.metadata, '$.dmp.project[0].funding[0].funder_id.identifier')) AS funder_id,
 JSON_UNQUOTE(JSON_EXTRACT(d.metadata, '$.dmp.project[0].funding[0].grant_id.identifier')) AS grant_id,
 JSON_UNQUOTE(JSON_EXTRACT(d.metadata, '$.dmp.project[0].funding[0].funding_status')) AS funding_status,
 JSON_UNQUOTE(JSON_EXTRACT(d.metadata, '$.dmp.project[0].funding[0].dmproadmap_project_number')) AS funder_project_id,
 JSON_UNQUOTE(JSON_EXTRACT(d.metadata, '$.dmp.project[0].funding[0].dmproadmap_opportunity_number')) AS funder_opportunity_id,
 JSON_EXTRACT(d.metadata, '$.dmp.contributor') AS members,
 JSON_EXTRACT(d.metadata, '$.dmp.dmphub_modifications') AS possible_works,
 JSON_EXTRACT(d.metadata, '$.dmp.dmproadmap_related_identifiers') AS related_works,
 JSON_UNQUOTE(JSON_EXTRACT(d.metadata, '$.dmp.dmproadmap_privacy')) AS visibility,
 JSON_UNQUOTE(JSON_EXTRACT(d.metadata, '$.dmp.created')) AS created,
 ue.userId AS createdById,
 JSON_UNQUOTE(JSON_EXTRACT(d.metadata, '$.dmp.modified')) AS modified,
 ue.userId AS modifiedById
FROM {{ var('source_db') }}.drafts AS d
  JOIN {{ var('source_db') }}.users AS u ON d.user_id = u.id
    LEFT JOIN migration.user_emails AS ue ON u.email = ue.email;

JINJA_END;