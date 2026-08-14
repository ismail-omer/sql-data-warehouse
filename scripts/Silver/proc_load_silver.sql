/*====================================================================================================================
    STORED PROCEDURE: silver.load_silver
    ====================================================================================================================

    PURPOSE:
        Loads and transforms data from the Bronze layer into the Silver layer.

        The Silver layer contains cleaned, standardized, and transformed data
        that is ready for downstream analytical processing.

    DATA FLOW:
        Bronze Layer
            |
            |-- bronze.crm_cust_info
            |-- bronze.crm_prd_info
            |-- bronze.crm_sales_info
            |-- bronze.erp_cust_az12
            |-- bronze.erp_loc_a101
            |-- bronze.erp_px_cat_g1v2
            |
            v
        Silver Layer
            |
            |-- silver.crm_cust_info
            |-- silver.crm_prd_info
            |-- silver.crm_sales_info
            |-- silver.erp_cust_az12
            |-- silver.erp_loc_a101
            |-- silver.erp_px_cat_g1v2

    PROCESS:
        1. Truncate existing Silver tables.
        2. Read raw data from the Bronze layer.
        3. Apply data cleansing and standardization rules.
        4. Insert the transformed data into the Silver layer.
        5. Capture and report any errors using TRY/CATCH.

    ERROR HANDLING:
        If any statement fails during execution, the CATCH block:
            - Prints a descriptive error message.
            - Displays the error number.
            - Displays the error message.
            - Displays the line where the error occurred.
            - Re-raises the original error using THROW so that external
              monitoring systems or SQL Agent jobs can detect the failure.

====================================================================================================================*/

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN

    BEGIN TRY

        /*================================================================
            1. CRM CUSTOMER DATA
            ----------------------------------------------------------------
            Source:
                bronze.crm_cust_info

            Target:
                silver.crm_cust_info

            Transformations:
                - Remove duplicate customer records.
                - Keep the most recent record for each customer ID.
                - Trim leading/trailing spaces from names.
                - Standardize marital status.
                - Standardize gender values.
        =================================================================*/

        -- Remove existing Silver-layer customer data before reloading.
        TRUNCATE TABLE silver.crm_cust_info;

        -- Insert cleansed and standardized customer data.
        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_material_status,
            cst_gndr,
            cst_create_date
        )
        SELECT
            cst_id,
            cst_key,

            -- Remove unnecessary leading and trailing spaces.
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname) AS cst_lastname,

            -- Standardize marital status codes.
            CASE UPPER(TRIM(cst_material_status))
                WHEN 'S' THEN 'Single'
                WHEN 'M' THEN 'Married'
                ELSE 'n/a'
            END AS cst_material_status,

            -- Standardize gender codes.
            CASE
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                ELSE 'n/a'
            END AS cst_gndr,

            cst_create_date

        FROM (
            SELECT
                *,

                /*
                    Assign a ranking to each customer record.

                    If multiple records exist for the same customer ID,
                    the most recently created record receives flag_last = 1.
                */
                ROW_NUMBER() OVER (
                    PARTITION BY cst_id
                    ORDER BY cst_create_date DESC
                ) AS flag_last

            FROM bronze.crm_cust_info

            -- Exclude records where the customer ID is missing.
            WHERE cst_id IS NOT NULL

        ) t

        -- Keep only the latest record for each customer.
        WHERE flag_last = 1;


        /*================================================================
            2. CRM PRODUCT DATA
            ----------------------------------------------------------------
            Source:
                bronze.crm_prd_info

            Target:
                silver.crm_prd_info

            Transformations:
                - Standardize category IDs.
                - Extract product key from the original product key.
                - Replace NULL product costs with 0.
                - Convert product line codes into descriptive values.
                - Convert start dates to DATE.
                - Calculate product end dates based on the next product
                  version's start date.
        =================================================================*/

        -- Remove existing Silver-layer product data.
        TRUNCATE TABLE silver.crm_prd_info;

        -- Insert cleansed and standardized product data.
        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,

            /*
                Extract the category portion of the product key
                and replace '-' with '_'.

                Example:
                    AC-HE -> AC_HE
            */
            REPLACE(
                SUBSTRING(prd_key, 1, 5),
                '-',
                '_'
            ) AS cat_id,

            /*
                Extract the product-specific portion of the original
                product key.

                Example:
                    AC-HE-1234 -> 1234
            */
            SUBSTRING(
                prd_key,
                7,
                LEN(prd_key)
            ) AS prd_key,

            prd_nm,

            -- Replace missing product costs with zero.
            ISNULL(prd_cost, 0) AS prd_cost,

            /*
                Convert product line codes into meaningful descriptions.
            */
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
            END AS prd_line,

            -- Convert the product start date to DATE.
            CAST(prd_start_dt AS DATE) AS prd_start_dt,

            /*
                Calculate the end date of the current product version.

                The end date is one day before the next version starts.

                DATEADD is used instead of subtracting 1 directly
                because it is the proper SQL Server date arithmetic method.
            */
            DATEADD(
                DAY,
                -1,
                LEAD(prd_start_dt) OVER (
                    PARTITION BY prd_key
                    ORDER BY prd_start_dt
                )
            ) AS prd_end_dt

        FROM bronze.crm_prd_info;


        /*================================================================
            3. CRM SALES DATA
            ----------------------------------------------------------------
            Source:
                bronze.crm_sales_info

            Target:
                silver.crm_sales_info

            Transformations:
                - Convert integer-based dates into DATE values.
                - Convert invalid dates to NULL.
                - Validate and recalculate sales amounts.
                - Convert negative prices to positive values.
                - Derive missing or invalid prices from sales and quantity.
        =================================================================*/

        -- Remove existing Silver-layer sales data.
        TRUNCATE TABLE silver.crm_sales_info;

        -- Insert cleansed and standardized sales data.
        INSERT INTO silver.crm_sales_info (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,

            /*
                Convert YYYYMMDD integer values into DATE.

                Invalid values such as:
                    0
                    values with an incorrect length

                are converted to NULL.
            */
            CASE
                WHEN sls_order_dt = 0
                     OR LEN(sls_order_dt) != 8
                    THEN NULL
                ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
            END AS sls_order_dt,

            CASE
                WHEN sls_ship_dt = 0
                     OR LEN(sls_ship_dt) != 8
                    THEN NULL
                ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
            END AS sls_ship_dt,

            CASE
                WHEN sls_due_dt = 0
                     OR LEN(sls_due_dt) != 8
                    THEN NULL
                ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
            END AS sls_due_dt,

            /*
                Validate the sales amount.

                If sales is:
                    - NULL
                    - less than or equal to zero
                    - inconsistent with quantity × price

                then recalculate it using:

                    quantity × absolute(price)
            */
            CASE
                WHEN sls_sales IS NULL
                     OR sls_sales <= 0
                     OR sls_sales != sls_quantity * ABS(sls_price)
                    THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,

            sls_quantity,

            /*
                Validate the product price.

                If the price is missing or invalid, calculate it using:

                    sales / quantity

                NULLIF prevents division-by-zero errors.
            */
            CASE
                WHEN sls_price IS NULL
                     OR sls_price <= 0
                    THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END AS sls_price

        FROM bronze.crm_sales_info;


        /*================================================================
            4. ERP CUSTOMER DATA
            ----------------------------------------------------------------
            Source:
                bronze.erp_cust_az12

            Target:
                silver.erp_cust_az12

            Transformations:
                - Remove the 'NAS' prefix from customer IDs.
                - Replace future birth dates with NULL.
                - Standardize gender values.
        =================================================================*/

        -- Remove existing Silver-layer ERP customer data.
        TRUNCATE TABLE silver.erp_cust_az12;

        -- Insert cleansed ERP customer data.
        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
        SELECT

            /*
                Remove the 'NAS' prefix from customer IDs
                when it exists.

                Example:
                    NAS12345 -> 12345
            */
            CASE
                WHEN cid LIKE 'NAS%'
                    THEN SUBSTRING(cid, 4, LEN(cid))
                ELSE cid
            END AS cid,

            /*
                A birth date cannot logically be in the future.

                Future dates are therefore replaced with NULL.
            */
            CASE
                WHEN bdate > GETDATE()
                    THEN NULL
                ELSE bdate
            END AS bdate,

            /*
                Standardize gender values from different formats.
            */
            CASE
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE')
                    THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')
                    THEN 'Male'
                ELSE 'n/a'
            END AS gen

        FROM bronze.erp_cust_az12;


        /*================================================================
            5. ERP LOCATION DATA
            ----------------------------------------------------------------
            Source:
                bronze.erp_loc_a101

            Target:
                silver.erp_loc_a101

            Transformations:
                - Remove '-' characters from customer IDs.
                - Standardize country names.
                - Handle missing country values.
        =================================================================*/

        -- Remove existing Silver-layer location data.
        TRUNCATE TABLE silver.erp_loc_a101;

        -- Insert cleansed location data.
        INSERT INTO silver.erp_loc_a101 (
            cid,
            cntry
        )
        SELECT

            -- Remove '-' characters from customer IDs.
            REPLACE(cid, '-', '') AS cid,

            /*
                Standardize country codes and country names.

                DE      -> Germany
                US/USA  -> United States
                NULL/'' -> n/a
            */
            CASE
                WHEN TRIM(cntry) = 'DE'
                    THEN 'Germany'

                WHEN TRIM(cntry) IN ('US', 'USA')
                    THEN 'United States'

                WHEN TRIM(cntry) = ''
                     OR cntry IS NULL
                    THEN 'n/a'

                ELSE TRIM(cntry)
            END AS cntry

        FROM bronze.erp_loc_a101;


        /*================================================================
            6. ERP PRODUCT CATEGORY DATA
            ----------------------------------------------------------------
            Source:
                bronze.erp_px_cat_g1v2

            Target:
                silver.erp_px_cat_g1v2

            Transformations:
                No major transformations are currently required.

                The data is transferred from Bronze to Silver as-is.
                This table is included in the Silver loading procedure
                to maintain a consistent layer-to-layer loading process.
        =================================================================*/

        -- Remove existing Silver-layer category data.
        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        -- Load category data from Bronze into Silver.
        INSERT INTO silver.erp_px_cat_g1v2 (
            id,
            cat,
            subcat,
            maintenance
        )
        SELECT
            id,
            cat,
            subcat,
            maintenance
        FROM bronze.erp_px_cat_g1v2;


        /*================================================================
            SILVER LAYER LOAD COMPLETED SUCCESSFULLY
        =================================================================*/

        PRINT '================================================';
        PRINT 'SUCCESS: Silver Layer Load Completed';
        PRINT '================================================';


    END TRY


    /*================================================================
        ERROR HANDLING
        ----------------------------------------------------------------
        If any operation inside the TRY block fails, execution moves
        to the CATCH block.

        ERROR_NUMBER()
            Returns the SQL Server error number.

        ERROR_MESSAGE()
            Returns the detailed error message.

        ERROR_LINE()
            Returns the line number where the error occurred.

        THROW
            Re-raises the original error so that:
                - SQL Agent jobs can detect the failure.
                - Monitoring systems can detect the failure.
                - Calling applications can handle the failure.
    =================================================================*/

    BEGIN CATCH

        PRINT '================================================';
        PRINT 'ERROR: Silver Layer Load Failed';
        PRINT '================================================';

        PRINT 'Error Number: '
            + CAST(ERROR_NUMBER() AS NVARCHAR(10));

        PRINT 'Error Message: '
            + ERROR_MESSAGE();

        PRINT 'Error Line: '
            + CAST(ERROR_LINE() AS NVARCHAR(10));

        -- Re-raise the original error.
        THROW;

    END CATCH;

END;
GO
