
### Layer 1 — RFM Scores

4,208 customers scored across three dimensions:

| Metric | Calculation | Range |
|--------|-------------|-------|
| Recency | Days from last order to Dec 24, 2010 | 1 — 353 days |
| Frequency | Count of distinct orders | 1 — 199 orders |
| Monetary | Sum of Quantity × Price | £0 — £293,594 |
-----------------------------------------------------------------------------------------------------------------

  --- Build analytics.rfm_scores Table
  
DROP TABLE IF EXISTS analytics.rfm_scores;
GO
SELECT 
    Customer_ID,
    Last_Order_Date,
    Recency_Days,
    Frequency,
    Monetary,
CASE 
    WHEN Recency_Days <= 30  THEN 5
    WHEN Recency_Days <= 60  THEN 4
    WHEN Recency_Days <= 90  THEN 3
    WHEN Recency_Days <= 180 THEN 2
    ELSE 1                           
END AS R_Score,
CASE 
    WHEN Frequency >= 10 THEN 5
    WHEN Frequency >= 6  THEN 4
    WHEN Frequency >= 4  THEN 3
    WHEN Frequency >= 2  THEN 2
    ELSE 1                       
END AS F_Score,
CASE 
    WHEN Monetary >= 2000 THEN 5
    WHEN Monetary >= 1000 THEN 4
    WHEN Monetary >= 500  THEN 3
    WHEN Monetary >= 200  THEN 2
    ELSE 1                        
END AS M_Score

INTO analytics.rfm_scores
FROM (
    SELECT 
    o.Customer_ID,
    MAX(o.InvoiceDate)                              AS Last_Order_Date,
    DATEDIFF(DAY, MAX(o.InvoiceDate), '2010-12-24') AS Recency_Days,
    COUNT(DISTINCT o.Invoice)                       AS Frequency,
    ROUND(SUM(i.Quantity * i.Price), 2)		        	AS Monetary
FROM staging.erp_orders o
JOIN staging.erp_order_items i ON o.Invoice = i.Invoice
WHERE o.Customer_ID IS NOT NULL
AND o.InvoiceDate IS NOT NULL
GROUP BY o.Customer_ID
) rfm;
