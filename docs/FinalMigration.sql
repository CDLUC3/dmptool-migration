-- PURGE **********************

-- Clear ALL tables
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE dmptool.affiliationDepartments;
TRUNCATE dmptool.affiliationEmailDomains;
TRUNCATE dmptool.affiliationLinks;

TRUNCATE dmptool.workVersions;
TRUNCATE dmptool.works;
TRUNCATE dmptool.relatedWorks;

TRUNCATE dmptool.feedbackComments;
TRUNCATE dmptool.feedback;
TRUNCATE dmptool.answerComments;
TRUNCATE dmptool.answers;
TRUNCATE dmptool.planFundings;
TRUNCATE dmptool.planMemberRoles;
TRUNCATE dmptool.planMembers;
TRUNCATE dmptool.plans;
TRUNCATE dmptool.projectFundings;
TRUNCATE dmptool.projectMemberRoles;
TRUNCATE dmptool.projectMembers;
TRUNCATE dmptool.projects;

TRUNCATE dmptool.versionedCustomQuestions;
TRUNCATE dmptool.customQuestions;
TRUNCATE dmptool.versionedCustomSections;
TRUNCATE dmptool.customSections;
TRUNCATE dmptool.versionedQuestionCustomizations;
TRUNCATE dmptool.questionCustomizations;
TRUNCATE dmptool.versionedSectionCustomizations;
TRUNCATE dmptool.sectionCustomizations;
TRUNCATE dmptool.versionedTemplateCustomizations;
TRUNCATE dmptool.templateCustomizations;

TRUNCATE dmptool.versionedQuestionConditions;
TRUNCATE dmptool.questionConditions;
TRUNCATE dmptool.versionedQuestions;
TRUNCATE dmptool.questions;
TRUNCATE dmptool.versionedSectionTags;
TRUNCATE dmptool.sectionTags;
TRUNCATE dmptool.versionedSections;
TRUNCATE dmptool.sections;
TRUNCATE dmptool.templateCollaborators;
TRUNCATE dmptool.versionedTemplateLinks;
TRUNCATE dmptool.templateLinks;
TRUNCATE dmptool.versionedTemplates;
TRUNCATE dmptool.templates;

TRUNCATE dmptool.metadataStandardResearchDomains;
TRUNCATE dmptool.repositoryResearchDomains;

TRUNCATE dmptool.licenses;
TRUNCATE dmptool.metadataStandards;
TRUNCATE dmptool.repositories;

TRUNCATE dmptool.memberRoles;
TRUNCATE dmptool.researchDomains;
TRUNCATE dmptool.tags;
TRUNCATE dmptool.projectOutputTypes;

TRUNCATE dmptool.userDepartments;
TRUNCATE dmptool.userEmails;
TRUNCATE dmptool.users;

TRUNCATE dmptool.affiliations;

SET FOREIGN_KEY_CHECKS = 1;


-- MIGRATIONS **********************

-- Migrate users
INSERT INTO dmptool.users (id, givenName, surName, affiliationId, orcid, ssoId, password, oldPasswordHash,
                           role, acceptedTerms, locked, active, languageId, last_sign_in, notify_on_comment_added,
                           notify_on_template_shared, notify_on_feedback_complete, notify_on_plan_shared,
                           notify_on_plan_visibility_change, created, createdById, modified, modifiedById)
SELECT id, givenName, surName, affiliationId, orcid, ssoId, COALESCE(password, '12345'), oldPasswordHash, role, COALESCE(acceptedTerms, 0), locked,
       active, languageId, last_sign_in, notify_on_comment_added, notify_on_template_shared,
       notify_on_feedback_complete, notify_on_plan_shared, notify_on_plan_visibility_change, created, createdById,
       modified, modifiedById
FROM migration.users;    -- 142,057

-- Add the default users we use for testing
INSERT dmptool.users (givenName, surName, affiliationId, password,
                           role, acceptedTerms, locked, active, languageId, notify_on_comment_added,
                           notify_on_template_shared, notify_on_feedback_complete, notify_on_plan_shared,
                           notify_on_plan_visibility_change, created, modified)
VALUES ('Super', 'Admin', 'https://ror.org/03yrm5c26',
        '$2a$10$f3wCBdUVt/2aMcPOb.GX1OBO9WMGxDXx5HKeSBBnrMhat4.pis4Pe',
        'SUPERADMIN', 1, 0, 1, 'en-US', 1, 1, 1, 1, 1, CURRENT_DATE(), CURRENT_DATE());

INSERT INTO dmptool.users (givenName, surName, affiliationId, password,
                           role, acceptedTerms, locked, active, languageId, notify_on_comment_added,
                           notify_on_template_shared, notify_on_feedback_complete, notify_on_plan_shared,
                           notify_on_plan_visibility_change, created, modified)
VALUES ('NIH', 'Admin', 'https://ror.org/01cwqze88',
        '$2a$10$f3wCBdUVt/2aMcPOb.GX1OBO9WMGxDXx5HKeSBBnrMhat4.pis4Pe',
        'ADMIN', 1, 0, 1, 'en-US', 1, 1, 1, 1, 1, CURRENT_DATE(), CURRENT_DATE());

SELECT COUNT(*) FROM dmptool.users; -- 142,059 as of 2025-10-27

-- Update the user records to set the createdById and modifiedById to the user
UPDATE dmptool.users SET createdById = id, modifiedById = id;

-- Migrate the user emails
INSERT INTO dmptool.userEmails (userId, email, isPrimary, isConfirmed, created, createdById, modified, modifiedById)
SELECT userId, email, isPrimary, isConfirmed, created, createdById, modified, modifiedById
FROM migration.user_emails;    -- 142,057

-- Add the default user emails for the test users
INSERT INTO dmptool.userEmails (userId, email, isPrimary, isConfirmed, created, createdById,
                                modified, modifiedById)
    (SELECT id, 'super@example.com', 1, 1, CURRENT_DATE(), id, CURRENT_DATE, id
     FROM dmptool.users WHERE givenName = 'Super' AND surName = 'Admin');

INSERT INTO dmptool.userEmails (userId, email, isPrimary, isConfirmed, created, createdById,
                                modified, modifiedById)
    (SELECT id, 'admin@nih.gov', 1, 1, CURRENT_DATE(), id, CURRENT_DATE, id
     FROM dmptool.users WHERE givenName = 'NIH' AND surName = 'Admin');


SELECT COUNT(*) FROM dmptool.userEmails; -- 142,059 as of 2025-10-27


-- TODO: userDepartments table

-- TODO: Fix issues with ROR Affiliations:
--         - Missing homepages from ROR records
--         - Ignore records whose status is "withdrawn".
--         - Handle duplicate display names (likely due to missing homepage)

-- Migrate affiliations
INSERT IGNORE INTO dmptool.affiliations
  (uri, provenance, name, displayName, searchName, funder, fundrefId, homepage, acronyms, aliases, types,
   logoURI, logoName, contactName, contactEmail, ssoEntityId, managed, active, apiTarget, createdById,
   created, modifiedById, modified)

SELECT uri, provenance, name, displayName, searchName, funder, fundrefId, homepage, acronyms, aliases,
       types, logoURI, logoName, contactName, contactEmail, ssoEntityId, managed, active, apiTarget,
       createdById, created, modifiedById, modified
FROM migration.affiliations;

SELECT COUNT(*) FROM dmptool.affiliations; -- 124,590 as of 2025-10-27  (SHOULD BE 125,981!!!)


-- Migrate affiliation departments
INSERT INTO dmptool.affiliationDepartments (id, affiliationId, name, abbreviation, createdById, created, 													   modifiedById, modified)
SELECT id, affiliationId, name, code, createdById, created, modifiedById, modified
FROM migration.affiliation_departments
WHERE affiliationId IN (SELECT uri FROM migration.affiliations);  -- 935 as of 2025-10-24

-- Migrate affiliation links
INSERT INTO dmptool.affiliationLinks (id, affiliationId, url, text, createdById, created, 													   modifiedById, modified)
SELECT id, affiliationId, url, text, createdById, created, modifiedById, modified
FROM migration.affiliation_links
WHERE affiliationId IN (SELECT uri FROM migration.affiliations);  -- 5,065 as of 2025-10-24

-- Migrate affiliation email domains
INSERT INTO dmptool.affiliationEmailDomains (id, affiliationId, emailDomain, createdById, created,
                                             modifiedById, modified)
SELECT id, affiliationId, emailDomain, createdById, created, modifiedById, modified
FROM migration.affiliation_email_domains
WHERE affiliationId IN (SELECT uri FROM migration.affiliations);   -- 6,344 as of 2025-10-24

-- Migrate the research domains
INSERT INTO dmptool.researchDomains (id, name, uri, description, parentResearchDomainId,
                                     createdById, created, modifiedById, modified)
SELECT id, name, uri, description, parentResearchDomainId, createdById, created, modifiedById, modified
FROM migration.research_domains;   -- 48 row as of 2025-10-24

-- Migrate the tags
INSERT INTO dmptool.tags (id, slug, name, description, created, createdById, modified, modifiedById)
SELECT id, slug, name, description, created, createdById, modified, modifiedById
FROM migration.tags;   -- 14 rows as of 2025-10-24

-- Migrate the member roles
INSERT INTO dmptool.memberRoles (id, label, uri, description, displayOrder, isDefault,
                                 createdById, created, modifiedById, modified)
SELECT id, label, uri, description, displayOrder, isDefault,
       createdById, created, modifiedById, modified
FROM migration.member_roles;   -- 15 rows as of 2025-10-27

-- Migrate the templates
INSERT INTO dmptool.templates (id, name, description, ownerId, latestPublishVisibility, languageId,
                               latestPublishVersion, latestPublishDate, isDirty, bestPractice,
                               created, createdById, modified, modifiedById)
SELECT id, name, description, ownerId, latestPublishVisibility, languageId, latestPublishVersion,
       latestPublishDate, isDirty, bestPractice, created, createdById, modified, modifiedById
FROM migration.templates;    -- 465 rows as of 2025-10-24

-- Migrate the template links
INSERT INTO dmptool.templateLinks (id, templateId, linkType, url, text, created, createdById,
                                   modified, modifiedById)
SELECT id, templateId, linkType, url, text, created, createdById, modified, modifiedById
FROM migration.template_links;    -- 210 rows as of 2025-10-24


-- Migrate the versioned templates
INSERT INTO dmptool.versionedTemplates (id, templateId, active, version, versionType, versionedById,
                                        comment, name, description, ownerId, visibility, languageId,
                                        bestPractice, created, createdById, modified, modifiedById)
SELECT id, template_id, active, version, versionType, versionedById, comment, name, description, ownerId,
       visibility, languageId, bestPractice, created, createdById, modified, modifiedById
FROM migration.versioned_templates;    -- 943 rows as of 2025-10-24

-- Migrate the versioned template links
INSERT INTO dmptool.versionedTemplateLinks (id, versionedTemplateId, linkType, url, text,
                                            created, createdById, modified, modifiedById)
SELECT id, versionedTemplateId, linkType, url, text, created, createdById, modified, modifiedById
FROM migration.versioned_template_links;    -- 569 rows as of 2025-10-24

-- Migrate the sections
INSERT INTO dmptool.sections (id, templateId, name, introduction, displayOrder, bestPractice, isDirty,
                              created, createdById, modified, modifiedById)
SELECT id, templateId, name, introduction, displayOrder, bestPractice, isDirty, created, createdById,
       modified, modifiedById
FROM migration.sections;    -- 2,319 rows as of 2025-10-24

-- Migrate the section tags
INSERT INTO dmptool.sectionTags (id, sectionId, tagId, created, createdById, modified, modifiedById)
SELECT id, sectionId, tagId, created, createdById, modified, modifiedById
FROM migration.section_tags;    -- 5,002 rows as of 2025-10-24

-- Migrate the versioned sections
INSERT INTO dmptool.versionedSections (id, versionedTemplateId, sectionId, name, introduction, displayOrder,
                                       bestPractice, created, createdById, modified, modifiedById)
SELECT id, versionedTemplateId, sectionId, name, introduction, displayOrder, bestPractice, created, createdById,
       modified, modifiedById
FROM migration.versioned_sections;    -- 7,417 rows as of 2025-10-24

-- Migrate the versioned section tags
INSERT INTO dmptool.versionedSectionTags (id, versionedSectionId, tagId, created, createdById,
                                          modified, modifiedById)
SELECT id, versionedSectionId, tagId, created, createdById, modified, modifiedById
FROM migration.versioned_section_tags;    -- 16,613 rows as of 2025-10-24

-- Migrate the questions
INSERT INTO dmptool.questions (id, templateId, sectionId, displayOrder, isDirty, questionText, json,
                               guidanceText, sampleText, created, createdById, modified, modifiedById)
SELECT id, templateId, sectionId, displayOrder, isDirty, questionText, json, guidanceText, sampleText,
       created, createdById, modified, modifiedById
FROM migration.questions;    -- 5,575 rows as of 2025-10-24

-- Migrate the versioned questions
INSERT INTO dmptool.versionedQuestions (id, versionedTemplateId, versionedSectionId, questionId,
                                        questionText, json, guidanceText, sampleText, displayOrder,
                                        created, createdById, modified, modifiedById)
SELECT id, versionedTemplateId, versionedSectionId, questionId, questionText, json, guidanceText,
       sampleText, displayOrder, created, createdById, modified, modifiedById
FROM migration.versioned_questions;    -- 18,105 rows as of 2025-10-24

-- TODO: Migrate questions that are research outputs settings

-- Migrate the projects
INSERT INTO dmptool.projects (id, title, abstractText, researchDomainId, startDate, endDate, isTestProject,
                              created, createdById, modified, modifiedById)
SELECT id, title, abstractText, researchDomainId, startDate, endDate, isTestProject, created, createdById,
       modified, modifiedById
FROM migration.projects;   -- 136,230 rows as of 2025-10-24

-- TODO: Migrate the project collaborators

-- Migrate the project members
INSERT INTO dmptool.projectMembers (id, projectId, affiliationId, givenName, surName, email, orcid, isPrimaryContact,
                                    created, createdById, modified, modifiedById)
SELECT DISTINCT pm.id, pm.projectId, pm.affiliationId, pm.givenName, pm.surName, pm.email, pm.orcid,
                pm.isPrimaryContact, pm.created, pm.createdById, pm.modified, pm.modifiedById
FROM migration.project_members AS pm
         LEFT JOIN migration.affiliations AS a ON pm.affiliationId = a.uri;   -- 121,308 as of 2025-10-27


-- Migrate the project member roles
INSERT INTO dmptool.projectMemberRoles (projectMemberId, memberRoleId, created, createdById, modified, modifiedById)
SELECT projectMemberId, memberRoleId, created, createdById, modified, modifiedById
FROM migration.project_member_roles;   -- 121,308 rows as of 2025-10-27

-- Migrate the project fundings
INSERT INTO dmptool.projectFundings (projectId, affiliationId, status, funderProjectNumber, grantId,
                                     funderOpportunityNumber, created, createdById, modified, modifiedById)
SELECT projectId, affiliationId, status, funderProjectNumber, grantId, funderOpportunityNumber,
       created, createdById, modified, modifiedById
FROM migration.project_fundings;    -- 87,396 rows as of 2025-10-27

-- Migrate the plans
INSERT INTO dmptool.plans (projectId, versionedTemplateId, title, visibility, status, dmpId, registeredById,
                           registered, languageId, featured, created, createdById, modified, modifiedById)
SELECT projectId, versionedTemplateId, title, visibility, status, dmpId, registeredById, registered,
       languageId, featured, created, createdById, modified, modifiedById
FROM migration.plans;


-- Migrate the plan members
INSERT INTO dmptool.planMembers (planId, projectMemberId, isPrimaryContact, created, createdById, modified,
                                 modifiedById)
SELECT planId, projectMemberId, isPrimaryContact, created, createdById, modified, modifiedById
FROM migration.plan_members;

-- Migrate the plan member roles
INSERT INTO dmptool.planMemberRoles (planMemberId, memberRoleId, created, createdById, modified, modifiedById)
SELECT planMemberId, memberRoleId, created, createdById, modified, modifiedById
FROM migration.plan_member_roles;

-- Migrate the plan fundings
INSERT INTO dmptool.planFundings (planId, projectFundingId, created, createdById, modified, modifiedById)
SELECT planId, projectFundingId, created, createdById, modified, modifiedById
FROM migration.plan_fundings;

