-- Step 1: Use an admin role
USE ROLE ACCOUNTADMIN;

-- Step 2: Create the `transform` role and assign it to ACCOUNTADMIN
CREATE ROLE IF NOT EXISTS TRANSFORM;
GRANT ROLE TRANSFORM TO ROLE ACCOUNTADMIN;

-- Step 3: Create a default warehouse
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH;
GRANT OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE TRANSFORM;

-- Step 4: Create the `dbt` user and assign to the transform role
CREATE USER IF NOT EXISTS dbt_user
  PASSWORD='**********************'
  LOGIN_NAME='**********************'
  MUST_CHANGE_PASSWORD=FALSE
  DEFAULT_WAREHOUSE='COMPUTE_WH'
  DEFAULT_ROLE=TRANSFORM
  DEFAULT_NAMESPACE='analytics_db.landing'
  COMMENT='DBT user used for data transformation';

ALTER USER dbt_user SET TYPE = LEGACY_SERVICE;
GRANT ROLE TRANSFORM TO USER dbt_user;

-- Step 5: Create a database and schema for the Analytics project
CREATE DATABASE IF NOT EXISTS analytics_db;
CREATE SCHEMA IF NOT EXISTS analytics_db.landing;

-- Step 6: Grant permissions to the `transform` role
GRANT ALL ON WAREHOUSE COMPUTE_WH TO ROLE transform;
GRANT ALL ON DATABASE analytics_db TO ROLE transform;
GRANT ALL ON ALL SCHEMAS IN DATABASE analytics_db TO ROLE transform;
GRANT ALL ON FUTURE SCHEMAS IN DATABASE analytics_db TO ROLE transform;
GRANT ALL ON ALL TABLES IN SCHEMA analytics_db.landing TO ROLE transform;
GRANT ALL ON FUTURE TABLES IN SCHEMA analytics_db.landing TO ROLE transform;

-- Set defaults
USE WAREHOUSE COMPUTE_WH;
USE DATABASE analytics_db;
USE SCHEMA landing;