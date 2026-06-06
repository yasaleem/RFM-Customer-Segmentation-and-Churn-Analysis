-- ============================================================
-- DATA QUALITY CHECKS
-- Project  : E-Commerce Customer Analytics
-- Author   : [Your Name]
-- Date     : 2010-12-31
-- Purpose  : Document all data quality checks performed
--            across raw and staging layers
-- ============================================================


-- ============================================================
-- SECTION 1 : RAW LAYER CHECKS
-- Purpose   : Verify dirty data landed correctly from source
--             systems before any cleaning was applied
-- ============================================================


-- ------------------------------------------------------------
-- 1.1 ROW COUNT VERIFICATION
-- Expected  : crm_customers=4460, erp_orders=28245, 
--             erp_order_items=533168
-- ------------------------------------------------------------
SELECT 'crm_customers'  AS table_name, COUNT(*) AS row_count FROM raw.crm_customers
UNION ALL
SELECT 'erp_orders',      COUNT(*) FROM raw.erp_orders
UNION ALL
SELECT 'erp_order_items', COUNT(*) FROM raw.erp_order_items;


-- ------------------------------------------------------------
-- 1.2 BROKEN EMAILS
-- Expected  : Returns rows with missing @, double @@, 
--             leading spaces
-- ------------------------------------------------------------
SELECT Email, COUNT(*) AS occurrences
FROM raw.crm_customers
WHERE Email NOT LIKE '%@%.%'
   OR Email LIKE '%@@%'
   OR Email LIKE ' %'
GROUP BY Email
ORDER BY occurrences DESC;


-- ------------------------------------------------------------
-- 1.3 MIXED CASE COUNTRIES
-- Expected  : Returns countries in lowercase, uppercase,
--             and abbreviated formats e.g. UK, U.K.
-- ------------------------------------------------------------
SELECT DISTINCT Country, COUNT(*) AS occurrences
FROM raw.crm_customers
GROUP BY Country
ORDER BY Country;


-- ------------------------------------------------------------
-- 1.4 MISSING CITIES
-- Expected  : Returns count of NULL or empty city values
-- ------------------------------------------------------------
SELECT COUNT(*) AS missing_cities
FROM raw.crm_customers
WHERE City IS NULL OR City = '';


-- ------------------------------------------------------------
-- 1.5 FUTURE REGISTRATION DATES
-- Expected  : Returns records with year 2025
-- ------------------------------------------------------------
SELECT TOP 10 Customer_ID, Registration_Date
FROM raw.crm_customers
WHERE LEFT(Registration_Date, 4) = '2025';


-- ------------------------------------------------------------
-- 1.6 DUPLICATE CUSTOMERS
-- Expected  : Returns Customer IDs appearing more than once
-- ------------------------------------------------------------
SELECT Customer_ID, COUNT(*) AS occurrences
FROM raw.crm_customers
GROUP BY Customer_ID
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


-- ------------------------------------------------------------
-- 1.7 CANCELLATION ORDERS MIXED IN ORDERS
-- Expected  : Returns orders with Invoice starting with C
-- ------------------------------------------------------------
SELECT TOP 10 Invoice
FROM raw.erp_orders
WHERE Invoice LIKE 'C%';


-- ------------------------------------------------------------
-- 1.8 MALFORMED DATES IN ORDERS
-- Expected  : Returns dates that cannot be cast to DATETIME
-- ------------------------------------------------------------
SELECT TOP 10 InvoiceDate
FROM raw.erp_orders
WHERE TRY_CAST(InvoiceDate AS DATETIME) IS NULL
AND InvoiceDate IS NOT NULL;


-- ------------------------------------------------------------
-- 1.9 NEGATIVE QUANTITIES IN ORDER ITEMS
-- Expected  : Returns count of negative quantity rows
-- ------------------------------------------------------------
SELECT COUNT(*) AS negative_qty
FROM raw.erp_order_items
WHERE TRY_CAST(Quantity AS INT) < 0;


-- ------------------------------------------------------------
-- 1.10 ZERO PRICES IN ORDER ITEMS
-- Expected  : Returns count of zero price rows
-- ------------------------------------------------------------
SELECT COUNT(*) AS zero_price
FROM raw.erp_order_items
WHERE TRY_CAST(Price AS FLOAT) = 0;


-- ------------------------------------------------------------
-- 1.11 MIXED CASE STOCKCODE
-- Expected  : Returns StockCodes with lowercase characters
-- ------------------------------------------------------------
SELECT TOP 10 StockCode
FROM raw.erp_order_items
WHERE StockCode != UPPER(StockCode) COLLATE Latin1_General_BIN;


-- ------------------------------------------------------------
-- 1.12 OUTLIER QUANTITIES DISTRIBUTION
-- Expected  : Shows spike at 5000+ confirming injected outliers
-- ------------------------------------------------------------
SELECT 
    CASE 
        WHEN CAST(Quantity AS INT) BETWEEN 1    AND 99   THEN '1-99'
        WHEN CAST(Quantity AS INT) BETWEEN 100  AND 999  THEN '100-999'
        WHEN CAST(Quantity AS INT) BETWEEN 1000 AND 4999 THEN '1000-4999'
        WHEN CAST(Quantity AS INT) >= 5000               THEN '5000+'
    END AS quantity_range,
    COUNT(*) AS row_count
FROM raw.erp_order_items
GROUP BY 
    CASE 
        WHEN CAST(Quantity AS INT) BETWEEN 1    AND 99   THEN '1-99'
        WHEN CAST(Quantity AS INT) BETWEEN 100  AND 999  THEN '100-999'
        WHEN CAST(Quantity AS INT) BETWEEN 1000 AND 4999 THEN '1000-4999'
        WHEN CAST(Quantity AS INT) >= 5000               THEN '5000+'
    END
ORDER BY MIN(CAST(Quantity AS INT));


-- ============================================================
-- SECTION 2 : STAGING LAYER CHECKS
-- Purpose   : Verify all cleaning tasks were applied correctly
-- ============================================================


-- ------------------------------------------------------------
-- 2.1 ROW COUNT COMPARISON RAW VS STAGING
-- Expected  : Staging has fewer rows due to deduplication
--             and removal of invalid records
-- ------------------------------------------------------------
SELECT 'raw.crm_customers'      AS layer, COUNT(*) AS row_count FROM raw.crm_customers
UNION ALL
SELECT 'staging.crm_customers',  COUNT(*) FROM staging.crm_customers
UNION ALL
SELECT 'raw.erp_orders',         COUNT(*) FROM raw.erp_orders
UNION ALL
SELECT 'staging.erp_orders',     COUNT(*) FROM staging.erp_orders
UNION ALL
SELECT 'raw.erp_order_items',    COUNT(*) FROM raw.erp_order_items
UNION ALL
SELECT 'staging.erp_order_items',COUNT(*) FROM staging.erp_order_items;


-- ------------------------------------------------------------
-- 2.2 NO DUPLICATE CUSTOMERS
-- Expected  : Returns zero rows
-- ------------------------------------------------------------
SELECT Customer_ID, COUNT(*) AS occurrences
FROM staging.crm_customers
GROUP BY Customer_ID
HAVING COUNT(*) > 1;


-- ------------------------------------------------------------
-- 2.3 COUNTRY STANDARDIZATION VERIFIED
-- Expected  : No lowercase, uppercase, or abbreviated 
--             country names remain
-- ------------------------------------------------------------
SELECT DISTINCT Country, COUNT(*) AS occurrences
FROM staging.crm_customers
GROUP BY Country
ORDER BY Country;


-- ------------------------------------------------------------
-- 2.4 EMAIL QUALITY CHECK
-- Expected  : null_emails = records with unfixable emails
--             still_broken = 0
-- ------------------------------------------------------------
SELECT 
    COUNT(*)                                        AS total_customers,
    SUM(CASE WHEN Email IS NULL THEN 1 ELSE 0 END) AS null_emails,
    SUM(CASE WHEN Email IS NOT NULL 
             AND Email NOT LIKE '%@%.%' 
             THEN 1 ELSE 0 END)                    AS still_broken
FROM staging.crm_customers;


-- ------------------------------------------------------------
-- 2.5 MISSING CITIES IMPUTED
-- Expected  : missing_cities = 0
--             imputed_cities = ~300
-- ------------------------------------------------------------
SELECT 
    COUNT(*)                                              AS total_customers,
    SUM(CASE WHEN City IS NULL OR City = '' 
             THEN 1 ELSE 0 END)                          AS missing_cities,
    SUM(CASE WHEN City LIKE 'Unknown%' 
             THEN 1 ELSE 0 END)                          AS imputed_cities
FROM staging.crm_customers;


-- ------------------------------------------------------------
-- 2.6 NO FUTURE REGISTRATION DATES
-- Expected  : future_dates = 0
-- ------------------------------------------------------------
SELECT 
    SUM(CASE WHEN YEAR(Registration_Date) = 2025 
             THEN 1 ELSE 0 END) AS future_dates,
    SUM(CASE WHEN YEAR(Registration_Date) = 2010 
             THEN 1 ELSE 0 END) AS correct_dates
FROM staging.crm_customers;


-- ------------------------------------------------------------
-- 2.7 CANCELLATIONS SEPARATED FROM VALID ORDERS
-- Expected  : valid_orders + cancellations = staging total
--             cancellation_rate ~16%
-- ------------------------------------------------------------
SELECT 
    COUNT(*)                                              AS valid_orders
FROM staging.erp_orders
UNION ALL
SELECT COUNT(*) FROM staging.erp_orders_cancellations;

-- Cancellation rate
SELECT 
    CAST(
        (SELECT COUNT(*) FROM staging.erp_orders_cancellations) 
        AS FLOAT) 
    / 
    (
        (SELECT COUNT(*) FROM staging.erp_orders) + 
        (SELECT COUNT(*) FROM staging.erp_orders_cancellations)
    ) * 100 AS cancellation_rate_pct;


-- ------------------------------------------------------------
-- 2.8 NULL DATES IN ORDERS
-- Expected  : ~402 null dates retained
-- ------------------------------------------------------------
SELECT 
    COUNT(*)                                              AS total_orders,
    SUM(CASE WHEN InvoiceDate IS NULL THEN 1 ELSE 0 END) AS null_dates
FROM staging.erp_orders;


-- ------------------------------------------------------------
-- 2.9 NO DUPLICATE ORDERS
-- Expected  : Returns zero rows
-- ------------------------------------------------------------
SELECT Invoice, COUNT(*) AS occurrences
FROM staging.erp_orders
GROUP BY Invoice
HAVING COUNT(*) > 1;


-- ------------------------------------------------------------
-- 2.10 NO LOWERCASE STOCKCODES OR DESCRIPTIONS
-- Expected  : Returns zero rows
-- ------------------------------------------------------------
SELECT TOP 10 StockCode, Description
FROM staging.erp_order_items
WHERE StockCode != UPPER(StockCode) COLLATE Latin1_General_BIN;


-- ------------------------------------------------------------
-- 2.11 ZERO AND NEGATIVE QUANTITIES REMOVED
-- Expected  : negative_qty = 0, zero_qty = 0
-- ------------------------------------------------------------
SELECT 
    SUM(CASE WHEN Quantity < 0 THEN 1 ELSE 0 END) AS negative_qty,
    SUM(CASE WHEN Quantity = 0 THEN 1 ELSE 0 END) AS zero_qty
FROM staging.erp_order_items;


-- ------------------------------------------------------------
-- 2.12 OUTLIER QUANTITIES REMOVED
-- Expected  : max_qty < 5000
-- ------------------------------------------------------------
SELECT 
    MIN(Quantity) AS min_qty,
    MAX(Quantity) AS max_qty,
    AVG(CAST(Quantity AS FLOAT)) AS avg_qty
FROM staging.erp_order_items;


-- ------------------------------------------------------------
-- 2.13 ZERO PRICES IMPUTED OR NULLED
-- Expected  : zero_prices = 0
--             null_prices = ~410 (no valid reference found)
-- ------------------------------------------------------------
SELECT 
    SUM(CASE WHEN Price = 0    THEN 1 ELSE 0 END) AS zero_prices,
    SUM(CASE WHEN Price IS NULL THEN 1 ELSE 0 END) AS null_prices,
    COUNT(*)                                        AS total_rows
FROM staging.erp_order_items;


-- ------------------------------------------------------------
-- 2.14 NO DUPLICATE ORDER ITEMS
-- Expected  : Returns zero rows
-- ------------------------------------------------------------
SELECT Invoice, StockCode, COUNT(*) AS occurrences
FROM staging.erp_order_items
GROUP BY Invoice, StockCode
HAVING COUNT(*) > 1;


-- ------------------------------------------------------------
-- 2.15 DATA TYPE VERIFICATION
-- Expected  : All columns show correct data types
-- ------------------------------------------------------------
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'staging'
AND TABLE_NAME IN ('crm_customers', 'erp_orders', 'erp_order_items')
ORDER BY TABLE_NAME, ORDINAL_POSITION;


-- ------------------------------------------------------------
-- 2.16 REFERENTIAL INTEGRITY CHECK
-- Expected  : Returns count of orders with no matching 
--             customer in CRM — guest checkouts expected
-- ------------------------------------------------------------
SELECT 
    COUNT(*) AS orders_with_no_customer
FROM staging.erp_orders o
LEFT JOIN staging.crm_customers c ON o.Customer_ID = c.Customer_ID
WHERE c.Customer_ID IS NULL;


-- ============================================================
-- SECTION 3 : SUMMARY REPORT
-- Purpose   : Single view of all data quality results
-- ============================================================
SELECT 'Total Raw Customers'        AS metric, COUNT(*) AS value FROM raw.crm_customers
UNION ALL
SELECT 'Total Staging Customers',    COUNT(*) FROM staging.crm_customers
UNION ALL
SELECT 'Duplicate Customers Removed',4460 - COUNT(*) FROM staging.crm_customers
UNION ALL
SELECT 'Total Raw Orders',           COUNT(*) FROM raw.erp_orders
UNION ALL
SELECT 'Valid Staging Orders',       COUNT(*) FROM staging.erp_orders
UNION ALL
SELECT 'Cancellation Orders',        COUNT(*) FROM staging.erp_orders_cancellations
UNION ALL
SELECT 'Total Raw Order Items',      COUNT(*) FROM raw.erp_order_items
UNION ALL
SELECT 'Total Staging Order Items',  COUNT(*) FROM staging.erp_order_items
UNION ALL
SELECT 'Order Items Removed',        533168 - COUNT(*) FROM staging.erp_order_items;
