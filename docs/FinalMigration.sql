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
TRUNCATE dmptool.researchOutputTypes;

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
FROM migration.users;    -- 141,266

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
VALUES ('Test', 'Admin', 'https://ror.org/03yrm5c26',
        '$2a$10$f3wCBdUVt/2aMcPOb.GX1OBO9WMGxDXx5HKeSBBnrMhat4.pis4Pe',
        'ADMIN', 1, 0, 1, 'en-US', 1, 1, 1, 1, 1, CURRENT_DATE(), CURRENT_DATE());

INSERT dmptool.users (givenName, surName, affiliationId, password,
                           role, acceptedTerms, locked, active, languageId, notify_on_comment_added,
                           notify_on_template_shared, notify_on_feedback_complete, notify_on_plan_shared,
                           notify_on_plan_visibility_change, created, modified)
VALUES ('Test', 'Researcher', 'https://ror.org/03yrm5c26',
        '$2a$10$f3wCBdUVt/2aMcPOb.GX1OBO9WMGxDXx5HKeSBBnrMhat4.pis4Pe',
        'RESEARCHER', 1, 0, 1, 'en-US', 1, 1, 1, 1, 1, CURRENT_DATE(), CURRENT_DATE());


SELECT COUNT(*) FROM dmptool.users; -- 141,268 as of 2025-11-03

-- Update the user records to set the createdById and modifiedById to the user
UPDATE dmptool.users SET createdById = id, modifiedById = id;

-- Migrate the user emails
INSERT INTO dmptool.userEmails (userId, email, isPrimary, isConfirmed, created, createdById, modified, modifiedById)
SELECT userId, email, isPrimary, isConfirmed, created, createdById, modified, modifiedById
FROM migration.user_emails;    -- 141,266 rows as of 2025-11-03

-- Add the default user emails for the test users
INSERT INTO dmptool.userEmails (userId, email, isPrimary, isConfirmed, created, createdById,
                                modified, modifiedById)
    (SELECT id, 'super@example.com', 1, 1, CURRENT_DATE(), id, CURRENT_DATE, id
     FROM dmptool.users WHERE givenName = 'Super' AND surName = 'Admin');

INSERT INTO dmptool.userEmails (userId, email, isPrimary, isConfirmed, created, createdById,
                                modified, modifiedById)
    (SELECT id, 'admin@example.gov', 1, 1, CURRENT_DATE(), id, CURRENT_DATE, id
     FROM dmptool.users WHERE givenName = 'Test' AND surName = 'Admin');

INSERT INTO dmptool.userEmails (userId, email, isPrimary, isConfirmed, created, createdById,
                                modified, modifiedById)
    (SELECT id, 'researcher@example.com', 1, 1, CURRENT_DATE(), id, CURRENT_DATE, id
     FROM dmptool.users WHERE givenName = 'Test' AND surName = 'Researcher');

SELECT COUNT(*) FROM dmptool.userEmails; -- 141,268 as of 2025-11-03


-- TODO: userDepartments table

-- TODO: Fix issues with ROR Affiliations:
--         - Handle duplicate display names (likely due to missing homepage)

-- Migrate affiliations
INSERT IGNORE INTO dmptool.affiliations
  (uri, provenance, name, displayName, searchName, funder, fundrefId, homepage, acronyms, aliases, types,
   logoURI, logoName, contactName, contactEmail, ssoEntityId, managed, active, apiTarget, createdById,
   created, modifiedById, modified)

SELECT DISTINCT uri, provenance, name, displayName, searchName, funder, fundrefId, homepage, acronyms, aliases,
                types, logoURI, logoName, contactName, contactEmail, ssoEntityId, managed, active, apiTarget,
                createdById, created, modifiedById, modified
FROM migration.affiliations;

SELECT COUNT(*) FROM dmptool.affiliations; -- 122,148 as of 2025-11-03


-- Migrate affiliation departments
INSERT INTO dmptool.affiliationDepartments (id, affiliationId, name, abbreviation, createdById, created, 													   modifiedById, modified)
SELECT id, affiliationId, name, code, createdById, created, modifiedById, modified
FROM migration.affiliation_departments
WHERE affiliationId IN (SELECT uri FROM migration.affiliations);  -- 937 as of 2025-11-03

-- Migrate affiliation links
INSERT IGNORE INTO dmptool.affiliationLinks (id, affiliationId, url, text, createdById, created, 													   modifiedById, modified)
SELECT id, affiliationId, url, text, createdById, created, modifiedById, modified
FROM migration.affiliation_links
WHERE affiliationId IN (SELECT uri FROM migration.affiliations);  -- 5,077 as of 2025-11-03

-- Migrate affiliation email domains
INSERT IGNORE INTO dmptool.affiliationEmailDomains (id, affiliationId, emailDomain, createdById, created,
													modifiedById, modified)
SELECT id, affiliationId, emailDomain, createdById, created, modifiedById, modified
FROM migration.affiliation_email_domains
WHERE affiliationId IN (SELECT uri FROM migration.affiliations);   -- 6,357 as of 2025-11-03

-- Migrate the research domains
INSERT INTO dmptool.researchDomains (id, name, uri, description, parentResearchDomainId,
                                     createdById, created, modifiedById, modified)
SELECT id, name, uri, description, parentResearchDomainId, createdById, created, modifiedById, modified
FROM migration.research_domains;   -- 48 row as of 2025-11-03

-- Migrate the tags
INSERT INTO dmptool.tags (id, slug, name, description, created, createdById, modified, modifiedById)
SELECT id, slug, name, description, created, createdById, modified, modifiedById
FROM migration.tags;   -- 14 rows as of 2025-11-03

-- Migrate the member roles
INSERT INTO dmptool.memberRoles (id, label, uri, description, displayOrder, isDefault,
                                 createdById, created, modifiedById, modified)
SELECT id, label, uri, description, displayOrder, isDefault,
       createdById, created, modifiedById, modified
FROM migration.member_roles;   -- 15 rows as of 2025-11-03

-- Migrate the research output types
INSERT INTO dmptool.researchOutputTypes (name, value, description, createdById, created, modifiedById, modified)
SELECT name, value, description, createdById, created, modifiedById, modified
FROM migration.research_putput_types; -- 15 rows as of 2025-11-19

-- Migrate the repositories
INSERT IGNORE INTO dmptool.repositories (name, uri, description, website, keywords, repositoryTypes,
								  createdById, created, modifiedById, modified)
SELECT DISTINCT name, uri, description, website, keywords, repositoryTypes, createdById, created, modifiedById, modified
FROM migration.repositories;   -- 4,117 rows as of 2025-11-19

-- Migrate the metadata standards
INSERT IGNORE INTO dmptool.metadataStandards (name, uri, description, createdById, created, modifiedById, modified)
SELECT DISTINCT name, uri, description, createdById, created, modifiedById, modified
FROM migration.metadata_standards;   -- 281 rows as of 2025-11-19

-- Migrate the licenses
INSERT INTO dmptool.licenses (name, uri, description, createdById, created, modifiedById, modified)
SELECT DISTINCT name, uri, description, createdById, created, modifiedById, modified
FROM migration.licenses;   -- 680 rows as of 2025-11-19


-- TODO: Unable to migrate templates for ROR https://ror.org/03e62d071 because of displayName issue mentioned above

-- Migrate the templates
INSERT IGNORE INTO dmptool.templates (id, name, description, ownerId, latestPublishVisibility, languageId,
									  latestPublishVersion, latestPublishDate, isDirty, bestPractice,
									         created, createdById, modified, modifiedById)
SELECT id, name, description, ownerId, latestPublishVisibility, languageId, latestPublishVersion,
       latestPublishDate, isDirty, bestPractice, created, createdById, modified, modifiedById
FROM migration.templates;    -- 471 rows as of 2025-11-03

-- Set the bestPractice / Default template
UPDATE dmptool.templates SET bestPractice = 1 WHERE ownerId = 'https://ror.org/01k9d6864';

-- Migrate the template links
INSERT IGNORE INTO dmptool.templateLinks (id, templateId, linkType, url, text, created, createdById,
										  modified, modifiedById)
SELECT id, templateId, linkType, url, text, created, createdById, modified, modifiedById
FROM migration.template_links;    -- 211 rows as of 2025-11-03


-- Migrate the versioned templates
INSERT IGNORE INTO dmptool.versionedTemplates (id, templateId, active, version, versionType, versionedById,
                                               comment, name, description, ownerId, visibility, languageId,
                                               bestPractice, created, createdById, modified, modifiedById)
SELECT id, template_id, active, version, versionType, versionedById, comment, name, description, ownerId,
       visibility, languageId, bestPractice, created, createdById, modified, modifiedById
FROM migration.versioned_templates;    -- 1,126 rows as of 2025-11-03

-- Migrate the versioned template links
INSERT IGNORE INTO dmptool.versionedTemplateLinks (id, versionedTemplateId, linkType, url, text,
												   created, createdById, modified, modifiedById)
SELECT id, versionedTemplateId, linkType, url, text, created, createdById, modified, modifiedById
FROM migration.versioned_template_links;    -- 601 rows as of 2025-11-03

-- Migrate the sections
INSERT IGNORE INTO dmptool.sections (id, templateId, name, introduction, displayOrder, bestPractice, isDirty,
									 created, createdById, modified, modifiedById)
SELECT id, templateId, name, introduction, displayOrder, bestPractice, isDirty, created, createdById,
       modified, modifiedById
FROM migration.sections;    -- 2,336 rows as of 2025-11-03

-- Migrate the section tags
INSERT IGNORE INTO dmptool.sectionTags (id, sectionId, tagId, created, createdById, modified, modifiedById)
SELECT id, sectionId, tagId, created, createdById, modified, modifiedById
FROM migration.section_tags;    -- 5,090 rows as of 2025-11-03

-- Migrate the versioned sections
INSERT IGNORE INTO dmptool.versionedSections (id, versionedTemplateId, sectionId, name, introduction, displayOrder,
											  bestPractice, created, createdById, modified, modifiedById)
SELECT id, versionedTemplateId, sectionId, name, introduction, displayOrder, bestPractice, created, createdById,
       modified, modifiedById
FROM migration.versioned_sections;    -- 8,033 rows as of 2025-11-03

-- Migrate the versioned section tags
INSERT IGNORE INTO dmptool.versionedSectionTags (id, versionedSectionId, tagId, created, createdById,
												 modified, modifiedById)
SELECT id, versionedSectionId, tagId, created, createdById, modified, modifiedById
FROM migration.versioned_section_tags;    -- 17,506 rows as of 2025-11-03

-- Migrate the questions
INSERT IGNORE INTO dmptool.questions (id, templateId, sectionId, displayOrder, isDirty, questionText, json,
									  guidanceText, sampleText, created, createdById, modified, modifiedById)
SELECT id, templateId, sectionId, displayOrder, isDirty, questionText, json, guidanceText, sampleText,
       created, createdById, modified, modifiedById
FROM migration.questions;    -- 5,583 rows as of 2025-11-03

-- Migrate the versioned questions
INSERT IGNORE INTO dmptool.versionedQuestions (id, versionedTemplateId, versionedSectionId, questionId,
											   questionText, json, guidanceText, sampleText, displayOrder,
											   created, createdById, modified, modifiedById)
SELECT id, versionedTemplateId, versionedSectionId, questionId, questionText, json, guidanceText,
       sampleText, displayOrder, created, createdById, modified, modifiedById
FROM migration.versioned_questions;    -- 19,271 rows as of 2025-11-03

-- Migrate the guidance
INSERT INTO dmptool.guidanceGroups (id, affiliationId, name, isDirty, optionalSubset, bestPractice, latestPublishedVersion, latestPublishedDate,
                                    created, createdById, modified, modifiedById)
SELECT id, affiliationId, name, isDirty, optionalSubset, bestPractice, latestPublishedVersion, latestPublishedDate,
       created, createdById, modified, modifiedById
FROM migration.guidance_groups; -- 2,452 rows as of 2025-11-20

INSERT INTO dmptool.guidance (id, guidanceGroupId, guidanceText, created, createdById, modified, modifiedById)
SELECT id, guidanceGroupId, guidanceText, created, createdById, modified, modifiedById
FROM migration.guidance; -- 1,672 rows as of 2025-11-20

INSERT INTO dmptool.guidanceTags (id, guidanceId, tagId, created, createdById, modified, modifiedById)
SELECT id, guidanceId, tagId, created, createdById, modified, modifiedById
FROM migration.guidance_tags; -- 2,291 rows as of 2025-11-20

INSERT INTO dmptool.versionedGuidanceGroups (id, guidanceGroupId, name, active, optionalSubset, bestPractice, version,
                                             created, createdById, modified, modifiedById)
SELECT id, guidanceGroupId, name, active, optionalSubset, bestPractice, version,
       created, createdById, modified, modifiedById
FROM migration.versioned_guidance_groups; -- 275 rows as of 2025-11-20

INSERT INTO dmptool.versionedGuidance (id, versionedGuidanceGroupId, guidanceId, guidanceText, created, createdById, modified, modifiedById)
SELECT id, versionedGuidanceGroupId, guidanceId, guidanceText, created, createdById, modified, modifiedById
FROM migration.versioned_guidance; -- 1,510 rows as of 2025-11-20

INSERT INTO dmptool.versionedGuidanceTags (id, versionedGuidanceId, tagId, created, createdById, modified, modifiedById)
SELECT id, versionedGuidanceId, tagId, created, createdById, modified, modifiedById
FROM migration.versioned_guidance_tags; -- 2,068 rows as of 2025-11-20

-- Migrate the projects
INSERT INTO dmptool.projects (id, title, abstractText, researchDomainId, startDate, endDate, isTestProject,
                              created, createdById, modified, modifiedById)
SELECT id, title, abstractText, researchDomainId, startDate, endDate, isTestProject, created, createdById,
       modified, modifiedById
FROM migration.projects;   -- 136,237 rows as of 2025-11-03

-- Migrate the project collaborators
INSERT IGNORE INTO dmptool.projectCollaborators (projectId, email, invitedById, userId, accessLevel,
                                          created, createdById, modified, modifiedById)
SELECT DISTINCT projectId, email, invitedById, userId, accessLevel, created, createdById, modified, modifiedById
FROM migration.project_collaborators;   -- 147,401 rows as of 2025-11-03

-- TODO: Deal with issue of duplicate users in intermediate.users (e.g. ids 48928, 48929)

-- Migrate the project members
INSERT IGNORE INTO dmptool.projectMembers (id, projectId, affiliationId, givenName, surName, email, orcid,
										   isPrimaryContact, created, createdById, modified, modifiedById)
SELECT DISTINCT id, projectId, affiliationId, givenName, surName, email, orcid,
                isPrimaryContact, created, createdById, modified, modifiedById
FROM migration.project_members AS pm;   -- 79,389 as of 2025-11-17

-- Migrate the project member roles
INSERT IGNORE INTO dmptool.projectMemberRoles (projectMemberId, memberRoleId, created, createdById, modified, modifiedById)
SELECT DISTINCT projectMemberId, memberRoleId, created, createdById, modified, modifiedById
FROM migration.project_member_roles;   -- 203,201 rows as of 2025-11-06

-- Migrate the project funding
INSERT IGNORE INTO dmptool.projectFundings (projectId, affiliationId, status, funderProjectNumber, grantId,
									 funderOpportunityNumber, created, createdById, modified, modifiedById)
SELECT projectId, affiliationId, status, funderProjectNumber, grantId, funderOpportunityNumber,
       created, createdById, modified, modifiedById
FROM migration.project_fundings;    -- 86,582 rows as of 2025-11-03

-- TODO: Determine why some versionedTemplateId are NULL. Related to missing affiliations?

-- Migrate the plans
INSERT IGNORE INTO dmptool.plans (projectId, versionedTemplateId, title, visibility, status, dmpId, registeredById,
						   registered, languageId, featured, created, createdById, modified, modifiedById)
SELECT projectId, versionedTemplateId, title, visibility, status, dmpId, registeredById, registered,
       languageId, featured, created, createdById, modified, modifiedById
FROM migration.plans;    -- 133,018 rows as of 2025-11-03

-- Migrate the answers
INSERT IGNORE INTO dmptool.answers (planId, versionedSectionId, versionedQuestionId, json, createdById, created, modifiedById, modified)
SELECT planId, versionedSectionId, versionedQuestionId, json,
       createdById, created, modifiedById, modified)
FROM migration.answers
WHERE planId IS NOT NULL; -- 567,112 rows as of 2025-11-13

-- Migrate the plan members
INSERT IGNORE INTO dmptool.planMembers (id, planId, projectMemberId, isPrimaryContact, created, createdById, modified,
								 modifiedById)
SELECT id, planId, projectMemberId, isPrimaryContact, created, createdById, modified, modifiedById
FROM migration.plan_members;    -- 133,198 rows as of 2025-11-03

-- Migrate the plan member roles
INSERT IGNORE INTO dmptool.planMemberRoles (planMemberId, memberRoleId, created, createdById, modified, modifiedById)
SELECT planMemberId, memberRoleId, created, createdById, modified, modifiedById
FROM migration.plan_member_roles;    -- 133,198 rows as of 2025-11-03

-- Migrate the plan funding
INSERT IGNORE INTO dmptool.planFundings (planId, projectFundingId, created, createdById, modified, modifiedById)
SELECT planId, projectFundingId, created, createdById, modified, modifiedById
FROM migration.plan_fundings;    -- 79,101 rows as of 2025-11-03

-- Migrate the works
INSERT INTO dmptool.works (doi, created, createdById, modified, modifiedById)
SELECT DISTINCT rw.value, MAX(p.created), MAX(p.createdById), MAX(p.modified), MAX(p.modifiedById)
FROM migration.related_works rw
         INNER JOIN migration.plans p ON rw.plan_id = p.old_plan_id
WHERE rw.identifier_type = 'DOI' AND rw.is_valid = 1
GROUP BY rw.value;   -- 321 rows as of 2025-11-05

-- TODO: Finish the workVersions and relatedWork migrations

-- Migrate the work versions

INSERT IGNORE INTO dmptool.workVersions (workId, hash, workType, authors, institutions, funders,
                                         awards, sourceName, sourceUrl,
                                         created, createdById, modified, modifiedById)
SELECT w.id AS workId, '{}', 'DATASET', '[]', '[]', '[]', '[]', 'DMPTOOL', 'https://dmptool.org',
  created, createdById, modified, modifiedById
FROM migration.related_works AS rw
  INNER JOIN dmptool.works AS w ON rw.value = w.doi;
WHERE migration.related_works.identifier_type = 'DOI' AND migration.related_works.is_valid = 1;   -- 112,345 rows as of 2025-11-03

-- Migrate the related works
INSERT IGNORE INTO dmptool.relatedWorks (planId, workVersionId, score, scoreMax, status, sourceType,
                                         created, createdById, modified, modifiedById)
SELECT p.id, wv.id, 1, 1, 'ACCEPTED', 'USER_ADDED', p.created, p.createdById, p.modified, p.modifiedById
FROM migration.related_works AS rw
  INNER JOIN dmptool.works AS w ON rw.value = w.doi
    INNER JOIN dmptool.workVersions AS wv ON w.id = wv.workId
  INNER JOIN migration.plans As p ON rw.plan_id = p.old_plan_id; -- 328 rows as of 2025-11-05


-- Add the API info for all NSF/NASA affiliations
-- ---------------------------------------------------
UPDATE affiliations SET apiTarget = '/awards/nsf'
WHERE uri IN ('https://ror.org/0171mag52', 'https://ror.org/027k65916', 'https://ror.org/027ka1x80',
              'https://ror.org/0540g1c48', 'https://ror.org/02acart68', 'https://ror.org/059fqnc42',
              'https://ror.org/01cyfxe35', 'https://ror.org/04xx4z452', 'https://ror.org/0399mhs52',
              'https://ror.org/02epydz83', 'https://ror.org/03j9e2j92', 'https://ror.org/02s42x260',
              'https://ror.org/01p7gwa14', 'https://ror.org/021nxhr62', 'https://ror.org/01qxmdg18',
              'https://ror.org/04aqat463', 'https://ror.org/006ndaj41', 'https://ror.org/03em45j53',
              'https://ror.org/045t78n53', 'https://ror.org/00r57r863', 'https://ror.org/01rcfpa16',
              'https://ror.org/014eweh95', 'https://ror.org/001xhss06', 'https://ror.org/04qn9mx93',
              'https://ror.org/03g87he71', 'https://ror.org/01tnvpc68', 'https://ror.org/01rvays47',
              'https://ror.org/002jdaq33', 'https://ror.org/025kzpk63', 'https://ror.org/04nh1dc89',
              'https://ror.org/01mng8331', 'https://ror.org/02rdzmk74', 'https://ror.org/053a2cp42',
              'https://ror.org/014bj5w56', 'https://ror.org/00whkrf32', 'https://ror.org/05s7cqk18',
              'https://ror.org/02kd4km72', 'https://ror.org/03mamvh39', 'https://ror.org/00b6sbb32',
              'https://ror.org/0471zv972', 'https://ror.org/028yd4c30', 'https://ror.org/01krpsy48',
              'https://ror.org/050rnw378', 'https://ror.org/0388pet74', 'https://ror.org/03xyg3m20',
              'https://ror.org/05p847d66', 'https://ror.org/037gd6g64', 'https://ror.org/05v01mk25',
              'https://ror.org/05wqqhv83', 'https://ror.org/05nwjp114', 'https://ror.org/05fnzca26',
              'https://ror.org/02trddg58', 'https://ror.org/029b7h395', 'https://ror.org/04mg8wm74',
              'https://ror.org/01ar8dr59', 'https://ror.org/01pc7k308', 'https://ror.org/051fftw81',
              'https://ror.org/04ap5x931', 'https://ror.org/00apvva27', 'https://ror.org/04nseet23',
              'https://ror.org/04k9mqs78', 'https://ror.org/01k638r21', 'https://ror.org/01gmp5538',
              'https://ror.org/01vnjbg30', 'https://ror.org/03h7mcc28', 'https://ror.org/05wgkzg12',
              'https://ror.org/0445wmv88', 'https://ror.org/02dz2hb46', 'https://ror.org/034m1ez10',
              'https://ror.org/02a65dj82', 'https://ror.org/020fhsn68', 'https://ror.org/03z9hh605',
              'https://ror.org/04ya3kq71', 'https://ror.org/04evh7y43', 'https://ror.org/04h67aa53',
              'https://ror.org/025dabr11', 'https://ror.org/04vw0kz07', 'https://ror.org/054ydxh33',
              'https://ror.org/01sharn77', 'https://ror.org/0401vze59', 'https://ror.org/04hccab49',
              'https://ror.org/02ch5q898', 'https://ror.org/04437j066', 'https://ror.org/028b18z22',
              'https://ror.org/00ryjtt64', 'https://ror.org/01dy3j343', 'https://ror.org/02yhmtm27',
              'https://ror.org/05q5zzn71', 'https://ror.org/02ajbht29', 'https://ror.org/057xcp713',
              'https://ror.org/04xr3m042', 'https://ror.org/05b5wvf11', 'https://ror.org/01bp8jn44',
              'https://ror.org/01wmcm405', 'https://ror.org/03cbpc337', 'https://ror.org/02z0mvz29',
              'https://ror.org/01ghfgz70', 'https://ror.org/02shwmm76');

-- Add the API info for all NIH affiliations
-- ---------------------------------------------------
UPDATE affiliations SET apiTarget = '/awards/nih'
WHERE uri IN ('https://ror.org/01cwqze88', 'https://ror.org/04mhx6838', 'https://ror.org/012pb6c26',
              'https://ror.org/03wkg3b53', 'https://ror.org/0060t0j89', 'https://ror.org/00372qc85',
              'https://ror.org/00190t495', 'https://ror.org/00j4k1h63', 'https://ror.org/01y3zfr79',
              'https://ror.org/04q48ey07', 'https://ror.org/0493hgw16', 'https://ror.org/04vfsmv21',
              'https://ror.org/03jh5a977', 'https://ror.org/04xeg9z08', 'https://ror.org/01s5ya894',
              'https://ror.org/02meqm098', 'https://ror.org/049v75w11', 'https://ror.org/004a2wv92',
              'https://ror.org/00adh9b73', 'https://ror.org/043z4tv69', 'https://ror.org/00x19de83',
              'https://ror.org/02jzrsm59', 'https://ror.org/006zn3t30', 'https://ror.org/04byxyr05',
              'https://ror.org/04pw6fb54', 'https://ror.org/05aq6yn88', 'https://ror.org/02xey9a22',
              'https://ror.org/00fj8a872', 'https://ror.org/01wtjyf13', 'https://ror.org/04r5s4b52',
              'https://ror.org/046zezr58', 'https://ror.org/02e3wq066', 'https://ror.org/031gy6182',
              'https://ror.org/054j5yq82', 'https://ror.org/02yrzyf97', 'https://ror.org/012wp4251',
              'https://ror.org/01jdyfj45', 'https://ror.org/04g4sf283');

-- Add the API info for all affiliations who appear in the Crossref grants API
-- ---------------------------------------------------
UPDATE affiliations SET apiTarget = '/awards/crossref/10.13039/501100011730' WHERE uri = 'https://ror.org/00x0z1472';
UPDATE affiliations SET apiTarget = '/awards/crossref/10.13039/501100002241' WHERE uri = 'https://ror.org/00097mb19';
UPDATE affiliations SET apiTarget = '/awards/crossref/10.13039/501100001821' WHERE uri = 'https://ror.org/01f9mc681';
UPDATE affiliations SET apiTarget = '/awards/crossref/10.13039/501100000223' WHERE uri = 'https://ror.org/000hkd473';
UPDATE affiliations SET apiTarget = '/awards/crossref/10.13039/100010586' WHERE uri = 'https://ror.org/04a2qqf85';
UPDATE affiliations SET apiTarget = '/awards/crossref/10.13039/100008984' WHERE uri = 'https://ror.org/0252rqe04';
UPDATE affiliations SET apiTarget = '/awards/crossref/10.13039/100008539' WHERE uri = 'https://ror.org/00qfsn733';
UPDATE affiliations SET apiTarget = '/awards/crossref/10.13039/100006309' WHERE uri = 'https://ror.org/04sedwh45';
UPDATE affiliations SET apiTarget = '/awards/crossref/10.13039/100005536' WHERE uri = 'https://ror.org/02r8tn769';
UPDATE affiliations SET apiTarget = '/awards/crossref/10.13039/100005202' WHERE uri = 'https://ror.org/01frxsf98';
UPDATE affiliations SET apiTarget = '/awards/crossref/10.13039/100005190' WHERE uri = 'https://ror.org/025ck6r46';
UPDATE affiliations SET apiTarget = '/awards/crossref/10.13039/100001771' WHERE uri = 'https://ror.org/02gegq725';
UPDATE affiliations SET apiTarget = '/awards/crossref/10.13039/100001545' WHERE uri = 'https://ror.org/01hx92781';
UPDATE affiliations SET apiTarget = '/awards/crossref/10.13039/100000980' WHERE uri = 'https://ror.org/04zk9fe75';
UPDATE affiliations SET apiTarget = '/awards/crossref/10.13039/100000971' WHERE uri = 'https://ror.org/00mwp5989';
UPDATE affiliations SET apiTarget = '/awards/crossref/10.13039/100000968' WHERE uri = 'https://ror.org/013kjyp64';
UPDATE affiliations SET apiTarget = '/awards/crossref/10.13039/100000936' WHERE uri = 'https://ror.org/006wxqw41';
UPDATE affiliations SET apiTarget = '/awards/crossref/10.13039/100000913' WHERE uri = 'https://ror.org/03dy4aq19';
UPDATE affiliations SET apiTarget = '/awards/crossref/10.13039/100000893' WHERE uri = 'https://ror.org/01cmst727';
UPDATE affiliations SET apiTarget = '/awards/crossref/10.13039/100000048' WHERE uri = 'https://ror.org/02e463172';
UPDATE affiliations SET apiTarget = '/awards/crossref/10.13039/100000015' WHERE uri = 'https://ror.org/01bj3aw27';