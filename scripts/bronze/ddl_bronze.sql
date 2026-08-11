/*====================================================================
    BRONZE LAYER - TABLE CREATION SCRIPT
    -------------------------------------------------------------------
    Purpose:
        Creates the staging tables used by the Bronze layer of the
        Data Warehouse.

    Bronze Layer:
        The Bronze layer is the raw data landing zone. Data is loaded
        directly from the source systems with minimal transformation.

    Design Approach:
        - Existing tables are dropped before recreation.
        - Source column names are preserved where possible.
        - Data types are selected based on the expected source data.
        - Separate tables are created for CRM and ERP source systems.

    Source Systems:
        CRM - Customer Relationship Management
        ERP - Enterprise Resource Planning

    Tables Created:
        CRM:
            1. bronze.crm_cust_info
            2. bronze.crm_prd_info
            3. bronze.crm_sales_info

        ERP:
            4. bronze.erp_loc_a101
            5. bronze.erp_cust_az12
            6. bronze.erp_px_cat_g1v2

    Important:
        This script is intended for development/initialization.
        Dropping an existing table permanently removes its data.
====================================================================*/


/*====================================================================
    CRM CUSTOMER INFORMATION
    -------------------------------------------------------------------
    Stores raw customer information received from the CRM source.
    
    Key attributes include:
        - Customer ID and business key
        - Customer name
        - Marital status
        - Gender
        - Customer creation date
====================================================================*/

-- Drop the table if it already exists to allow a clean recreation.
IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;

-- Create the raw CRM customer staging table.
CREATE TABLE bronze.crm_cust_info (
    cst_id              INT,
    cst_key             NVARCHAR(50),
    cst_firstname       NVARCHAR(50),
    cst_lastname        NVARCHAR(50),
    cst_material_status  NVARCHAR(50),
    cst_gndr            NVARCHAR(50),
    cst_create_date     DATE
);


/*====================================================================
    CRM PRODUCT INFORMATION
    -------------------------------------------------------------------
    Stores raw product information received from the CRM source.

    Includes:
        - Product identifiers
        - Product name
        - Product cost
        - Product line/category
        - Product validity period
====================================================================*/

-- Drop the existing table before recreating it.
IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;

-- Create the raw CRM product staging table.
CREATE TABLE bronze.crm_prd_info (
    prd_id          INT,
    prd_key         NVARCHAR(50),
    prd_nm          NVARCHAR(50),
    prd_cost        INT,
    prd_line        NVARCHAR(50),
    prd_start_dt    DATETIME,
    prd_end_dt      DATETIME
);


/*====================================================================
    CRM SALES INFORMATION
    -------------------------------------------------------------------
    Stores raw sales transaction information received from the CRM
    source system.

    Includes:
        - Sales order number
        - Product and customer references
        - Order, shipping, and due dates
        - Sales amount
        - Quantity
        - Product price
====================================================================*/

-- Drop the existing table before recreating it.
IF OBJECT_ID('bronze.crm_sales_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_info;

-- Create the raw CRM sales staging table.
CREATE TABLE bronze.crm_sales_info (
    sls_ord_num     NVARCHAR(50),
    sls_prd_key     NVARCHAR(50),
    sls_cust_id     INT,
    sls_order_dt    INT,
    sls_ship_dt     INT,
    sls_due_dt      INT,
    sls_sales       INT,
    sls_quantity    INT,
    sls_price       INT
);


/*====================================================================
    ERP LOCATION INFORMATION
    -------------------------------------------------------------------
    Stores raw customer-to-country/location information received from
    the ERP source system.

    The customer identifier is stored as a string because ERP source
    identifiers may contain prefixes or other non-numeric characters.
====================================================================*/

-- Drop the existing table before recreating it.
IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;

-- Create the raw ERP location staging table.
CREATE TABLE bronze.erp_loc_a101 (
    cid     NVARCHAR(50),
    cntry   NVARCHAR(50)
);


/*====================================================================
    ERP CUSTOMER INFORMATION
    -------------------------------------------------------------------
    Stores additional customer information received from the ERP
    source system.

    Includes:
        - Customer identifier
        - Birth date
        - Gender
====================================================================*/

-- Drop the existing table before recreating it.
IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;

-- Create the raw ERP customer staging table.
CREATE TABLE bronze.erp_cust_az12 (
    cid     NVARCHAR(50),
    bdate   DATE,
    gen     NVARCHAR(50)
);


/*====================================================================
    ERP PRODUCT CATEGORY INFORMATION
    -------------------------------------------------------------------
    Stores raw product category and maintenance information received
    from the ERP source system.

    Includes:
        - Product identifier
        - Category
        - Subcategory
        - Maintenance classification
====================================================================*/

-- Drop the existing table before recreating it.
IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;

-- Create the raw ERP product category staging table.
CREATE TABLE bronze.erp_px_cat_g1v2 (
    id          NVARCHAR(50),
    cat         NVARCHAR(50),
    subcat      NVARCHAR(50),
    maintenance NVARCHAR(50)
);
