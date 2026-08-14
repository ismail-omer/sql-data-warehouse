/*====================================================================================================================
    GOLD LAYER - DATA QUALITY CHECKS
    ====================================================================================================================

    SCRIPT PURPOSE:
        This script performs data quality and integrity checks against the
        Gold layer views.

        The Gold layer represents the final business-ready analytical layer
        of the Data Warehouse and follows a Star Schema design.

    GOLD LAYER OBJECTS:
        - gold.dim_customers
        - gold.dim_products
        - gold.fact_sales

    QUALITY DIMENSIONS:
        1. Completeness
        2. Uniqueness
        3. Referential Integrity
        4. Validity
        5. Consistency
        6. Business Rule Validation
        7. Star Schema Integrity

    IMPORTANT:
        These checks are designed to identify data-quality issues.

        They do NOT modify the Gold layer.

        Any required data corrections should be applied in the Bronze-to-Silver
        transformation logic or Silver-to-Gold transformation logic rather
        than directly modifying the Gold views.

====================================================================================================================*/


/*====================================================================================================================
    1. CUSTOMER DIMENSION - COMPLETENESS CHECKS
    ====================================================================================================================

    PURPOSE:
        Verify that important customer attributes are populated.

====================================================================================================================*/


/*---------------------------------------------------------------
    CHECK 1.1
    Check for NULL customer surrogate keys.
----------------------------------------------------------------*/

SELECT *
FROM gold.dim_customers
WHERE customer_key IS NULL;


/*---------------------------------------------------------------
    CHECK 1.2
    Check for NULL customer IDs.
----------------------------------------------------------------*/

SELECT *
FROM gold.dim_customers
WHERE customer_id IS NULL;


/*---------------------------------------------------------------
    CHECK 1.3
    Check for NULL customer numbers.
----------------------------------------------------------------*/

SELECT *
FROM gold.dim_customers
WHERE customer_number IS NULL
   OR TRIM(customer_number) = '';


/*---------------------------------------------------------------
    CHECK 1.4
    Check for missing customer names.
----------------------------------------------------------------*/

SELECT *
FROM gold.dim_customers
WHERE first_name IS NULL
   OR TRIM(first_name) = ''
   OR last_name IS NULL
   OR TRIM(last_name) = '';


/*====================================================================================================================
    2. CUSTOMER DIMENSION - UNIQUENESS CHECKS
    ====================================================================================================================*/


/*---------------------------------------------------------------
    CHECK 2.1
    Customer surrogate key must be unique.
----------------------------------------------------------------*/

SELECT
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;


/*---------------------------------------------------------------
    CHECK 2.2
    Customer ID should be unique in the customer dimension.
----------------------------------------------------------------*/

SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


/*---------------------------------------------------------------
    CHECK 2.3
    Customer business number should be unique.
----------------------------------------------------------------*/

SELECT
    customer_number,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_number
HAVING COUNT(*) > 1;


/*====================================================================================================================
    3. CUSTOMER DIMENSION - STANDARDIZATION CHECKS
    ====================================================================================================================*/


/*---------------------------------------------------------------
    CHECK 3.1
    Verify that gender values are standardized.
----------------------------------------------------------------*/

SELECT DISTINCT gender
FROM gold.dim_customers
WHERE gender NOT IN (
    'Male',
    'Female',
    'n/a'
);


/*---------------------------------------------------------------
    CHECK 3.2
    Verify that marital status values are standardized.
----------------------------------------------------------------*/

SELECT DISTINCT material_status
FROM gold.dim_customers
WHERE material_status NOT IN (
    'Single',
    'Married',
    'n/a'
);


/*---------------------------------------------------------------
    CHECK 3.3
    Verify that customer names do not contain unnecessary spaces.
----------------------------------------------------------------*/

SELECT *
FROM gold.dim_customers
WHERE first_name <> TRIM(first_name)
   OR last_name <> TRIM(last_name);


/*====================================================================================================================
    4. CUSTOMER DIMENSION - DATE VALIDATION
    ====================================================================================================================*/


/*---------------------------------------------------------------
    CHECK 4.1
    Birth dates should not be in the future.
----------------------------------------------------------------*/

SELECT *
FROM gold.dim_customers
WHERE birth_date > CAST(GETDATE() AS DATE);


/*---------------------------------------------------------------
    CHECK 4.2
    Customer creation dates should not be in the future.
----------------------------------------------------------------*/

SELECT *
FROM gold.dim_customers
WHERE cst_create_date > CAST(GETDATE() AS DATE);


/*---------------------------------------------------------------
    CHECK 4.3
    Birth date should not occur after customer creation date.
----------------------------------------------------------------*/

SELECT *
FROM gold.dim_customers
WHERE birth_date > cst_create_date;


/*====================================================================================================================
    5. PRODUCT DIMENSION - COMPLETENESS CHECKS
    ====================================================================================================================*/


/*---------------------------------------------------------------
    CHECK 5.1
    Check for NULL product surrogate keys.
----------------------------------------------------------------*/

SELECT *
FROM gold.dim_products
WHERE product_key IS NULL;


/*---------------------------------------------------------------
    CHECK 5.2
    Check for NULL product IDs.
----------------------------------------------------------------*/

SELECT *
FROM gold.dim_products
WHERE product_id IS NULL;


/*---------------------------------------------------------------
    CHECK 5.3
    Check for NULL product numbers.
----------------------------------------------------------------*/

SELECT *
FROM gold.dim_products
WHERE product_number IS NULL
   OR TRIM(product_number) = '';


/*---------------------------------------------------------------
    CHECK 5.4
    Check for NULL product names.
----------------------------------------------------------------*/

SELECT *
FROM gold.dim_products
WHERE product_name IS NULL
   OR TRIM(product_name) = '';


/*---------------------------------------------------------------
    CHECK 5.5
    Check for missing category information.
----------------------------------------------------------------*/

SELECT *
FROM gold.dim_products
WHERE category_id IS NULL
   OR category IS NULL
   OR subcategory IS NULL;


/*====================================================================================================================
    6. PRODUCT DIMENSION - UNIQUENESS CHECKS
    ====================================================================================================================*/


/*---------------------------------------------------------------
    CHECK 6.1
    Product surrogate key must be unique.
----------------------------------------------------------------*/

SELECT
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;


/*---------------------------------------------------------------
    CHECK 6.2
    Product ID should be unique.
----------------------------------------------------------------*/

SELECT
    product_id,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_id
HAVING COUNT(*) > 1;


/*---------------------------------------------------------------
    CHECK 6.3
    Product number should be unique.

    This is especially important because fact_sales uses
    product_number to obtain product_key.
----------------------------------------------------------------*/

SELECT
    product_number,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_number
HAVING COUNT(*) > 1;


/*====================================================================================================================
    7. PRODUCT DIMENSION - BUSINESS RULE CHECKS
    ====================================================================================================================*/


/*---------------------------------------------------------------
    CHECK 7.1
    Product cost should not be negative.
----------------------------------------------------------------*/

SELECT *
FROM gold.dim_products
WHERE cost < 0;


/*---------------------------------------------------------------
    CHECK 7.2
    Verify that only current product records exist.

    The Gold product dimension should contain only records where
    the Silver product end date is NULL.
----------------------------------------------------------------*/

SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt IS NULL;


/*---------------------------------------------------------------
    CHECK 7.3
    Verify that product start dates are valid.
----------------------------------------------------------------*/

SELECT *
FROM gold.dim_products
WHERE start_date IS NULL;


/*---------------------------------------------------------------
    CHECK 7.4
    Verify standardized product lines.
----------------------------------------------------------------*/

SELECT DISTINCT product_line
FROM gold.dim_products
WHERE product_line NOT IN (
    'Mountain',
    'Road',
    'Other Sales',
    'Touring',
    'n/a'
);


/*====================================================================================================================
    8. FACT SALES - COMPLETENESS CHECKS
    ====================================================================================================================*/


/*---------------------------------------------------------------
    CHECK 8.1
    Check for NULL order numbers.
----------------------------------------------------------------*/

SELECT *
FROM gold.fact_sales
WHERE order_number IS NULL
   OR TRIM(order_number) = '';


/*---------------------------------------------------------------
    CHECK 8.2
    Check for NULL product surrogate keys.

    A NULL product_key indicates that the sales transaction could
    not be matched to a product dimension record.
----------------------------------------------------------------*/

SELECT *
FROM gold.fact_sales
WHERE product_key IS NULL;


/*---------------------------------------------------------------
    CHECK 8.3
    Check for NULL customer surrogate keys.

    A NULL customer_key indicates that the sales transaction could
    not be matched to a customer dimension record.
----------------------------------------------------------------*/

SELECT *
FROM gold.fact_sales
WHERE customer_key IS NULL;


/*---------------------------------------------------------------
    CHECK 8.4
    Check for NULL sales amounts.
----------------------------------------------------------------*/

SELECT *
FROM gold.fact_sales
WHERE sales_amount IS NULL;


/*---------------------------------------------------------------
    CHECK 8.5
    Check for NULL quantities.
----------------------------------------------------------------*/

SELECT *
FROM gold.fact_sales
WHERE quantity IS NULL;


/*---------------------------------------------------------------
    CHECK 8.6
    Check for NULL prices.
----------------------------------------------------------------*/

SELECT *
FROM gold.fact_sales
WHERE price IS NULL;


/*====================================================================================================================
    9. FACT SALES - BUSINESS RULE CHECKS
    ====================================================================================================================*/


/*---------------------------------------------------------------
    CHECK 9.1
    Quantity should be greater than zero.
----------------------------------------------------------------*/

SELECT *
FROM gold.fact_sales
WHERE quantity <= 0;


/*---------------------------------------------------------------
    CHECK 9.2
    Price should be greater than zero.
----------------------------------------------------------------*/

SELECT *
FROM gold.fact_sales
WHERE price <= 0;


/*---------------------------------------------------------------
    CHECK 9.3
    Sales amount should be greater than zero.
----------------------------------------------------------------*/

SELECT *
FROM gold.fact_sales
WHERE sales_amount <= 0;


/*---------------------------------------------------------------
    CHECK 9.4
    Verify the fundamental sales calculation:

        Sales Amount = Quantity × Price

    NOTE:
        Depending on the business definition of sales, discounts,
        taxes, or other adjustments may cause this relationship
        to differ.
----------------------------------------------------------------*/

SELECT
    *,
    quantity * price AS calculated_sales
FROM gold.fact_sales
WHERE sales_amount <> quantity * price;


/*====================================================================================================================
    10. FACT SALES - DATE VALIDATION
    ====================================================================================================================*/


/*---------------------------------------------------------------
    CHECK 10.1
    Shipping date should not be before order date.
----------------------------------------------------------------*/

SELECT *
FROM gold.fact_sales
WHERE shipping_date < order_date;


/*---------------------------------------------------------------
    CHECK 10.2
    Due date should not be before order date.
----------------------------------------------------------------*/

SELECT *
FROM gold.fact_sales
WHERE due_date < order_date;


/*---------------------------------------------------------------
    CHECK 10.3
    Shipping date should not be before order date.
----------------------------------------------------------------*/

SELECT *
FROM gold.fact_sales
WHERE shipping_date IS NOT NULL
  AND order_date IS NOT NULL
  AND shipping_date < order_date;


/*---------------------------------------------------------------
    CHECK 10.4
    Due date should not be before shipping date when both
    dates are available.
----------------------------------------------------------------*/

SELECT *
FROM gold.fact_sales
WHERE due_date IS NOT NULL
  AND shipping_date IS NOT NULL
  AND due_date < shipping_date;


/*====================================================================================================================
    11. FACT TABLE - DUPLICATE CHECKS
    ====================================================================================================================

    PURPOSE:
        Validate that the fact table does not contain unexpected
        duplicate transaction lines.

    NOTE:
        The exact grain should be confirmed according to the source
        system's business definition.

====================================================================================================================*/


SELECT
    order_number,
    product_key,
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.fact_sales
GROUP BY
    order_number,
    product_key,
    customer_key
HAVING COUNT(*) > 1;


/*====================================================================================================================
    12. REFERENTIAL INTEGRITY
    ====================================================================================================================

    PURPOSE:
        Validate the relationships between the Fact and Dimension
        tables in the Star Schema.

====================================================================================================================*/


/*---------------------------------------------------------------
    CHECK 12.1
    Every product_key in fact_sales should exist in dim_products.
----------------------------------------------------------------*/

SELECT
    f.product_key,
    COUNT(*) AS invalid_records
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
WHERE p.product_key IS NULL
GROUP BY f.product_key;


/*---------------------------------------------------------------
    CHECK 12.2
    Every customer_key in fact_sales should exist in
    dim_customers.
----------------------------------------------------------------*/

SELECT
    f.customer_key,
    COUNT(*) AS invalid_records
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
WHERE c.customer_key IS NULL
GROUP BY f.customer_key;


/*---------------------------------------------------------------
    CHECK 12.3
    Every product number in fact_sales should have a corresponding
    product in dim_products.
----------------------------------------------------------------*/

SELECT
    f.order_number,
    f.product_key
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
WHERE p.product_key IS NULL;


/*====================================================================================================================
    13. SURROGATE KEY SEQUENCE CHECKS
    ====================================================================================================================

    PURPOSE:
        Validate that dimension surrogate keys are sequential.

    NOTE:
        This is primarily a diagnostic check. Sequential surrogate
        keys are not always a strict business requirement.

====================================================================================================================*/


/*---------------------------------------------------------------
    CHECK 13.1
    Customer surrogate key sequence.
----------------------------------------------------------------*/

SELECT
    MIN(customer_key) AS min_customer_key,
    MAX(customer_key) AS max_customer_key,
    COUNT(*) AS customer_count
FROM gold.dim_customers;


/*---------------------------------------------------------------
    CHECK 13.2
    Product surrogate key sequence.
----------------------------------------------------------------*/

SELECT
    MIN(product_key) AS min_product_key,
    MAX(product_key) AS max_product_key,
    COUNT(*) AS product_count
FROM gold.dim_products;


/*====================================================================================================================
    14. STAR SCHEMA SUMMARY CHECK
    ====================================================================================================================

    PURPOSE:
        Provide a high-level overview of the Gold layer.

====================================================================================================================*/

SELECT
    'gold.dim_customers' AS table_name,
    COUNT(*) AS record_count
FROM gold.dim_customers

UNION ALL

SELECT
    'gold.dim_products',
    COUNT(*)
FROM gold.dim_products

UNION ALL

SELECT
    'gold.fact_sales',
    COUNT(*)
FROM gold.fact_sales;


/*====================================================================================================================
    15. GOLD LAYER DATA DISTRIBUTION
    ====================================================================================================================*/


/*---------------------------------------------------------------
    Customer distribution by country.
----------------------------------------------------------------*/

SELECT
    country,
    COUNT(*) AS customer_count
FROM gold.dim_customers
GROUP BY country
ORDER BY customer_count DESC;


/*---------------------------------------------------------------
    Customer distribution by gender.
----------------------------------------------------------------*/

SELECT
    gender,
    COUNT(*) AS customer_count
FROM gold.dim_customers
GROUP BY gender
ORDER BY customer_count DESC;


/*---------------------------------------------------------------
    Product distribution by category.
----------------------------------------------------------------*/

SELECT
    category,
    COUNT(*) AS product_count
FROM gold.dim_products
GROUP BY category
ORDER BY product_count DESC;


/*---------------------------------------------------------------
    Product distribution by product line.
----------------------------------------------------------------*/

SELECT
    product_line,
    COUNT(*) AS product_count
FROM gold.dim_products
GROUP BY product_line
ORDER BY product_count DESC;


/*====================================================================================================================
    16. FACT SALES SUMMARY
    ====================================================================================================================*/


/*---------------------------------------------------------------
    Overall sales metrics.
----------------------------------------------------------------*/

SELECT
    COUNT(*) AS total_sales_records,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    AVG(price) AS average_price
FROM gold.fact_sales;


/*---------------------------------------------------------------
    Sales by order date.
----------------------------------------------------------------*/

SELECT
    order_date,
    COUNT(*) AS sales_records,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
GROUP BY order_date
ORDER BY order_date;


/*====================================================================================================================
    17. FINAL GOLD LAYER QUALITY SUMMARY
    ====================================================================================================================

    The Gold layer should satisfy the following conditions:

        [1] Customer surrogate keys are unique.
        [2] Product surrogate keys are unique.
        [3] Customer and product business keys are unique.
        [4] Fact records contain valid customer keys.
        [5] Fact records contain valid product keys.
        [6] Sales amounts are positive.
        [7] Quantities are positive.
        [8] Prices are positive.
        [9] Date relationships are logically valid.
        [10] Customer and product dimensions contain standardized values.
        [11] The Gold layer contains current product records only.
        [12] Fact-to-dimension relationships maintain referential integrity.

    IMPORTANT:
        A query returning ZERO rows for a validation check generally
        indicates that no records violated that specific rule.

====================================================================================================================*/
