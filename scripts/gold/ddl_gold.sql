 /*====================================================================================================================
    GGOLD LAYER - DIMENSION & FACT VIEWS
    ====================================================================================================================

    SCRIPT PURPOSE:
        This script creates the analytical views for the Gold layer of the
        Data Warehouse.

        The Gold layer represents the final business-ready data model,
        structured according to a STAR SCHEMA consisting of:

            - Dimension tables
            - Fact tables

        These views consume cleaned and standardized data from the Silver
        layer and transform it into an enriched, analytics-ready structure.

    DATA FLOW:

        SILVER LAYER
            |
            |-- Customer Data
            |-- Product Data
            |-- Sales Data
            |-- ERP Customer Data
            |-- ERP Location Data
            |-- Product Category Data
            |
            v
        GOLD LAYER
            |
            |-- gold.dim_customers
            |-- gold.dim_products
            |-- gold.fact_sales
            |
            v
        ANALYTICS / REPORTING / BI

    GOLD LAYER OBJECTS:
        1. gold.dim_customers
           Customer dimension containing enriched customer attributes.

        2. gold.dim_products
           Product dimension containing current product information and
           enriched category/subcategory attributes.

        3. gold.fact_sales
           Sales fact view containing transactional measures linked to
           customer and product dimensions.

    DESIGN PRINCIPLES:
        - Provide business-friendly column names.
        - Integrate related Silver-layer entities.
        - Generate surrogate keys for dimensions.
        - Keep the fact table at the sales transaction grain.
        - Expose only current product records in the product dimension.
        - Prepare the data for BI and analytical workloads.

    USAGE:
        These views can be queried directly by reporting tools, dashboards,
        analytical queries, and downstream data consumers.

====================================================================================================================*/


/*====================================================================================================================
    1. CUSTOMER DIMENSION
    ====================================================================================================================

    VIEW:
        gold.dim_customers

    PURPOSE:
        Creates the Customer Dimension used by the analytical star schema.

        The view combines customer information from:
            - CRM customer data
            - ERP customer demographic data
            - ERP customer location data

    SOURCE TABLES:
        silver.crm_cust_info
        silver.erp_cust_az12
        silver.erp_loc_a101

    KEY DESIGN:
        customer_key:
            A surrogate key generated using ROW_NUMBER().

        customer_id:
            The original CRM customer identifier.

        customer_number:
            The business/customer key used for integration across systems.

    DATA INTEGRATION:
        CRM is treated as the master source for gender when a valid CRM
        gender value exists.

        If CRM gender is 'n/a', the ERP gender is used as a fallback.

====================================================================================================================*/

CREATE VIEW gold.dim_customers AS

SELECT
    /*
        Generate a surrogate key for the customer dimension.

        ROW_NUMBER() creates a sequential analytical key that is independent
        of the source-system customer ID.
    */
    ROW_NUMBER() OVER (
        ORDER BY cst_id
    ) AS customer_key,

    -- Original CRM customer identifier.
    ci.cst_id AS customer_id,

    -- Business/customer number used for integration.
    ci.cst_key AS customer_number,

    -- Customer first name.
    ci.cst_firstname AS first_name,

    -- Customer last name.
    ci.cst_lastname AS last_name,

    -- Customer country obtained from the ERP location system.
    la.cntry AS country,

    -- Standardized marital status from CRM.
    ci.cst_material_status AS material_status,

    /*
        Determine the final customer gender.

        CRM is considered the master source for gender information.

        If CRM contains a valid gender:
            Use CRM gender.

        If CRM contains 'n/a':
            Fall back to the ERP gender.

        If neither system provides a valid value:
            Return 'n/a'.
    */
    CASE
        WHEN ci.cst_gndr != 'n/a'
            THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender,

    -- Customer birth date obtained from the ERP customer system.
    ca.bdate AS birth_date,

    -- Original CRM customer creation date.
    ci.cst_create_date

FROM silver.crm_cust_info ci

/*
    Enrich CRM customer data with ERP customer demographic information.

    The customer business key is used to connect the two systems.
*/
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid

/*
    Enrich customer data with country/location information.
*/
LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;


/*====================================================================================================================
    2. PRODUCT DIMENSION
    ====================================================================================================================

    VIEW:
        gold.dim_products

    PURPOSE:
        Creates the Product Dimension used by the analytical star schema.

        The view combines:
            - CRM product information
            - ERP product category information

    SOURCE TABLES:
        silver.crm_prd_info
        silver.erp_px_cat_g1v2

    KEY DESIGN:
        product_key:
            Surrogate key generated using ROW_NUMBER().

        product_number:
            Business key used to connect products with sales transactions.

    HISTORICAL DATA:
        Products may have multiple records representing different versions
        of the same product.

        Only the currently active product version is included in the Gold
        dimension by filtering:

            prd_end_dt IS NULL

====================================================================================================================*/

CREATE VIEW gold.dim_products AS

SELECT
    /*
        Generate a surrogate key for the product dimension.

        The ordering by start date and product key provides a deterministic
        sequence for the generated product keys.
    */
    ROW_NUMBER() OVER (
        ORDER BY pn.prd_start_dt, pn.prd_key
    ) AS product_key,

    -- Original product identifier.
    pn.prd_id AS product_id,

    -- Business/product number used to connect with sales transactions.
    pn.prd_key AS product_number,

    -- Product name.
    pn.prd_nm AS product_name,

    -- Product category identifier.
    pn.cat_id AS category_id,

    -- Product category description from ERP.
    pc.cat AS category,

    -- Product subcategory description from ERP.
    pc.subcat AS subcategory,

    -- Product maintenance classification.
    pc.maintenance,

    -- Product cost.
    pn.prd_cost AS cost,

    -- Standardized product line.
    pn.prd_line AS product_line,

    -- Date from which the current product version is active.
    pn.prd_start_dt AS start_date

FROM silver.crm_prd_info pn

/*
    Enrich product information with category and subcategory details
    from the ERP product category table.
*/
LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id

/*
    Keep only the currently active product version.

    Historical product versions are excluded from the Gold dimension.
*/
WHERE pn.prd_end_dt IS NULL;


/*====================================================================================================================
    3. SALES FACT
    ====================================================================================================================

    VIEW:
        gold.fact_sales

    PURPOSE:
        Creates the central Sales Fact used by the analytical star schema.

        The fact view combines transactional sales data with the surrogate
        keys from the Customer and Product dimensions.

    SOURCE:
        silver.crm_sales_info

    DIMENSIONS:
        gold.dim_products
        gold.dim_customers

    FACT GRAIN:
        One row represents a sales transaction line identified by the
        combination of order number, product, and customer.

    MEASURES:
        - sales_amount
        - quantity
        - price

    DATE ATTRIBUTES:
        - order_date
        - shipping_date
        - due_date

====================================================================================================================*/

CREATE VIEW gold.fact_sales AS

SELECT

    -- Sales order number from the CRM transaction system.
    si.sls_ord_num AS order_number,

    /*
        Product surrogate key.

        The business product key from the sales transaction is mapped
        to the surrogate key in the Product Dimension.
    */
    pr.product_key,

    /*
        Customer surrogate key.

        The source-system customer ID is mapped to the surrogate key
        in the Customer Dimension.
    */
    cu.customer_key,

    -- Date when the sales order was placed.
    si.sls_order_dt AS order_date,

    -- Date when the order was shipped.
    si.sls_ship_dt AS shipping_date,

    -- Expected/due date of the order.
    si.sls_due_dt AS due_date,

    -- Total sales amount for the transaction.
    si.sls_sales AS sales_amount,

    -- Number of units sold.
    si.sls_quantity AS quantity,

    -- Selling price per unit.
    si.sls_price AS price

FROM silver.crm_sales_info si

/*
    Connect sales transactions to the Product Dimension.

    The business product number from the sales table is matched against
    the product number in the Gold Product Dimension.
*/
LEFT JOIN gold.dim_products pr
    ON si.sls_prd_key = pr.product_number

/*
    Connect sales transactions to the Customer Dimension.

    The source customer ID is matched against the Customer Dimension.
*/
LEFT JOIN gold.dim_customers cu
    ON si.sls_cust_id = cu.customer_id;


/*====================================================================================================================
    GOLD LAYER CREATION COMPLETED
    ====================================================================================================================

    CREATED VIEWS:
        gold.dim_customers
        gold.dim_products
        gold.fact_sales

    STAR SCHEMA:

                         gold.dim_customers
                               |
                               |
                               v
                         gold.fact_sales
                               ^
                               |
                               |
                         gold.dim_products

    The Gold layer is now ready to serve as the business-facing analytical
    layer for reporting, dashboards, BI tools, and analytical queries.

====================================================================================================================*/
