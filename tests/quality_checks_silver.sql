/*====================================================================================================================
    SILVER LAYER - DATA QUALITY CHECKS
    ====================================================================================================================

    PURPOSE:
        Validate the quality, consistency, completeness, and integrity of
        data loaded into the Silver layer.

    DATA FLOW:

        Bronze Layer
             |
             v
        silver.load_silver
             |
             v
        Silver Layer
             |
             v
        DATA QUALITY CHECKS

    QUALITY DIMENSIONS:
        1. Completeness
        2. Uniqueness
        3. Validity
        4. Consistency
        5. Standardization
        6. Referential Integrity
        7. Business Rule Validation
        8. Temporal / Date Validation

====================================================================================================================*/


/*====================================================================================================================
    1. CRM CUSTOMER DATA
    ====================================================================================================================*/


/*---------------------------------------------------------------
    CHECK 1.1
    Check for NULL customer IDs.

    cst_id should never be NULL because it is used to identify
    the customer.
----------------------------------------------------------------*/

SELECT *
FROM silver.crm_cust_info
WHERE cst_id IS NULL;


/*---------------------------------------------------------------
    CHECK 1.2
    Check for duplicate customer IDs.

    The Silver load is designed to keep only the latest record
    for each customer.
----------------------------------------------------------------*/

SELECT
    cst_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1;


/*---------------------------------------------------------------
    CHECK 1.3
    Check for duplicate customer business keys.
----------------------------------------------------------------*/

SELECT
    cst_key,
    COUNT(*) AS duplicate_count
FROM silver.crm_cust_info
GROUP BY cst_key
HAVING COUNT(*) > 1;


/*---------------------------------------------------------------
    CHECK 1.4
    Check for unwanted spaces in customer names.
----------------------------------------------------------------*/

SELECT *
FROM silver.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname)
   OR cst_lastname <> TRIM(cst_lastname);


/*---------------------------------------------------------------
    CHECK 1.5
    Check that marital status contains only standardized values.
----------------------------------------------------------------*/

SELECT DISTINCT cst_material_status
FROM silver.crm_cust_info
WHERE cst_material_status NOT IN (
    'Single',
    'Married',
    'n/a'
);


/*---------------------------------------------------------------
    CHECK 1.6
    Check that gender contains only standardized values.
----------------------------------------------------------------*/

SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info
WHERE cst_gndr NOT IN (
    'Male',
    'Female',
    'n/a'
);


/*---------------------------------------------------------------
    CHECK 1.7
    Check for NULL customer creation dates.
----------------------------------------------------------------*/

SELECT *
FROM silver.crm_cust_info
WHERE cst_create_date IS NULL;


/*---------------------------------------------------------------
    CHECK 1.8
    Check for future customer creation dates.
----------------------------------------------------------------*/

SELECT *
FROM silver.crm_cust_info
WHERE cst_create_date > CAST(GETDATE() AS DATE);


/*====================================================================================================================
    2. CRM PRODUCT DATA
    ====================================================================================================================*/


/*---------------------------------------------------------------
    CHECK 2.1
    Check for NULL product IDs.
----------------------------------------------------------------*/

SELECT *
FROM silver.crm_prd_info
WHERE prd_id IS NULL;


/*---------------------------------------------------------------
    CHECK 2.2
    Check for duplicate product IDs.
----------------------------------------------------------------*/

SELECT
    prd_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1;


/*---------------------------------------------------------------
    CHECK 2.3
    Check for duplicate product keys.
----------------------------------------------------------------*/

SELECT
    prd_key,
    COUNT(*) AS duplicate_count
FROM silver.crm_prd_info
GROUP BY prd_key
HAVING COUNT(*) > 1;


/*---------------------------------------------------------------
    CHECK 2.4
    Check for NULL product keys.
----------------------------------------------------------------*/

SELECT *
FROM silver.crm_prd_info
WHERE prd_key IS NULL
   OR TRIM(prd_key) = '';


/*---------------------------------------------------------------
    CHECK 2.5
    Check for NULL product names.
----------------------------------------------------------------*/

SELECT *
FROM silver.crm_prd_info
WHERE prd_nm IS NULL
   OR TRIM(prd_nm) = '';


/*---------------------------------------------------------------
    CHECK 2.6
    Check for invalid product costs.

    The load procedure converts NULL costs to 0.
    Negative costs should therefore not exist.
----------------------------------------------------------------*/

SELECT *
FROM silver.crm_prd_info
WHERE prd_cost < 0;


/*---------------------------------------------------------------
    CHECK 2.7
    Check that product line contains only standardized values.
----------------------------------------------------------------*/

SELECT DISTINCT prd_line
FROM silver.crm_prd_info
WHERE prd_line NOT IN (
    'Mountain',
    'Road',
    'Other Sales',
    'Touring',
    'n/a'
);


/*---------------------------------------------------------------
    CHECK 2.8
    Check for invalid product date ranges.

    End date should never be earlier than start date.
----------------------------------------------------------------*/

SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;


/*---------------------------------------------------------------
    CHECK 2.9
    Check for overlapping product validity periods.

    A product should not have overlapping active periods.
----------------------------------------------------------------*/

SELECT
    p1.prd_key,
    p1.prd_start_dt,
    p1.prd_end_dt,
    p2.prd_start_dt AS next_start_dt,
    p2.prd_end_dt AS next_end_dt
FROM silver.crm_prd_info p1
JOIN silver.crm_prd_info p2
    ON p1.prd_key = p2.prd_key
    AND p1.prd_start_dt < p2.prd_start_dt
WHERE p1.prd_end_dt >= p2.prd_start_dt;


/*====================================================================================================================
    3. CRM SALES DATA
    ====================================================================================================================*/


/*---------------------------------------------------------------
    CHECK 3.1
    Check for NULL order numbers.
----------------------------------------------------------------*/

SELECT *
FROM silver.crm_sales_info
WHERE sls_ord_num IS NULL
   OR TRIM(sls_ord_num) = '';


/*---------------------------------------------------------------
    CHECK 3.2
    Check for NULL product keys.
----------------------------------------------------------------*/

SELECT *
FROM silver.crm_sales_info
WHERE sls_prd_key IS NULL
   OR TRIM(sls_prd_key) = '';


/*---------------------------------------------------------------
    CHECK 3.3
    Check for NULL customer IDs.
----------------------------------------------------------------*/

SELECT *
FROM silver.crm_sales_info
WHERE sls_cust_id IS NULL;


/*---------------------------------------------------------------
    CHECK 3.4
    Check for invalid order dates.
----------------------------------------------------------------*/

SELECT *
FROM silver.crm_sales_info
WHERE sls_order_dt IS NULL;


/*---------------------------------------------------------------
    CHECK 3.5
    Check that shipping date is not before order date.
----------------------------------------------------------------*/

SELECT *
FROM silver.crm_sales_info
WHERE sls_ship_dt < sls_order_dt;


/*---------------------------------------------------------------
    CHECK 3.6
    Check that due date is not before order date.
----------------------------------------------------------------*/

SELECT *
FROM silver.crm_sales_info
WHERE sls_due_dt < sls_order_dt;


/*---------------------------------------------------------------
    CHECK 3.7
    Check for negative or zero quantities.
----------------------------------------------------------------*/

SELECT *
FROM silver.crm_sales_info
WHERE sls_quantity <= 0;


/*---------------------------------------------------------------
    CHECK 3.8
    Check for negative or zero sales.
----------------------------------------------------------------*/

SELECT *
FROM silver.crm_sales_info
WHERE sls_sales <= 0;


/*---------------------------------------------------------------
    CHECK 3.9
    Check for negative or zero prices.
----------------------------------------------------------------*/

SELECT *
FROM silver.crm_sales_info
WHERE sls_price <= 0;


/*---------------------------------------------------------------
    CHECK 3.10
    Check the fundamental sales calculation:

        Sales = Quantity × Price
----------------------------------------------------------------*/

SELECT
    *,
    sls_quantity * sls_price AS calculated_sales
FROM silver.crm_sales_info
WHERE sls_sales <> sls_quantity * sls_price;


/*---------------------------------------------------------------
    CHECK 3.11
    Check for duplicate sales transactions.

    Adjust the columns if your business defines a different
    transaction grain.
----------------------------------------------------------------*/

SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_sales_info
GROUP BY
    sls_ord_num,
    sls_prd_key,
    sls_cust_id
HAVING COUNT(*) > 1;


/*====================================================================================================================
    4. ERP CUSTOMER DATA
    ====================================================================================================================*/


/*---------------------------------------------------------------
    CHECK 4.1
    Check for NULL customer IDs.
----------------------------------------------------------------*/

SELECT *
FROM silver.erp_cust_az12
WHERE cid IS NULL
   OR TRIM(cid) = '';


/*---------------------------------------------------------------
    CHECK 4.2
    Check that NAS prefixes were removed.
----------------------------------------------------------------*/

SELECT *
FROM silver.erp_cust_az12
WHERE cid LIKE 'NAS%';


/*---------------------------------------------------------------
    CHECK 4.3
    Check for future birth dates.
----------------------------------------------------------------*/

SELECT *
FROM silver.erp_cust_az12
WHERE bdate > CAST(GETDATE() AS DATE);


/*---------------------------------------------------------------
    CHECK 4.4
    Check for unreasonable birth dates.

    This is a business-rule check and can be adjusted depending
    on the expected customer population.
----------------------------------------------------------------*/

SELECT *
FROM silver.erp_cust_az12
WHERE bdate < '1900-01-01';


/*---------------------------------------------------------------
    CHECK 4.5
    Check that gender values are standardized.
----------------------------------------------------------------*/

SELECT DISTINCT gen
FROM silver.erp_cust_az12
WHERE gen NOT IN (
    'Male',
    'Female',
    'n/a'
);


/*---------------------------------------------------------------
    CHECK 4.6
    Check for duplicate ERP customer IDs.
----------------------------------------------------------------*/

SELECT
    cid,
    COUNT(*) AS duplicate_count
FROM silver.erp_cust_az12
GROUP BY cid
HAVING COUNT(*) > 1;


/*====================================================================================================================
    5. ERP LOCATION DATA
    ====================================================================================================================*/


/*---------------------------------------------------------------
    CHECK 5.1
    Check for NULL customer IDs.
----------------------------------------------------------------*/

SELECT *
FROM silver.erp_loc_a101
WHERE cid IS NULL
   OR TRIM(cid) = '';


/*---------------------------------------------------------------
    CHECK 5.2
    Check whether customer IDs still contain '-'.

    The Silver load should remove these characters.
----------------------------------------------------------------*/

SELECT *
FROM silver.erp_loc_a101
WHERE cid LIKE '%-%';


/*---------------------------------------------------------------
    CHECK 5.3
    Check for missing country values.
----------------------------------------------------------------*/

SELECT *
FROM silver.erp_loc_a101
WHERE cntry IS NULL
   OR TRIM(cntry) = '';


/*---------------------------------------------------------------
    CHECK 5.4
    Check that country codes have been standardized.
----------------------------------------------------------------*/

SELECT *
FROM silver.erp_loc_a101
WHERE cntry IN ('DE', 'US', 'USA');


/*====================================================================================================================
    6. ERP PRODUCT CATEGORY DATA
    ====================================================================================================================*/


/*---------------------------------------------------------------
    CHECK 6.1
    Check for NULL category IDs.
----------------------------------------------------------------*/

SELECT *
FROM silver.erp_px_cat_g1v2
WHERE id IS NULL
   OR TRIM(id) = '';


/*---------------------------------------------------------------
    CHECK 6.2
    Check for NULL categories.
----------------------------------------------------------------*/

SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat IS NULL
   OR TRIM(cat) = '';


/*---------------------------------------------------------------
    CHECK 6.3
    Check for NULL subcategories.
----------------------------------------------------------------*/

SELECT *
FROM silver.erp_px_cat_g1v2
WHERE subcat IS NULL
   OR TRIM(subcat) = '';


/*---------------------------------------------------------------
    CHECK 6.4
    Check for duplicate category IDs.
----------------------------------------------------------------*/

SELECT
    id,
    COUNT(*) AS duplicate_count
FROM silver.erp_px_cat_g1v2
GROUP BY id
HAVING COUNT(*) > 1;


/*====================================================================================================================
    7. CROSS-TABLE REFERENTIAL INTEGRITY
    ====================================================================================================================*/


/*---------------------------------------------------------------
    CHECK 7.1
    Sales records with a product key that does not exist
    in the Silver product table.
----------------------------------------------------------------*/

SELECT
    s.sls_prd_key,
    COUNT(*) AS invalid_records
FROM silver.crm_sales_info s
LEFT JOIN silver.crm_prd_info p
    ON s.sls_prd_key = p.prd_key
WHERE p.prd_key IS NULL
GROUP BY s.sls_prd_key;


/*---------------------------------------------------------------
    CHECK 7.2
    Sales records with a customer ID that does not exist
    in the Silver CRM customer table.
----------------------------------------------------------------*/

SELECT
    s.sls_cust_id,
    COUNT(*) AS invalid_records
FROM silver.crm_sales_info s
LEFT JOIN silver.crm_cust_info c
    ON s.sls_cust_id = c.cst_id
WHERE c.cst_id IS NULL
GROUP BY s.sls_cust_id;


/*---------------------------------------------------------------
    CHECK 7.3
    ERP customer records without matching location records.
----------------------------------------------------------------*/

SELECT
    c.cid
FROM silver.erp_cust_az12 c
LEFT JOIN silver.erp_loc_a101 l
    ON c.cid = l.cid
WHERE l.cid IS NULL;


/*====================================================================================================================
    8. TECHNICAL AUDIT COLUMN CHECKS
    ====================================================================================================================*/


/*---------------------------------------------------------------
    CHECK 8.1
    Verify that dwh_create is populated.
----------------------------------------------------------------*/

SELECT 'crm_cust_info' AS table_name, COUNT(*) AS null_dwh_create
FROM silver.crm_cust_info
WHERE dwh_create IS NULL

UNION ALL

SELECT 'crm_prd_info', COUNT(*)
FROM silver.crm_prd_info
WHERE dwh_create IS NULL

UNION ALL

SELECT 'crm_sales_info', COUNT(*)
FROM silver.crm_sales_info
WHERE dwh_create IS NULL

UNION ALL

SELECT 'erp_cust_az12', COUNT(*)
FROM silver.erp_cust_az12
WHERE dwh_create IS NULL

UNION ALL

SELECT 'erp_loc_a101', COUNT(*)
FROM silver.erp_loc_a101
WHERE dwh_create IS NULL

UNION ALL

SELECT 'erp_px_cat_g1v2', COUNT(*)
FROM silver.erp_px_cat_g1v2
WHERE dwh_create IS NULL;


/*====================================================================================================================
    9. ROW COUNT VALIDATION
    ====================================================================================================================

    Compare Bronze and Silver row counts.

    NOTE:
        The counts do not necessarily need to be identical because
        the Silver layer intentionally removes duplicates and NULL
        customer IDs in some tables.
====================================================================================================================*/

SELECT
    'crm_cust_info' AS table_name,
    (SELECT COUNT(*) FROM bronze.crm_cust_info) AS bronze_count,
    (SELECT COUNT(*) FROM silver.crm_cust_info) AS silver_count

UNION ALL

SELECT
    'crm_prd_info',
    (SELECT COUNT(*) FROM bronze.crm_prd_info),
    (SELECT COUNT(*) FROM silver.crm_prd_info)

UNION ALL

SELECT
    'crm_sales_info',
    (SELECT COUNT(*) FROM bronze.crm_sales_info),
    (SELECT COUNT(*) FROM silver.crm_sales_info)

UNION ALL

SELECT
    'erp_cust_az12',
    (SELECT COUNT(*) FROM bronze.erp_cust_az12),
    (SELECT COUNT(*) FROM silver.erp_cust_az12)

UNION ALL

SELECT
    'erp_loc_a101',
    (SELECT COUNT(*) FROM bronze.erp_loc_a101),
    (SELECT COUNT(*) FROM silver.erp_loc_a101)

UNION ALL

SELECT
    'erp_px_cat_g1v2',
    (SELECT COUNT(*) FROM bronze.erp_px_cat_g1v2),
    (SELECT COUNT(*) FROM silver.erp_px_cat_g1v2);


/*====================================================================================================================
    10. STANDARDIZATION SUMMARY
    ====================================================================================================================*/


/*---------------------------------------------------------------
    Customer gender distribution
----------------------------------------------------------------*/

SELECT
    cst_gndr,
    COUNT(*) AS record_count
FROM silver.crm_cust_info
GROUP BY cst_gndr
ORDER BY record_count DESC;


/*---------------------------------------------------------------
    Customer marital status distribution
----------------------------------------------------------------*/

SELECT
    cst_material_status,
    COUNT(*) AS record_count
FROM silver.crm_cust_info
GROUP BY cst_material_status
ORDER BY record_count DESC;


/*---------------------------------------------------------------
    Product line distribution
----------------------------------------------------------------*/

SELECT
    prd_line,
    COUNT(*) AS record_count
FROM silver.crm_prd_info
GROUP BY prd_line
ORDER BY record_count DESC;


/*---------------------------------------------------------------
    ERP customer gender distribution
----------------------------------------------------------------*/

SELECT
    gen,
    COUNT(*) AS record_count
FROM silver.erp_cust_az12
GROUP BY gen
ORDER BY record_count DESC;


/*====================================================================================================================
    11. CORRECTIVE UPDATE STATEMENTS
    ====================================================================================================================

    These UPDATE statements can be used if bad values are found
    after the Silver load.

    IMPORTANT:
        These corrections should preferably be incorporated into
        silver.load_silver so that every execution produces clean
        data automatically.
====================================================================================================================*/


/*---------------------------------------------------------------
    UPDATE 11.1
    Standardize CRM customer gender.
----------------------------------------------------------------*/

UPDATE silver.crm_cust_info
SET cst_gndr =
    CASE
        WHEN UPPER(TRIM(cst_gndr)) IN ('F', 'FEMALE')
            THEN 'Female'
        WHEN UPPER(TRIM(cst_gndr)) IN ('M', 'MALE')
            THEN 'Male'
        ELSE 'n/a'
    END;


/*---------------------------------------------------------------
    UPDATE 11.2
    Standardize CRM marital status.
----------------------------------------------------------------*/

UPDATE silver.crm_cust_info
SET cst_material_status =
    CASE
        WHEN UPPER(TRIM(cst_material_status)) IN ('S', 'SINGLE')
            THEN 'Single'
        WHEN UPPER(TRIM(cst_material_status)) IN ('M', 'MARRIED')
            THEN 'Married'
        ELSE 'n/a'
    END;


/*---------------------------------------------------------------
    UPDATE 11.3
    Standardize ERP customer gender.
----------------------------------------------------------------*/

UPDATE silver.erp_cust_az12
SET gen =
    CASE
        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE')
            THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')
            THEN 'Male'
        ELSE 'n/a'
    END;


/*---------------------------------------------------------------
    UPDATE 11.4
    Remove NAS prefix from ERP customer IDs.
----------------------------------------------------------------*/

UPDATE silver.erp_cust_az12
SET cid = SUBSTRING(cid, 4, LEN(cid))
WHERE cid LIKE 'NAS%';


/*---------------------------------------------------------------
    UPDATE 11.5
    Remove '-' from ERP location customer IDs.
----------------------------------------------------------------*/

UPDATE silver.erp_loc_a101
SET cid = REPLACE(cid, '-', '')
WHERE cid LIKE '%-%';


/*---------------------------------------------------------------
    UPDATE 11.6
    Standardize ERP country values.
----------------------------------------------------------------*/

UPDATE silver.erp_loc_a101
SET cntry =
    CASE
        WHEN TRIM(cntry) = 'DE'
            THEN 'Germany'

        WHEN TRIM(cntry) IN ('US', 'USA')
            THEN 'United States'

        WHEN cntry IS NULL
             OR TRIM(cntry) = ''
            THEN 'n/a'

        ELSE TRIM(cntry)
    END;


/*---------------------------------------------------------------
    UPDATE 11.7
    Remove leading/trailing spaces from customer names.
----------------------------------------------------------------*/

UPDATE silver.crm_cust_info
SET
    cst_firstname = TRIM(cst_firstname),
    cst_lastname  = TRIM(cst_lastname);


/*---------------------------------------------------------------
    UPDATE 11.8
    Replace future ERP birth dates with NULL.
----------------------------------------------------------------*/

UPDATE silver.erp_cust_az12
SET bdate = NULL
WHERE bdate > CAST(GETDATE() AS DATE);


/*====================================================================================================================
    12. FINAL QUALITY SUMMARY
    ====================================================================================================================

    This query provides a simple overview of the number of records
    currently present in each Silver table.
====================================================================================================================*/

SELECT
    'silver.crm_cust_info' AS table_name,
    COUNT(*) AS record_count
FROM silver.crm_cust_info

UNION ALL

SELECT
    'silver.crm_prd_info',
    COUNT(*)
FROM silver.crm_prd_info

UNION ALL

SELECT
    'silver.crm_sales_info',
    COUNT(*)
FROM silver.crm_sales_info

UNION ALL

SELECT
    'silver.erp_cust_az12',
    COUNT(*)
FROM silver.erp_cust_az12

UNION ALL

SELECT
    'silver.erp_loc_a101',
    COUNT(*)
FROM silver.erp_loc_a101

UNION ALL

SELECT
    'silver.erp_px_cat_g1v2',
    COUNT(*)
FROM silver.erp_px_cat_g1v2;


/*====================================================================================================================
    END OF SILVER LAYER DATA QUALITY CHECKS
====================================================================================================================*/
