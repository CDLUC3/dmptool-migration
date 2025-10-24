-- PURGE **********************

-- Clear ALL tables
DELETE FROM dmptool.affiliationDepartments;
DELETE FROM dmptool.affiliationEmailDomains;
DELETE FROM dmptool.affiliationLinks;

DELETE FROM dmptool.workVersions;
DELETE FROM dmptool.works;
DELETE FROM dmptool.relatedWorks;

DELETE FROM dmptool.feedbackComments;
DELETE FROM dmptool.feedback;
DELETE FROM dmptool.answerComments;
DELETE FROM dmptool.answers;
DELETE FROM dmptool.planFundings;
DELETE FROM dmptool.planMemberRoles;
DELETE FROM dmptool.planMembers;
DELETE FROM dmptool.plans;
DELETE FROM dmptool.projectFundings;
DELETE FROM dmptool.projectMemberRoles;
DELETE FROM dmptool.projectMembers;
DELETE FROM dmptool.projects;

DELETE FROM dmptool.versionedCustomQuestions;
DELETE FROM dmptool.customQuestions;
DELETE FROM dmptool.versionedCustomSections;
DELETE FROM dmptool.customSections;
DELETE FROM dmptool.versionedQuestionCustomizations;
DELETE FROM dmptool.questionCustomizations;
DELETE FROM dmptool.versionedSectionCustomizations;
DELETE FROM dmptool.sectionCustomizations;
DELETE FROM dmptool.versionedTemplateCustomizations;
DELETE FROM dmptool.templateCustomizations;

DELETE FROM dmptool.versionedQuestionConditions;
DELETE FROM dmptool.questionConditions;
DELETE FROM dmptool.versionedQuestions;
DELETE FROM dmptool.questions;
DELETE FROM dmptool.versionedSectionTags;
DELETE FROM dmptool.sectionTags;
DELETE FROM dmptool.versionedSections;
DELETE FROM dmptool.sections;
DELETE FROM dmptool.templateCollaborators;
DELETE FROM dmptool.versionedTemplateLinks;
DELETE FROM dmptool.templateLinks;
DELETE FROM dmptool.versionedTemplates;
DELETE FROM dmptool.templates;

DELETE FROM dmptool.metadataStandardResearchDomains;
DELETE FROM dmptool.repositoryResearchDomains;

DELETE FROM dmptool.licenses;
DELETE FROM dmptool.metadataStandards;
DELETE FROM dmptool.repositories;

DELETE FROM dmptool.memberRoles;
DELETE FROM dmptool.researchDomains;
DELETE FROM dmptool.tags;
DELETE FROM dmptool.projectOutputTypes;

DELETE FROM dmptool.userDepartments;
DELETE FROM dmptool.userEmails;
DELETE FROM dmptool.users;

DELETE FROM dmptool.affiliations;


-- MIGRATIONS **********************

-- Migrate users
INSERT IGNORE INTO dmptool.users (id, givenName, surName, affiliationId, orcid, ssoId, password, oldPasswordHash,
								  acceptedTerms, locked, active, languageId, last_sign_in, notify_on_comment_added,
								  		 notify_on_template_shared, notify_on_feedback_complete, notify_on_plan_shared,
								  		 notify_on_plan_visibility_change, created, createdById, modified, modifiedById)
SELECT id, givenName, surName, affiliationId, orcid, ssoId, password, oldPasswordHash, acceptedTerms, locked,
       active, languageId, last_sign_in, notify_on_comment_added, notify_on_template_shared,
       notify_on_feedback_complete, notify_on_plan_shared, notify_on_plan_visibility_change, created, createdById,
       modified, modifiedById
FROM migration.users;

SELECT COUNT(*) FROM dmptool.users; -- 141,269 as of 2025-10-24

INSERT INTO dmptool.userEmails (userId, email, isPrimary, isConfirmed, created, createdById, modified, modifiedById)
SELECT userId, email, isPrimary, isConfirmed, created, createdById, modified, modifiedById
FROM migration.user_emails;

SELECT COUNT(*) FROM dmptool.userEmails; -- 141,269 as of 2025-10-24

-- Update the user records to set the createdById and modifiedById to the user
UPDATE dmptool.users SET createdById = id, modifiedById = id;


-- TODO: userDepartments table

-- Migrate affiliations
INSERT IGNORE INTO dmptool.affiliations
  (uri, provenance, name, displayName, searchName, funder, fundrefId, homepage, acronyms, aliases, types,
   logoURI, logoName, contactName, contactEmail, ssoEntityId, managed, active, apiTarget, createdById,
   created, modifiedById, modified)

SELECT uri, provenance, name, displayName, searchName, funder, fundrefId, homepage, acronyms, aliases,
       types, logoURI, logoName, contactName, contactEmail, ssoEntityId, managed, active, apiTarget,
       createdById, created, modifiedById, modified
FROM migration.affiliations;

SELECT COUNT(*) FROM dmptool.affiliations; -- 124,590 as of 2025-10-24

-- Migrate affiliation departments
INSERT IGNORE INTO dmptool.affiliationDepartments (id, affiliationId, name, abbreviation, createdById, created, 													   modifiedById, modified)
SELECT id, affiliationId, name, abbreviation, createdById, created, modifiedById, modified
FROM migration.affiliation_departments
WHERE affiliationId IN (SELECT uri FROM migration.affiliations);  -- 935 as of 2025-10-24

-- Migrate affiliation links
INSERT IGNORE INTO dmptool.affiliationLinks (id, affiliationId, url, text, createdById, created, 													   modifiedById, modified)
SELECT id, affiliationId, url, text, createdById, created, modifiedById, modified
FROM migration.affiliation_links
WHERE affiliationId IN (SELECT uri FROM migration.affiliations);  -- 5,065 as of 2025-10-24

-- Migrate affiliation email domains
INSERT IGNORE INTO dmptool.affiliationEmailDomains (id, affiliationId, emailDomain, createdById, created,
													modifiedById, modified)
SELECT id, affiliationId, emailDomain, createdById, created, modifiedById, modified
FROM migration.affiliation_email_domains
WHERE affiliationId IN (SELECT uri FROM migration.affiliations);   -- 6,344 as of 2025-10-24

-- Migrate the research domains
INSERT IGNORE INTO dmptool.researchDomains (id, name, url, description, parentResearchDomainId,
											createdById, created, modifiedById, modified)
SELECT id, name, url, description, parentResearchDomainId, createdById, created, modifiedById, modified
FROM migration.research_domains;   -- 48 row as of 2025-10-24

-- Migrate the tags
INSERT IGNORE INTO dmptool.tags (id, slug, name, description, created, createdById, modified, modifiedById)
SELECT id, slug, name, description, created, createdById, modified, modifiedById
FROM migration.tags;   -- 14 rows as of 2025-10-24

-- Migrate the templates
INSERT IGNORE INTO dmptool.templates (id, name, description, ownerId, latestPublishVisibility, languageId,
									  latestPublishVersion, latestPublishDate, isDirty, bestPractice,
									         created, createdById, modified, modifiedById)
SELECT id, name, description, ownerId, latestPublishVisibility, languageId, latestPublishVersion,
       latestPublishDate, isDirty, bestPractice, created, createdById, modified, modifiedById
FROM migration.templates;    -- 465 rows as of 2025-10-24

-- Migrate the template links
INSERT IGNORE INTO dmptool.templateLinks (id, templateId, linkType, url, text, created, createdById,
										  modified, modifiedById)
SELECT id, templateId, linkType, url, text, created, createdById, modified, modifiedById
FROM migration.template_links;    -- 210 rows as of 2025-10-24


-- Migrate the versioned templates
INSERT IGNORE INTO dmptool.versionedTemplates (id, templateId, active, version, versionType, versionedById,
                                               comment, name, description, ownerId, visibility, languageId,
                                               bestPractice, created, createdById, modified, modifiedById)
SELECT id, template_id, active, version, versionType, versionedById, comment, name, description, ownerId,
       visibility, languageId, bestPractice, created, createdById, modified, modifiedById
FROM migration.versioned_templates;    -- 943 rows as of 2025-10-24

-- Migrate the versioned template links
INSERT IGNORE INTO dmptool.versionedTemplateLinks (id, versionedTemplateId, linkType, url, text,
												   created, createdById, modified, modifiedById)
SELECT id, versionedTemplateId, linkType, url, text, created, createdById, modified, modifiedById
FROM migration.versioned_template_links;    -- 569 rows as of 2025-10-24

-- Migrate the sections
INSERT IGNORE INTO dmptool.sections (id, templateId, name, introduction, displayOrder, bestPractice, isDirty,
									 created, createdById, modified, modifiedById)
SELECT id, templateId, name, introduction, displayOrder, bestPractice, isDirty, created, createdById,
       modified, modifiedById
FROM migration.sections;    -- 2,319 rows as of 2025-10-24

-- Migrate the section tags
INSERT IGNORE INTO dmptool.sectionTags (id, sectionId, tagId, created, createdById, modified, modifiedById)
SELECT id, sectionId, tagId, created, createdById, modified, modifiedById
FROM migration.section_tags;    -- 5,002 rows as of 2025-10-24

-- Migrate the versioned sections
INSERT IGNORE INTO dmptool.versionedSections (id, versionedTemplateId, sectionId, name, introduction, displayOrder,
											  bestPractice, created, createdById, modified, modifiedById)
SELECT id, versionedTemplateId, sectionId, name, introduction, displayOrder, bestPractice, created, createdById,
       modified, modifiedById
FROM migration.versioned_sections;    -- 7,417 rows as of 2025-10-24

-- Migrate the versioned section tags
INSERT IGNORE INTO dmptool.versionedSectionTags (id, versionedSectionId, tagId, created, createdById,
												 modified, modifiedById)
SELECT (id, versionedSectionId, tagId, created, createdById, modified, modifiedById)
FROM migration.versioned_section_tags;    -- 16,613 rows as of 2025-10-24

-- Migrate the questions
INSERT IGNORE INTO dmptool.questions (id, templateId, sectionId, displayOrder, isDirty, questionText, json,
									  guidanceText, sampleText, created, createdById, modified, modifiedById)
SELECT id, templateId, sectionId, displayOrder, isDirty, questionText, json, guidanceText, sampleText,
       created, createdById, modified, modifiedById
FROM migration.questions;    -- 5,575 rows as of 2025-10-24

-- Migrate the versioned questions
INSERT IGNORE INTO dmptool.versionedQuestions (id, versionedTemplateId, versionedSectionId, questionId,
											   questionText, json, guidanceText, sampleText, displayOrder,
											   created, createdById, modified, modifiedById)
SELECT id, versionedTemplateId, versionedSectionId, questionId, questionText, json, guidanceText,
       sampleText, displayOrder, created, createdById, modified, modifiedById
FROM migration.versioned_questions;    -- 18,105 rows as of 2025-10-24


-- Migrate the projects
INSERT IGNORE INTO dmptool.projects (id, title, abstractText, researchDomainId, startDate, endDate, isTestProject,
									 created, createdById, modified, modifiedById)
SELECT id, title, abstractText, researchDomainId, startDate, endDate, isTestProject, created, createdById,
       modified, modifiedById
FROM migration.projects;   -- 136,230 rows as of 2025-10-24

-- TODO: Migrate the project collaborators

-- Migrate the project members
INSERT INTO dmptool.projectMembers (id, projectId, affiliationId, givenName, surName, email, orcid, isPrimaryContact,
                                    created, createdById, modified, modifiedById)
SELECT id, projectId, affiliationId, givenName, surName, email, orcid, isPrimaryContact,
       created, createdById, modified, modifiedById
FROM migration.project_members;
