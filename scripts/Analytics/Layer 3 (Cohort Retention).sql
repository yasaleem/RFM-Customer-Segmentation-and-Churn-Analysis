
Layer 3 — Cohort Retention

12 monthly cohorts tracked from January to December 2010:

| Cohort | Size | Month 1 Retention | Month 2 Retention | Month 3 Retention |
|--------|------|-------------------|-------------------|-------------------|
| January | 711 | 36.4% | 47.0% | 44.0% |
| February | 510 | 27.6% | 27.8% | 32.9% |
| March | 569 | 22.5% | 24.4% | 26.7% |
| April | 354 | 19.8% | 20.3% | 18.1% |
| May | 297 | 17.2% | 18.2% | 17.2% |
| June | 302 | 15.9% | 19.2% | 20.2% |
| July | 203 | 16.3% | 18.2% | 28.6% |
| August | 174 | 20.1% | 29.3% | 31.6% |
| September | 256 | 21.1% | 23.0% | 11.7% |
| October | 403 | 26.3% | 15.1% | — |
| November | 351 | 17.4% | — | — |
| December | 78 | — | — | — |
------------------------------------------------------------------------------------------------------------

--- build analytics.cohort_retention Table
  
DROP TABLE IF EXISTS analytics.cohort_retention
SELECT 
    Cohort_Month,
    Period_Number,
    Retained_Customers,
    Cohort_Size,
    ROUND(100.0 * Retained_Customers / Cohort_Size, 1) AS Retention_Rate
INTO analytics.cohort_retention
FROM (
SELECT 
    s3.Cohort_Month,
    s3.Period_Number,
    s3.Retained_Customers,
    cs.Cohort_Size
FROM (
SELECT 
	Cohort_Month,
    Period_Number,
    COUNT(DISTINCT Customer_ID) AS Retained_Customers
FROM (
SELECT 
    c.Customer_ID,
    c.Cohort_Month,
    DATEFROMPARTS(YEAR(o.InvoiceDate), MONTH(o.InvoiceDate), 1) AS Order_Month,
    DATEDIFF(MONTH, c.Cohort_Month, 
        DATEFROMPARTS(YEAR(o.InvoiceDate), MONTH(o.InvoiceDate), 1)) AS Period_Number
FROM (
    SELECT 
        Customer_ID,
        DATEFROMPARTS(YEAR(MIN(InvoiceDate)), MONTH(MIN(InvoiceDate)), 1) AS Cohort_Month
    FROM staging.erp_orders
    WHERE Customer_ID IS NOT NULL
    AND InvoiceDate IS NOT NULL
    GROUP BY Customer_ID
) c
JOIN staging.erp_orders o ON c.Customer_ID = o.Customer_ID
WHERE o.InvoiceDate IS NOT NULL) cohort_data
GROUP BY Cohort_Month,Period_Number
) s3
JOIN (
	   SELECT 
    Cohort_Month,
    COUNT(DISTINCT Customer_ID) AS Cohort_Size
FROM (
    -- your Step 2 query here
	SELECT 
    c.Customer_ID,
    c.Cohort_Month,
    DATEFROMPARTS(YEAR(o.InvoiceDate), MONTH(o.InvoiceDate), 1) AS Order_Month,
    DATEDIFF(MONTH, c.Cohort_Month, 
        DATEFROMPARTS(YEAR(o.InvoiceDate), MONTH(o.InvoiceDate), 1)) AS Period_Number
FROM (
    SELECT 
        Customer_ID,
        DATEFROMPARTS(YEAR(MIN(InvoiceDate)), MONTH(MIN(InvoiceDate)), 1) AS Cohort_Month
    FROM staging.erp_orders
    WHERE Customer_ID IS NOT NULL
    AND InvoiceDate IS NOT NULL
    GROUP BY Customer_ID
) c
JOIN staging.erp_orders o ON c.Customer_ID = o.Customer_ID
WHERE o.InvoiceDate IS NOT NULL
) cohort_data
WHERE Period_Number = 0
GROUP BY Cohort_Month
) cs ON s3.Cohort_Month = cs.Cohort_Month
) cohort_final;
