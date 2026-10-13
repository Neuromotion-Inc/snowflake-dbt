-- =============================================================================
-- SETUP.sql: one-time bootstrap for DCM, run ONCE PER SNOWFLAKE ACCOUNT
--
-- DCM can't create the project objects it deploys into, so an admin runs this
-- manually as ACCOUNTADMIN in each account. Everything else is defined by the
-- DCM project and deployed through it.
--
-- Run it in each account:
--   MIGHTIER_STAGING  dev/test sandbox, mocked data  -> project: *_DEV
--   MIGHTIER_HIPAA    production account             -> projects: *_PREPROD, *_PROD
--
-- Safe to re-run: it never drops or replaces anything. (CREATE OR REPLACE on a
-- DCM project would delete its deployment history.)
-- =============================================================================

USE ROLE ACCOUNTADMIN;

-- Holds the DCM project objects, kept apart from the databases they manage
CREATE DATABASE IF NOT EXISTS dcm_db;
CREATE SCHEMA IF NOT EXISTS dcm_db.dcm_projects;

-- Role that owns the DCM projects. PLAN/DEPLOY require OWNERSHIP on the project,
-- and objects are deployed with this role's privileges.
CREATE ROLE IF NOT EXISTS DCM_DEPLOYER;
-- Standard hierarchy: SYSADMIN (and thus ACCOUNTADMIN) inherits DCM_DEPLOYER
GRANT ROLE DCM_DEPLOYER TO ROLE SYSADMIN;

GRANT USAGE ON DATABASE dcm_db TO ROLE DCM_DEPLOYER;
GRANT USAGE ON SCHEMA dcm_db.dcm_projects TO ROLE DCM_DEPLOYER;
GRANT CREATE DCM PROJECT ON SCHEMA dcm_db.dcm_projects TO ROLE DCM_DEPLOYER;
-- The Snowflake CLI uploads local definition files to a temporary stage in this schema
GRANT CREATE STAGE ON SCHEMA dcm_db.dcm_projects TO ROLE DCM_DEPLOYER;

-- Create the project as DCM_DEPLOYER so it owns them
USE ROLE DCM_DEPLOYER;
CREATE DCM PROJECT IF NOT EXISTS dcm_db.dcm_projects.EDI_FILE_INGESTION
    COMMENT = 'EDI file ingestion: production';
