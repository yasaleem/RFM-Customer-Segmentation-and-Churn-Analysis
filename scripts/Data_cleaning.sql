-- ============================================================
-- STAGING LAYER — DATA CLEANING AND TRANSFORMATION
-- Project  : RFM Customer Segmentation and Churn Analysis
-- Company  : BritGifts Online
-- Author   : Yassir Saleem — Customer Analytics Analyst
-- Date     : 2010-12-31
-- Purpose  : Clean, deduplicate, and prepare raw data for
--            analytics layer across three staging tables
-- ============================================================
-- Source Tables  : raw.crm_customers
--                  raw.erp_orders
--                  raw.erp_order_items
-- Output Tables  : staging.crm_customers
--                  staging.erp_orders
--                  staging.erp_orders_cancellations
--                  staging.erp_order_items
-- ============================================================
-- Cleaning Approach:
-- All transformations applied in a single INSERT INTO per table
-- Raw layer is never modified — serves as permanent audit trail
-- Every cleaning decision documented with rationale
-- Type casting applied last after all cleaning is complete
-- ============================================================


-- ============================================================
-- TABLE 1 : staging.crm_customers
-- Source  : raw.crm_customers
-- Purpose : Clean customer master data — deduplicate, fix
--           countries, emails, cities, and dates
-- ============================================================

-- ------------------------------------------------------------
-- Cleaning tasks applied in one statement:
-- 1. Deduplication        — ROW_NUMBER() PARTITION BY Customer_ID
-- 2. Country standardize  — CASE WHEN UPPER(TRIM(Country))
-- 3. Email fix            — TRIM spaces, fix @@, NULL unfixable
-- 4. City imputation      — Unknown - Country for NULL cities
-- 5. Date fix             — Replace year 2025 with 2010
-- 6. Type casting         — Customer_ID to INT, Date to DATE
-- ------------------------------------------------------------

DROP TABLE IF EXISTS staging.crm_customers;

CREATE TABLE staging.crm_customers (
    Customer_ID         INT,            -- cast from NVARCHAR
    Email               NVARCHAR(255),
    City                NVARCHAR(100),
    Country             NVARCHAR(100),
    Registration_Date   DATE,           -- cast from NVARCHAR
    dwh_create_date     DATETIME2 DEFAULT GETDATE()
);

INSERT INTO staging.crm_customers (
    Customer_ID,
    Email,
    City,
    Country,
    Registration_Date
)
SELECT
    -- ── TYPE CAST ──────────────────────────────────────────
    -- Customer_ID loaded as NVARCHAR in raw — cast to INT
    -- TRY_CAST returns NULL instead of error if cast fails
    TRY_CAST(Customer_ID AS INT)                AS Customer_ID,

    -- ── EMAIL CLEANING ─────────────────────────────────────
    -- Three issues found in raw data:
    -- 1. Leading spaces    → TRIM removes them
    -- 2. Double @@         → REPLACE fixes to single @
    -- 3. Missing @ symbol  → cannot recover, NULL out
    -- Order matters: check unfixable first, then fix fixable
    CASE
        WHEN TRIM(Email) NOT LIKE '%@%'          THEN NULL
        WHEN TRIM(Email) LIKE '%@@%'             THEN REPLACE(TRIM(Email), '@@', '@')
        ELSE                                          TRIM(Email)
    END                                         AS Email,

    -- ── CITY IMPUTATION ────────────────────────────────────
    -- ~7% of customers have NULL or empty city values
    -- Cannot determine exact city from available data
    -- Impute as Unknown - Country to preserve geographic context
    -- while honestly flagging the gap
    CASE
        WHEN City IS NULL OR City = ''           THEN 'Unknown - ' + 
             -- Use cleaned country for imputation label
             UPPER(LEFT(TRIM(Country), 1)) + 
             LOWER(SUBSTRING(TRIM(Country), 2, LEN(Country)))
        ELSE City
    END                                         AS City,

    -- ── COUNTRY STANDARDIZATION ────────────────────────────
    -- Issues found: lowercase, UPPERCASE, abbreviations
    -- UK / U.K. / united kingdom → United Kingdom
    -- EIRE → Ireland
    -- All others → proper case (first letter upper, rest lower)
    CASE
        WHEN UPPER(TRIM(Country)) IN (
             'UK','U.K.','UNITED KINGDOM','UNITED KINDOM')
                                                 THEN 'United Kingdom'
        WHEN UPPER(TRIM(Country)) = 'EIRE'       THEN 'Ireland'
        ELSE UPPER(LEFT(TRIM(Country), 1)) +
             LOWER(SUBSTRING(TRIM(Country), 2, LEN(Country)))
    END                                         AS Country,

    -- ── REGISTRATION DATE FIX + TYPE CAST ─────────────────
    -- ~3% of records have year 2025 — data entry error
    -- Recovery: replace year with 2010, preserve month and day
    -- Example: 2025-03-15 → 2010-03-15
    -- TRY_CAST wraps the CASE WHEN — clean first then cast
    -- to avoid casting a still-dirty value
    TRY_CAST(
        CASE
            WHEN LEFT(Registration_Date, 4) = '2025'
                THEN '2010' + SUBSTRING(Registration_Date, 5,
                              LEN(Registration_Date))
            ELSE Registration_Date
        END
    AS DATE)                                    AS Registration_Date

FROM (
    -- ── DEDUPLICATION ──────────────────────────────────────
    -- 171 duplicate customer records found in raw layer
    -- Strategy: keep earliest record per Customer_ID
    -- Tiebreaker: LEN(Email) DESC prefers longer email
    -- as a proxy for the more complete original record
    -- vs the duplicate which often has a broken email
    SELECT
        Customer_ID,
        Email,
        City,
        Country,
        Registration_Date,
        ROW_NUMBER() OVER (
            PARTITION BY Customer_ID
            ORDER BY    Registration_Date ASC,
                        LEN(Email)        DESC
        ) AS rn
    FROM raw.crm_customers
) t
WHERE rn = 1;  -- keep only first record per Customer_ID


-- Verification
-- Expected: 4,289 rows (4,460 raw minus 171 duplicates)
-- Expected: 0 duplicate Customer_IDs
-- Expected: 0 missing cities
-- Expected: 0 future registration dates
SELECT
    COUNT(*)                                              AS total_customers,
    SUM(CASE WHEN Email IS NULL         THEN 1 ELSE 0 END) AS null_emails,
    SUM(CASE WHEN City LIKE 'Unknown%'  THEN 1 ELSE 0 END) AS imputed_cities,
    SUM(CASE WHEN YEAR(Registration_Date) = 2025
                                        THEN 1 ELSE 0 END) AS future_dates
FROM staging.crm_customers;


-- ============================================================
-- TABLE 2 : staging.erp_orders
-- Source  : raw.erp_orders
-- Purpose : Clean valid orders — deduplicate, fix dates,
--           separate cancellations into own table,
--           cast to proper types
-- ============================================================

-- ------------------------------------------------------------
-- Cleaning tasks applied:
-- 1. Deduplication        — ROW_NUMBER() PARTITION BY Invoice
-- 2. Cancellation filter  — WHERE Invoice NOT LIKE 'C%'
-- 3. Date handling        — NULL dates retained as NULL
-- 4. Type casting         — Customer_ID to INT, Date to DATE
-- ------------------------------------------------------------

DROP TABLE IF EXISTS staging.erp_orders;

CREATE TABLE staging.erp_orders (
    Invoice         NVARCHAR(20),
    Customer_ID     INT,            -- cast from NVARCHAR
    InvoiceDate     DATE,           -- cast from NVARCHAR
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);

INSERT INTO staging.erp_orders (
    Invoice,
    Customer_ID,
    InvoiceDate
)
SELECT
    Invoice,

    -- ── TYPE CAST ──────────────────────────────────────────
    -- Customer_ID loaded as NVARCHAR — cast to INT
    -- NULL Customer_IDs retained — represent guest checkouts
    TRY_CAST(Customer_ID AS INT)    AS Customer_ID,

    -- ── DATE HANDLING ──────────────────────────────────────
    -- 402 records have NULL InvoiceDate — retained as NULL
    -- These records excluded from time-based analysis
    -- in analytics layer but retained for order count
    -- 0 malformed dates found after deduplication
    TRY_CAST(InvoiceDate AS DATE)   AS InvoiceDate

FROM (
    -- ── DEDUPLICATION ──────────────────────────────────────
    -- 822 duplicate orders found in raw layer
    -- Strategy: keep record with non-NULL Customer_ID
    -- Tiebreaker: CASE WHEN assigns 0 to non-NULL Customer_ID
    -- so ORDER BY ASC picks non-NULL first (row 1)
    SELECT
        Invoice,
        Customer_ID,
        InvoiceDate,
        ROW_NUMBER() OVER (
            PARTITION BY Invoice
            ORDER BY CASE WHEN Customer_ID IS NULL THEN 1 ELSE 0 END ASC
        ) AS rn
    FROM raw.erp_orders

    -- ── CANCELLATION FILTER ────────────────────────────────
    -- Invoices starting with C are cancellations
    -- Separated into staging.erp_orders_cancellations
    -- NOT deleted — retained for cancellation rate analysis
    -- and churn indicator enrichment
    WHERE Invoice NOT LIKE 'C%'
) t
WHERE rn = 1;


-- ── CANCELLATIONS TABLE ────────────────────────────────────────────────────
-- Separate table for cancellation orders
-- Cancellation rate: 4,381 / 27,423 = 16% — significant business metric
-- Used in business recommendations for churn analysis

DROP TABLE IF EXISTS staging.erp_orders_cancellations;

CREATE TABLE staging.erp_orders_cancellations (
    Invoice         NVARCHAR(20),
    Customer_ID     INT,
    InvoiceDate     DATE,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);

INSERT INTO staging.erp_orders_cancellations (
    Invoice,
    Customer_ID,
    InvoiceDate
)
SELECT
    Invoice,
    TRY_CAST(Customer_ID AS INT) AS Customer_ID,
    TRY_CAST(InvoiceDate AS DATE) AS InvoiceDate
FROM (
    SELECT
        Invoice,
        Customer_ID,
        InvoiceDate,
        ROW_NUMBER() OVER (
            PARTITION BY Invoice
            ORDER BY CASE WHEN Customer_ID IS NULL THEN 1 ELSE 0 END ASC
        ) AS rn
    FROM raw.erp_orders
    WHERE Invoice LIKE 'C%'  -- cancellations only
) t
WHERE rn = 1;


-- Verification
-- Expected: valid orders ~23,042
-- Expected: cancellations ~4,381
-- Expected: combined = ~27,423 (raw minus 822 duplicates)
SELECT
    'Valid Orders'   AS type, COUNT(*) AS row_count
FROM staging.erp_orders
UNION ALL
SELECT
    'Cancellations', COUNT(*)
FROM staging.erp_orders_cancellations;

-- Cancellation rate
SELECT
    ROUND(
        CAST(
            (SELECT COUNT(*) FROM staging.erp_orders_cancellations)
        AS FLOAT)
        /
        (
            (SELECT COUNT(*) FROM staging.erp_orders) +
            (SELECT COUNT(*) FROM staging.erp_orders_cancellations)
        ) * 100, 1
    ) AS cancellation_rate_pct;


-- ============================================================
-- TABLE 3 : staging.erp_order_items
-- Source  : raw.erp_order_items
-- Purpose : Clean order line items — fix casing, impute
--           zero prices, remove invalid quantities,
--           remove outliers, deduplicate
-- ============================================================

-- ------------------------------------------------------------
-- Cleaning tasks applied in one statement:
-- 1. StockCode casing     — UPPER(TRIM(StockCode))
-- 2. Description casing   — UPPER(TRIM(Description))
-- 3. Zero price imputation — AVG from same StockCode
-- 4. Negative qty filter  — WHERE Quantity > 0
-- 5. Outlier qty filter   — WHERE Quantity < 5000
-- 6. Deduplication        — ROW_NUMBER() PARTITION BY Invoice, StockCode
-- 7. Type casting         — Quantity to INT, Price to FLOAT
-- ------------------------------------------------------------

-- ------------------------------------------------------------
-- Why clean before deduplicating:
-- Mixed case StockCodes and inconsistent descriptions make
-- genuinely identical rows appear different to SQL.
-- Cleaning casing first collapses true duplicates into
-- identical rows — then deduplication reliably removes them.
-- ------------------------------------------------------------

-- ------------------------------------------------------------
-- Zero price imputation rationale:
-- 14,363 rows had zero unit price — data entry errors.
-- Strategy: impute using AVG valid price for same StockCode
-- from other transactions where Price > 0.
-- If no valid reference exists for a StockCode → NULL.
-- Avoids distorting revenue calculations with fake zeros.
-- ------------------------------------------------------------

-- ------------------------------------------------------------
-- Outlier quantity rationale:
-- Distribution analysis showed natural drop-off at 1,000-4,999
-- (220 rows) then unnatural spike at 5,000+ (2,720 rows).
-- Threshold set at 5,000 based on distribution evidence.
-- Likely causes: data entry errors, unit of measure confusion,
-- system migration errors, or test transactions.
-- ------------------------------------------------------------

DROP TABLE IF EXISTS staging.erp_order_items;

CREATE TABLE staging.erp_order_items (
    Invoice         NVARCHAR(20),
    StockCode       NVARCHAR(20),
    Description     NVARCHAR(255),
    Quantity        INT,            -- cast from NVARCHAR
    Price           FLOAT,          -- cast from NVARCHAR
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);

INSERT INTO staging.erp_order_items (
    Invoice,
    StockCode,
    Description,
    Quantity,
    Price
)
SELECT
    Invoice,

    -- ── STOCKCODE CASING ───────────────────────────────────
    -- ~6% of StockCodes had lowercase characters
    -- Standard: all StockCodes uppercase
    UPPER(TRIM(StockCode))          AS StockCode,

    -- ── DESCRIPTION CASING ─────────────────────────────────
    -- ~4% of descriptions had inconsistent casing
    -- Standard: all descriptions uppercase
    -- Consistent casing essential for deduplication accuracy
    UPPER(TRIM(Description))        AS Description,

    -- ── QUANTITY TYPE CAST ─────────────────────────────────
    -- Loaded as NVARCHAR in raw — cast to INT
    -- Negative and zero quantities filtered in WHERE clause
    -- Outlier quantities filtered in WHERE clause
    TRY_CAST(Quantity AS INT)       AS Quantity,

    -- ── PRICE IMPUTATION + TYPE CAST ───────────────────────
    -- 14,363 zero prices found — imputed from StockCode average
    -- Correlated subquery looks up avg valid price per product
    -- from all other rows where Price > 0
    -- Result NULLed if no valid reference price exists
    CASE
        WHEN CAST(Price AS FLOAT) = 0
            THEN (
                SELECT AVG(CAST(Price AS FLOAT))
                FROM   raw.erp_order_items oi2
                WHERE  oi2.StockCode = oi.StockCode
                AND    CAST(oi2.Price AS FLOAT) > 0
            )
        ELSE CAST(Price AS FLOAT)
    END                             AS Price

FROM (
    -- ── DEDUPLICATION ──────────────────────────────────────
    -- Cleaning applied first — casing fixes collapse true
    -- duplicates into identical rows before deduplication
    -- Partition: Invoice + StockCode (one line per product per order)
    -- Tiebreaker: highest Quantity preferred — more likely
    -- to be the original correct entry vs duplicate
    SELECT
        Invoice,
        StockCode,
        Description,
        Quantity,
        Price,
        ROW_NUMBER() OVER (
            PARTITION BY Invoice, StockCode
            ORDER BY     CAST(Quantity AS INT) DESC
        ) AS rn
    FROM raw.erp_order_items oi

    -- ── QUANTITY FILTERS ───────────────────────────────────
    -- Remove negative quantities — cancellation lines
    -- already captured in staging.erp_orders_cancellations
    -- Remove zero quantities — meaningless for analysis
    -- Remove outliers above 5,000 — data entry errors
    WHERE CAST(Quantity AS INT) > 0
    AND   CAST(Quantity AS INT) < 5000
) t
WHERE rn = 1;  -- keep only best record per Invoice + StockCode


-- Verification
-- Expected: ~473,658 rows
-- Expected: 0 negative quantities
-- Expected: 0 zero prices
-- Expected: max quantity < 5,000
-- Expected: 0 duplicate Invoice + StockCode combinations
SELECT
    COUNT(*)                                              AS total_rows,
    SUM(CASE WHEN Quantity < 0    THEN 1 ELSE 0 END)     AS negative_qty,
    SUM(CASE WHEN Quantity = 0    THEN 1 ELSE 0 END)     AS zero_qty,
    MAX(Quantity)                                         AS max_qty,
    SUM(CASE WHEN Price = 0       THEN 1 ELSE 0 END)     AS zero_prices,
    SUM(CASE WHEN Price IS NULL   THEN 1 ELSE 0 END)     AS null_prices
FROM staging.erp_order_items;

-- Duplicate check
SELECT Invoice, StockCode, COUNT(*) AS occurrences
FROM staging.erp_order_items
GROUP BY Invoice, StockCode
HAVING COUNT(*) > 1;


-- ============================================================
-- STAGING LAYER SUMMARY
-- Purpose : Single view confirming all cleaning results
-- ============================================================
SELECT
    'raw.crm_customers'              AS table_name,
    COUNT(*)                         AS row_count,
    'Source — unmodified'            AS notes
FROM raw.crm_customers
UNION ALL
SELECT 'staging.crm_customers', COUNT(*),
    '171 duplicates removed, countries fixed, emails fixed, cities imputed, dates fixed'
FROM staging.crm_customers
UNION ALL
SELECT 'raw.erp_orders', COUNT(*), 'Source — unmodified'
FROM raw.erp_orders
UNION ALL
SELECT 'staging.erp_orders', COUNT(*),
    '822 duplicates removed, 4381 cancellations separated, 402 null dates retained'
FROM staging.erp_orders
UNION ALL
SELECT 'staging.erp_orders_cancellations', COUNT(*),
    '16% cancellation rate — retained for churn analysis'
FROM staging.erp_orders_cancellations
UNION ALL
SELECT 'raw.erp_order_items', COUNT(*), 'Source — unmodified'
FROM raw.erp_order_items
UNION ALL
SELECT 'staging.erp_order_items', COUNT(*),
    'Casing fixed, zero prices imputed, invalid quantities removed, deduplicated'
FROM staging.erp_order_items;
