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

-- Role that owns the DCM projects. PLAN/DEPLOY require OWNERSHIP on the project,
-- and objects are deployed with this role's privileges.
CREATE ROLE IF NOT EXISTS dcm_developer;
SET user_name = (SELECT CURRENT_USER());
GRANT ROLE dcm_developer TO USER IDENTIFIER($user_name);

GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE dcm_developer;
GRANT CREATE ROLE ON ACCOUNT TO ROLE dcm_developer;
GRANT CREATE DATABASE ON ACCOUNT TO ROLE dcm_developer;
GRANT EXECUTE MANAGED TASK ON ACCOUNT TO ROLE dcm_developer;
GRANT EXECUTE TASK ON ACCOUNT TO ROLE dcm_developer;
GRANT MANAGE GRANTS ON ACCOUNT TO ROLE dcm_developer;

GRANT APPLICATION ROLE SNOWFLAKE.DATA_QUALITY_MONITORING_VIEWER TO ROLE dcm_developer;
GRANT APPLICATION ROLE SNOWFLAKE.DATA_QUALITY_MONITORING_ADMIN TO ROLE dcm_developer;
GRANT DATABASE ROLE SNOWFLAKE.DATA_METRIC_USER TO ROLE dcm_developer;
GRANT EXECUTE DATA METRIC FUNCTION ON ACCOUNT TO ROLE dcm_developer;

-- 
-- work done as dcm_developer
-- 
USE ROLE dcm_developer;

CREATE DATABASE IF NOT EXISTS dcm_db;
CREATE SCHEMA IF NOT EXISTS dcm_db.projects;

CREATE OR REPLACE DCM PROJECT dcm_db.projects.edi_file_ingestion
    COMMENT = 'Availity EDI file ingestion';
