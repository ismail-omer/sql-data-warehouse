/*====================================================================================================================
    SILVER LAYER - DATA DEFINITION LANGUAGE (DDL)
    ====================================================================================================================

    PURPOSE:
        This script creates the physical table structures for the Silver layer
        of the Data Warehouse.

    SILVER LAYER RESPONSIBILITY:
        The Silver layer contains cleaned, standardized, and transformed data
        originating from the Bronze layer.

        Bronze Layer
            |
            |  Data Cleansing
            |  Standardization
            |  Transformation
            v
        Silver Layer
            |
            v
        Gold Layer / Analytical Layer

    DESIGN PRINCIPLES:
        - Store cleaned and standardized data.
        - Use appropriate SQL Server data types.
        - Keep the Silver layer structurally consistent with the source systems.
        - Add a technical audit column (dwh_create) to track record creation time.
        - Recreate tables during development to ensure a consistent schema.

    NOTE:
        These tables do not currently define PRIMARY KEY or FOREIGN KEY
        constraints because the Silver layer is primarily focused on data
        cleansing and transformation. Business rules and relationships are
        typically enforced or modeled in the Gold layer.

====================================================================================================================*/


/*====================================================================================================================
    1. CRM CUSTOMER INFORMATION
    --------------------------------------------------------------------------------------------------------------------
    SOURCE:
        CRM Customer Information

    PURPOSE:
        Stores cleaned and standardized customer master data.

    TRANSFORMATIONS APPLIED DURING LOADING:
        - Duplicate customer records are removed.
        - Customer names are trimmed.
        - Marital status is standardized.
        - Gender values are standardized.
        - Invalid or missing values are handled during the Silver load.

====================================================================================================================*/

-- Drop the existing Silver customer table if it already exists.
IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;

-- Create the Silver customer table.
CREATE TABLE silver.crm_cust_info (
    -- Unique identifier assigned to the customer.
    cst_id              INT,

    -- Business key used to identify the customer across the source system.
    cst_key             NVARCHAR(50),

    -- Customer first name.
    cst_firstname       NVARCHAR(50),

    -- Customer last name.
    cst_lastname        NVARCHAR(50),

    -- Standardized marital status.
    -- Expected values include: Single, Married, n/a.
    cst_material_status NVARCHAR(50),

    -- Standardized gender.
    -- Expected values include: Male, Female, n/a.
    cst_gndr            NVARCHAR(50),

    -- Date when the customer record was created in the source system.
    cst_create_date     DATE,

    -- Technical audit column recording when the Silver record was created.
    dwh_create          DATETIME2 DEFAULT GETDATE()
);


/*====================================================================================================================
    2. CRM PRODUCT INFORMATION
    --------------------------------------------------------------------------------------------------------------------
    SOURCE:
        CRM Product Information

    PURPOSE:
        Stores cleaned and standardized product master data.

    TRANSFORMATIONS APPLIED DURING LOADING:
        - Category IDs are standardized.
        - Product keys are transformed.
        - NULL product costs are replaced with 0.
        - Product line codes are converted into descriptive values.
        - Product dates are converted to DATE.
        - Product end dates are derived from subsequent product versions.

====================================================================================================================*/

-- Drop the existing Silver product table if it already exists.
IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;

-- Create the Silver product table.
CREATE TABLE silver.crm_prd_info (
    -- Unique identifier assigned to the product.
    prd_id          INT,

    -- Standardized product category identifier.
    cat_id          NVARCHAR(50),

    -- Business key used to identify the product.
    prd_key         NVARCHAR(50),

    -- Product name.
    prd_nm          NVARCHAR(50),

    -- Standardized product cost.
    prd_cost        INT,

    -- Descriptive product line.
    -- Examples: Mountain, Road, Touring, Other Sales.
    prd_line        NVARCHAR(50),

    -- Date when the product version became active.
    prd_start_dt    DATE,

    -- Date when the product version became inactive.
    prd_end_dt      DATE,

    -- Technical audit column recording Silver record creation time.
    dwh_create      DATETIME2 DEFAULT GETDATE()
);


/*====================================================================================================================
    3. CRM SALES INFORMATION
    --------------------------------------------------------------------------------------------------------------------
    SOURCE:
        CRM Sales Information

    PURPOSE:
        Stores cleaned and standardized transactional sales data.

    TRANSFORMATIONS APPLIED DURING LOADING:
        - Invalid dates are converted to NULL.
        - Sales amounts are validated and recalculated when necessary.
        - Invalid prices are corrected.
        - Negative prices are converted to positive values.
        - Sales and price calculations are standardized.

====================================================================================================================*/

-- Drop the existing Silver sales table if it already exists.
IF OBJECT_ID('silver.crm_sales_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_info;

-- Create the Silver sales table.
CREATE TABLE silver.crm_sales_info (
    -- Sales order number.
    sls_ord_num     NVARCHAR(50),

    -- Product business key associated with the sale.
    sls_prd_key     NVARCHAR(50),

    -- Customer identifier associated with the sale.
    sls_cust_id     INT,

    -- Date when the order was placed.
    sls_order_dt    DATE,

    -- Date when the order was shipped.
    sls_ship_dt     DATE,

    -- Expected delivery/due date.
    sls_due_dt      DATE,

    -- Total sales amount for the transaction.
    sls_sales       INT,

    -- Number of units sold.
    sls_quantity    INT,

    -- Unit selling price.
    sls_price       INT,

    -- Technical audit column recording Silver record creation time.
    dwh_create      DATETIME2 DEFAULT GETDATE()
);


/*====================================================================================================================
    4. ERP LOCATION INFORMATION
    --------------------------------------------------------------------------------------------------------------------
    SOURCE:
        ERP Location Data

    PURPOSE:
        Stores standardized customer location and country information.

    TRANSFORMATIONS APPLIED DURING LOADING:
        - Customer IDs are standardized by removing '-'.
        - Country codes are converted into country names.
        - US and USA are standardized to United States.
        - DE is standardized to Germany.
        - Missing country values are represented as 'n/a'.

====================================================================================================================*/

-- Drop the existing Silver location table if it already exists.
IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_a101;

-- Create the Silver ERP location table.
CREATE TABLE silver.erp_loc_a101 (
    -- Customer identifier from the ERP system.
    cid     NVARCHAR(50),

    -- Standardized country name.
    cntry   NVARCHAR(50),

    -- Technical audit column recording Silver record creation time.
    dwh_create DATETIME2 DEFAULT GETDATE()
);


/*====================================================================================================================
    5. ERP CUSTOMER INFORMATION
    --------------------------------------------------------------------------------------------------------------------
    SOURCE:
        ERP Customer Data

    PURPOSE:
        Stores cleaned and standardized customer demographic information
        originating from the ERP system.

    TRANSFORMATIONS APPLIED DURING LOADING:
        - 'NAS' prefixes are removed from customer IDs.
        - Future birth dates are converted to NULL.
        - Gender values are standardized.
        - Different representations of Male/Female are unified.

====================================================================================================================*/

-- Drop the existing Silver ERP customer table if it already exists.
IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;

-- Create the Silver ERP customer table.
CREATE TABLE silver.erp_cust_az12 (
    -- Customer identifier from the ERP system.
    cid     NVARCHAR(50),

    -- Customer birth date.
    bdate   DATE,

    -- Standardized customer gender.
    -- Expected values include: Male, Female, n/a.
    gen     NVARCHAR(50),

    -- Technical audit column recording Silver record creation time.
    dwh_create DATETIME2 DEFAULT GETDATE()
);


/*====================================================================================================================
    6. ERP PRODUCT CATEGORY INFORMATION
    --------------------------------------------------------------------------------------------------------------------
    SOURCE:
        ERP Product Category Data

    PURPOSE:
        Stores product category, subcategory, and maintenance information
        from the ERP system.

    TRANSFORMATIONS APPLIED DURING LOADING:
        Currently, no major transformations are applied.
        Data is transferred from Bronze to Silver while preserving
        the source values.

====================================================================================================================*/

-- Drop the existing Silver product category table if it already exists.
IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;

-- Create the Silver ERP product category table.
CREATE TABLE silver.erp_px_cat_g1v2 (
    -- Product category identifier.
    id          NVARCHAR(50),

    -- Main product category.
    cat         NVARCHAR(50),

    -- Product subcategory.
    subcat      NVARCHAR(50),

    -- Product maintenance classification.
    maintenance NVARCHAR(50),

    -- Technical audit column recording Silver record creation time.
    dwh_create  DATETIME2 DEFAULT GETDATE()
);


/*====================================================================================================================
    SILVER LAYER DDL COMPLETED
    --------------------------------------------------------------------------------------------------------------------
    The Silver layer tables have now been created with their required
    structures and technical audit columns.

    NEXT STEP:
        Execute the Silver loading procedure:

            EXEC silver.load_silver;

        This procedure extracts data from the Bronze layer, applies the
        required cleansing and transformation rules, and populates
        the Silver layer tables.

====================================================================================================================*/
