### Layer 4 — Churn Indicators

Churn risk calculated using a relative indicator — Gap Ratio = Recency Days / Average Order Gap. This approach flags customers who are overdue relative to their own purchase pattern, not a fixed threshold.

| Churn Risk | Segment | Customers | Avg Recency | Avg Order Gap |
|------------|---------|-----------|-------------|---------------|
| High | Hibernating | 825 | 245 days | 14 days |
| High | Promising | 120 | 60 days | 19 days |
| High | At Risk | 88 | 129 days | 36 days |
| High | Lost | 32 | 223 days | 34 days |
| High | Loyal Customers | 23 | 39 days | 13 days |
| High | Champions | 4 | 21 days | 8 days |
| Medium | Hibernating | 447 | 127 days | 50 days |
| Medium | At Risk | 59 | 108 days | 79 days |
| Low | Promising | 1,459 | 48 days | 63 days |
| Low | Loyal Customers | 776 | 26 days | 58 days |
| Low | Champions | 278 | 12 days | 24 days |
---------------------------------------------------------------------------------------------------------------------

--- Build analytics.churn_indicators Table

DROP TABLE IF EXISTS analytics.churn_indicators
SELECT 
    r.Customer_ID,
    r.Recency_Days,
    r.Frequency,
    r.Monetary,
    r.R_Score,
    r.Segment,
    COALESCE(g.Avg_Order_Gap, 0)        AS Avg_Order_Gap,
    CASE 
        WHEN COALESCE(g.Avg_Order_Gap, 0) = 0 THEN NULL
        ELSE ROUND(CAST(r.Recency_Days AS FLOAT) / g.Avg_Order_Gap, 2)
    END                                  AS Gap_Ratio,
    CASE
        WHEN r.Recency_Days >= 180                                    THEN 'High'
        WHEN COALESCE(g.Avg_Order_Gap, 0) > 0 
             AND r.Recency_Days >= g.Avg_Order_Gap * 2                THEN 'High'
        WHEN r.Recency_Days >= 90                                     THEN 'Medium'
        WHEN COALESCE(g.Avg_Order_Gap, 0) > 0 
             AND r.Recency_Days >= g.Avg_Order_Gap * 1.5              THEN 'Medium'
        ELSE                                                               'Low'
    END                                  AS Churn_Risk
INTO analytics.churn_indicators
FROM analytics.customer_segments r
LEFT JOIN (
    SELECT 
        Customer_ID,
        AVG(Days_Between_Orders) AS Avg_Order_Gap
    FROM (
        SELECT 
            Customer_ID,
            InvoiceDate,
            DATEDIFF(DAY, 
                LAG(InvoiceDate) OVER (
                    PARTITION BY Customer_ID 
                    ORDER BY InvoiceDate
                ), 
                InvoiceDate
            ) AS Days_Between_Orders
        FROM staging.erp_orders
        WHERE Customer_ID IS NOT NULL
        AND InvoiceDate IS NOT NULL
    ) order_gaps
    WHERE Days_Between_Orders > 0
    GROUP BY Customer_ID
) g ON r.Customer_ID = g.Customer_ID;
