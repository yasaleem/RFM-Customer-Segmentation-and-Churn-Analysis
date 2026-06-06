
### Layer 2 — Customer Segments

6 segments defined based on RFM score profiles:

| Segment | Customers | Avg Recency | Avg Orders | Avg Spend |
|---------|-----------|-------------|------------|-----------|
| Champions | 289 | 13 days | 21 orders | £12,684 |
| Loyal Customers | 834 | 27 days | 6 orders | £2,395 |
| At Risk | 147 | 120 days | 5 orders | £2,336 |
| Lost | 32 | 223 days | 5 orders | £2,317 |
| Promising | 1,634 | 50 days | 2 orders | £874 |
| Hibernating | 1,272 | 203 days | 1 order | £545 |

**Note on segmentation approach:** Standard 11-segment RFM model was analyzed but consolidated to 6 segments
  due to dataset size (4,208 customers). Three segments were empty and one segment contained 37% of all 
  customers — making them not actionable. Segments were merged to ensure each group was large enough for 
  meaningful marketing action
  ----------------------------------------------------------------------------------------------------------

--- Build analytics.customer_segments Table
  
DROP TABLE IF EXISTS analytics.customer_segments;
SELECT 
    Customer_ID,
    Recency_Days,
    Frequency,
    Monetary,
    R_Score,
    F_Score,
    M_Score,
    CASE
        WHEN R_Score = 5  AND F_Score = 5        THEN 'Champions'
        WHEN R_Score >= 4 AND F_Score >= 3        THEN 'Loyal Customers'
        WHEN R_Score >= 3 AND F_Score >= 1        THEN 'Promising'
        WHEN R_Score >= 2 AND F_Score >= 3        THEN 'At Risk'
        WHEN R_Score <= 2 AND F_Score <= 2        THEN 'Hibernating'
        ELSE                                           'Lost'
    END AS Segment
INTO analytics.customer_segments
FROM analytics.rfm_scores;
