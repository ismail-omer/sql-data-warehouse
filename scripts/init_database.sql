/*====================================================================
    DATA WAREHOUSE DATABASE INITIALIZATION
    -------------------------------------------------------------------
    Purpose:
        - Remove the existing DataWarehouse database if it exists.
        - Create a fresh DataWarehouse database.
        - Create the Bronze, Silver, and Gold schemas used in the
          Medallion Architecture.

    Architecture:
        Bronze  -> Raw / Source Data
        Silver  -> Cleaned / Transformed Data
        Gold    -> Business-Ready / Analytics Data

    Note:
        This script is intended for development and testing environments.
        Dropping the database will permanently remove all existing data.
====================================================================*/


/*====================================================================
    STEP 1: CHECK FOR EXISTING DATABASE
    -------------------------------------------------------------------
    If the DataWarehouse database already exists, force all active
    connections to close and remove the database.

    SINGLE_USER:
        Restricts the database to a single connection.

    WITH ROLLBACK IMMEDIATE:
        Immediately terminates active transactions and rolls them back,
        allowing the database to be dropped without waiting for users
        or processes to disconnect.
====================================================================*/

USE master;
GO

IF EXISTS (
    SELECT 1
    FROM sys.databases
    WHERE name = 'DataWarehouse'
)
BEGIN
    -- Force the database into single-user mode and terminate
    -- all existing connections before dropping it.
    ALTER DATABASE DataWarehouse
        SET SINGLE_USER
        WITH ROLLBACK IMMEDIATE;

    -- Remove the existing database and all of its objects/data.
    DROP DATABASE DataWarehouse;
END;
GO


/*====================================================================
    STEP 2: CREATE DATA WAREHOUSE DATABASE
    -------------------------------------------------------------------
    Creates a new, clean database that will serve as the central
    repository for the data warehouse.
====================================================================*/

CREATE DATABASE DataWarehouse;
GO


/*====================================================================
    STEP 3: SWITCH TO THE DATA WAREHOUSE
    -------------------------------------------------------------------
    Sets DataWarehouse as the active database so that subsequent
    schemas and database objects are created inside it.
====================================================================*/

USE DataWarehouse;
GO


/*====================================================================
    STEP 4: CREATE MEDALLION ARCHITECTURE SCHEMAS
    -------------------------------------------------------------------
    The data warehouse follows a three-layer Medallion Architecture:

    BRONZE:
        Stores raw data as received from source systems.
        Minimal or no transformation is applied.

    SILVER:
        Contains cleaned, validated, standardized, and transformed
        data prepared for analytical processing.

    GOLD:
        Contains business-ready data such as dimensional models,
        fact tables, aggregations, and data marts used for reporting
        and analytics.
====================================================================*/


-- Bronze Layer: Raw source data
CREATE SCHEMA bronze;
GO

-- Silver Layer: Cleaned and transformed data
CREATE SCHEMA silver;
GO

-- Gold Layer: Business-ready analytical data
CREATE SCHEMA gold;
GO
