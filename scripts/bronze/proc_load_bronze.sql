/*====================================================================
    STORED PROCEDURE: bronze.load_bronze
    -------------------------------------------------------------------
    Purpose:
        Loads raw data from the source CSV files into the Bronze layer
        of the Data Warehouse.

    ETL Process:
        1. Clear existing data from each Bronze table.
        2. Load the latest data from the corresponding source CSV file.
        3. Repeat the process for CRM and ERP source systems.
        4. Handle and report any errors that occur during the load.

    Bronze Layer:
        The Bronze layer stores raw data from source systems with
        minimal transformation. It serves as the initial landing zone
        for the Data Warehouse ETL pipeline.

    Source Systems:
        CRM - Customer Relationship Management data
        ERP - Enterprise Resource Planning data

    Important:
        - Existing Bronze data is truncated before each load.
        - CSV files must be accessible by the SQL Server service account.
        - The file paths below are environment-specific and may need
          to be updated when the project is deployed to another machine.
====================================================================*/


CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN

    /*---------------------------------------------------------------
        Begin TRY block

        All Bronze loading operations are placed inside a TRY block
        so that any loading error can be captured by the CATCH block.
    ----------------------------------------------------------------*/
    BEGIN TRY

        /*============================================================
            CRM: CUSTOMER INFORMATION
            ----------------------------------------------------------
            Clear the existing Bronze customer data and reload the
            latest records from the CRM source CSV file.
        ============================================================*/

        -- Remove existing records to ensure a full refresh.
        TRUNCATE TABLE bronze.crm_cust_info;

        -- Load raw customer data from the CRM source file.
        BULK INSERT bronze.crm_cust_info
        FROM 'E:\Ismail\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
        WITH (
            FIRSTROW = 2,              -- Skip the CSV header row.
            FIELDTERMINATOR = ',',     -- CSV columns are comma-separated.
            TABLOCK                    -- Improve bulk loading performance.
        );


        /*============================================================
            CRM: PRODUCT INFORMATION
            ----------------------------------------------------------
            Load raw product information from the CRM source system.
        ============================================================*/

        -- Remove existing product records before the new load.
        TRUNCATE TABLE bronze.crm_prd_info;

        -- Load raw product data from the CRM source file.
        BULK INSERT bronze.crm_prd_info
        FROM 'E:\Ismail\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );


        /*============================================================
            CRM: SALES INFORMATION
            ----------------------------------------------------------
            Load raw sales transaction data from the CRM source system.
        ============================================================*/

        -- Remove existing sales records before the new load.
        TRUNCATE TABLE bronze.crm_sales_info;

        -- Load raw sales data from the CRM source file.
        BULK INSERT bronze.crm_sales_info
        FROM 'E:\Ismail\sql-data-warehouse-project\datasets\source_crm\sales_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );


        /*============================================================
            ERP: LOCATION INFORMATION
            ----------------------------------------------------------
            Load raw customer/location mapping data from the ERP
            source system.
        ============================================================*/

        -- Remove existing ERP location records.
        TRUNCATE TABLE bronze.erp_loc_a101;

        -- Load raw location data from the ERP source file.
        BULK INSERT bronze.erp_loc_a101
        FROM 'E:\Ismail\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );


        /*============================================================
            ERP: CUSTOMER INFORMATION
            ----------------------------------------------------------
            Load additional customer information provided by the ERP
            source system.
        ============================================================*/

        -- Remove existing ERP customer records.
        TRUNCATE TABLE bronze.erp_cust_az12;

        -- Load raw customer data from the ERP source file.
        BULK INSERT bronze.erp_cust_az12
        FROM 'E:\Ismail\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );


        /*============================================================
            ERP: PRODUCT CATEGORY INFORMATION
            ----------------------------------------------------------
            Load raw product category information from the ERP source
            system.
        ============================================================*/

        -- Remove existing product category records.
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        -- Load raw product category data from the ERP source file.
        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'E:\Ismail\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );


        /*---------------------------------------------------------------
            Successful completion message

            Confirms that all Bronze tables were successfully loaded.
        ----------------------------------------------------------------*/
        PRINT '================================================';
        PRINT 'Bronze Layer Load Completed Successfully';
        PRINT '================================================';


    END TRY


    /*================================================================
        ERROR HANDLING
        ----------------------------------------------------------------
        If any operation inside the TRY block fails, execution moves
        to the CATCH block.

        ERROR_MESSAGE() returns the detailed SQL Server error message.
        ERROR_NUMBER() identifies the SQL Server error code.
        ERROR_LINE() identifies the line where the error occurred.
    =================================================================*/

    BEGIN CATCH

        PRINT '================================================';
        PRINT 'ERROR: Bronze Layer Load Failed';
        PRINT '================================================';

        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10));
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR(10));

        -- Re-raise the original error so that calling processes,
        -- monitoring systems, or SQL Agent jobs can detect the failure.
        THROW;

    END CATCH;

END;
GO
