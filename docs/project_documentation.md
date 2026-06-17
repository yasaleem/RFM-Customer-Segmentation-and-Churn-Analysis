# RFM Customer Segmentation and Churn Analysis
### BritGifts Online — E-Commerce Customer Analytics Project

**Author:** Yassir Saleem — Customer Analytics Analyst  
**Date:** December 2010  
**Dataset:** UK Online Retail II — BritGifts Online Transactional Data  
**Tools:** SQL Server, Python, Excel  

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Business Questions](#2-business-questions)
3. [Data Architecture](#3-data-architecture)
4. [Data Sources](#4-data-sources)
5. [Data Quality Issues](#5-data-quality-issues)
6. [Data Cleaning Decisions](#6-data-cleaning-decisions)
7. [Analytics Layer](#7-analytics-layer)
8. [Key Findings](#8-key-findings)
9. [Business Recommendations](#9-business-recommendations)
10. [Limitations and Next Steps](#10-limitations-and-next-steps)

---

## 1. Project Overview

BritGifts Online is a UK-based e-commerce retailer selling gifts and homeware products across Europe and beyond. This project builds a complete customer analytics pipeline — from raw transactional data to actionable customer segments and churn indicators — designed to help the marketing team make data-driven decisions about customer retention, loyalty, and lifetime value.

The project simulates a real-world analytics workflow:

- Data extracted from two source systems — an e-commerce platform and a CRM system
- Loaded into SQL Server as a central data warehouse
- Cleaned and transformed across raw, staging, and analytics layers
- Analyzed to answer four core business questions

---

## 2. Business Questions

This project was designed to answer four specific business questions:

| # | Question | Answered By |
|---|----------|-------------|
| 1 | Who are our highest value customers and what behaviors define them? | RFM Scores + Customer Segments |
| 2 | Which customer segments are at risk of churning and why? | Churn Indicators |
| 3 | What does the repeat purchase pattern look like and where does it break down? | Cohort Retention Analysis |
| 4 | What specific actions should the marketing team take for each customer segment? | Business Recommendations |

---

## 3. Data Architecture

The project follows a three-layer data warehouse architecture — standard practice in modern analytics environments:

```
Source Systems
    ├── E-Commerce Platform (Shopify simulation)
    └── CRM System

        ↓ Extract and Load

Raw Layer (SQL Server)
    ├── raw.crm_customers        — 4,460 rows
    ├── raw.erp_orders           — 28,245 rows
    └── raw.erp_order_items      — 533,168 rows

        ↓ Clean and Transform

Staging Layer (SQL Server)
    ├── staging.crm_customers        — 4,289 rows
    ├── staging.erp_orders           — 23,042 rows
    ├── staging.erp_orders_cancellations — 4,381 rows
    └── staging.erp_order_items      — 473,658 rows

        ↓ Analyze

Analytics Layer (SQL Server)
    ├── analytics.rfm_scores         — 4,208 customers scored
    ├── analytics.customer_segments  — 6 segments defined
    ├── analytics.cohort_retention   — 12 monthly cohorts tracked
    └── analytics.churn_indicators   — churn risk per customer
```

**Why three layers:**

- **Raw layer** — exact copy of source data, never modified, permanent audit trail
- **Staging layer** — cleaned, deduplicated, and typed data ready for analysis
- **Analytics layer** — purpose-built tables answering specific business questions

---

## 4. Data Sources

Data was extracted from two simulated source systems representing a real e-commerce environment:

### Source 1 — E-Commerce Platform (Shopify)
Transactional data covering all orders and product line items.

| Column | Description |
|--------|-------------|
| Invoice | Order identifier — prefix C indicates cancellation |
| StockCode | Product identifier |
| Description | Product name |
| Quantity | Units ordered |
| InvoiceDate | Date and time of transaction |
| Price | Unit price in GBP |

### Source 2 — CRM System
Customer master data containing profiles and geographic information.

| Column | Description |
|--------|-------------|
| Customer ID | Unique customer identifier — Primary Key |
| Email | Customer email address |
| City | Customer city |
| Country | Customer country |
| Registration Date | Date customer first registered |

**Relational Model:**

```
CRM_Customers.Customer_ID (Primary Key)
        ↑
Orders.Customer_ID (Foreign Key)
        ↓
Order_Items.Invoice (linked via Invoice ID)
```

**Date Range:** January 2010 — December 2010  
**Geography:** UK primary market plus 20+ international markets  
**Reference Date for RFM:** December 24, 2010 (one day after last order)

---

## 5. Data Quality Issues

The following data quality issues were identified in the raw layer and resolved in staging:

### CRM Customers

| Issue | Scale | Example |
|-------|-------|---------|
| Duplicate customer records | 171 duplicates | Same Customer ID with slight variations |
| Mixed case country names | ~13% of records | "united kingdom", "GERMANY" |
| Inconsistent UK naming | ~6% of UK records | "UK", "U.K.", "united kingdom" |
| Broken email formats | ~6% of records | Missing @, double @@, leading spaces |
| Missing city values | ~7% of records | NULL city column |
| Future registration dates | ~3% of records | Year 2025 instead of 2010 |

### Orders

| Issue | Scale | Example |
|-------|-------|---------|
| Duplicate orders | 822 duplicates | Same Invoice appearing twice |
| Malformed date strings | ~2% of records | Date format errors |
| NULL invoice dates | 402 records | Missing transaction date |
| Cancellations mixed with valid orders | 4,381 records | Invoice starting with C |

### Order Items

| Issue | Scale | Example |
|-------|-------|---------|
| Mixed case StockCode | ~6% of records | "22139a" instead of "22139A" |
| Inconsistent description casing | ~4% of records | Title case vs uppercase |
| Zero unit prices | 14,363 records | Data entry errors |
| Negative quantities | Present | Cancellation lines mixed in |
| Outlier quantities | 2,720 records | 5,000-99,999 units — data entry errors |
| Duplicate line items | ~2% of records | Same Invoice and StockCode twice |

---

## 6. Data Cleaning Decisions

Every cleaning decision was intentional and documented. Key decisions and rationale:

### Decision 1 — Raw layer loads everything as NVARCHAR
All columns loaded as text in the raw layer to prevent SQL Server rejecting dirty rows during load. Type casting applied only after cleaning in staging.

### Decision 2 — Deduplication using ROW_NUMBER()
Duplicates removed using ROW_NUMBER() PARTITION BY the primary key, ordering by Registration_Date ASC and LEN(Email) DESC to prefer the most complete record as tiebreaker.

### Decision 3 — Country standardization using CASE WHEN + INITCAP
UPPER(TRIM()) applied first to normalize casing, then CASE WHEN mapped known variations — UK, U.K., EIRE — to standard names. All other countries converted to proper case.

### Decision 4 — Email fixing strategy
Fixable issues — leading spaces, double @@ — corrected using TRIM and REPLACE. Unfixable issues — missing @ symbol — nulled out rather than dropped. Records retained for non-email analysis.

### Decision 5 — Missing cities imputed as Unknown - Country
NULL cities replaced with "Unknown - [Country]" to preserve country context for geographic analysis while honestly flagging the gap.

### Decision 6 — Future registration dates recovered
Dates with year 2025 recovered by replacing year with 2010 while preserving month and day. Root cause: data entry error replacing year digit.

### Decision 7 — Cancellations separated not deleted
4,381 cancellation orders moved to staging.erp_orders_cancellations rather than deleted. Retained for cancellation rate analysis and churn indicator enrichment.

**Cancellation rate: 16%** — a significant business metric flagged for recommendations.

### Decision 8 — Zero prices imputed from StockCode average
14,363 zero price rows imputed using average valid price for the same StockCode from other transactions. 410 rows nulled out where no valid reference price existed for that product.

### Decision 9 — Outlier quantities removed above 5,000
Distribution analysis showed a natural drop-off at 1,000-4,999 range (220 rows) followed by an unnatural spike at 5,000+ (2,720 rows). Threshold set at 5,000 based on distribution evidence not arbitrary cutoff.

### Decision 10 — Manual RFM bins over NTILE
Initial scoring using NTILE(5) produced misleading results — customers with 170 days recency and only one purchase were classified as Champions due to heavily skewed frequency distribution (34% of customers bought only once).

Manual bins defined based on actual data distribution:

```sql
-- Recency
<= 30 days  = 5    -- bought within last month
<= 60 days  = 4    -- bought within last 2 months
<= 90 days  = 3    -- bought within last 3 months
<= 180 days = 2    -- bought within last 6 months
> 180 days  = 1    -- bought more than 6 months ago

-- Frequency
>= 10 orders = 5   -- very loyal
>= 6 orders  = 4   -- regular buyer
>= 4 orders  = 3   -- occasional buyer
>= 2 orders  = 2   -- returned once
= 1 order    = 1   -- one time buyer

-- Monetary
>= £2,000 = 5      -- high spender
>= £1,000 = 4      -- above average
>= £500   = 3      -- average
>= £200   = 2      -- below average
< £200    = 1      -- low spender
```

---

## 7. Analytics Layer

### Layer 1 — RFM Scores

4,208 customers scored across three dimensions:

| Metric | Calculation | Range |
|--------|-------------|-------|
| Recency | Days from last order to Dec 24, 2010 | 1 — 353 days |
| Frequency | Count of distinct orders | 1 — 199 orders |
| Monetary | Sum of Quantity × Price | £0 — £293,594 |

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

**Note on segmentation approach:** Standard 11-segment RFM model was analyzed but consolidated to 6 segments due to dataset size (4,208 customers). Three segments were empty and one segment contained 37% of all customers — making them not actionable. Segments were merged to ensure each group was large enough for meaningful marketing action.

### Layer 3 — Cohort Retention

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

---

## 8. Key Findings

### Finding 1 — First month retention is the critical break point
Across all cohorts the sharpest drop in retention happens between Period 0 and Period 1. January cohort dropped from 711 to 259 customers — a 64% loss in one month. This is where the business loses most of its customers.

### Finding 2 — January cohort significantly outperforms all others
January retention at 36.4% in Month 1 is more than double June's 15.9%. This suggests customers acquired in January have fundamentally different loyalty characteristics. Root cause unknown from this dataset — acquisition channel data recommended for further investigation.

### Finding 3 — 825 Hibernating customers were once frequent buyers
Average order gap of 14 days for High risk Hibernating customers proves these were active, engaged buyers — not one-time purchasers. They stopped buying abruptly. Win-back campaigns have high ROI potential given their proven purchase history.

### Finding 4 — 4 Champions showing early churn signals
Average order gap of 8 days but 21 days since last purchase — already 2.6x overdue. Losing one Champion costs as much as losing 23 Hibernating customers in revenue terms. Immediate personal outreach warranted.

### Finding 5 — 39% of customers are Promising — the biggest opportunity
1,634 customers bought recently but only twice on average. Converting even 20% to Loyal Customers would add 326 repeat buyers. The second purchase is the critical conversion moment.

### Finding 6 — 16% cancellation rate is a hidden retention signal
4,381 cancellations out of 27,423 total orders. High cancellation rates correlate with customer dissatisfaction — a leading indicator of churn worth monitoring per product category.

---

## 9. Business Recommendations

### Champions (289 customers — Avg spend £12,684)
**Goal: Retain and reward**
- Exclusive early access to new products
- Personal thank you outreach — not mass email
- Loyalty reward program enrollment
- Immediate personal contact for the 4 showing churn signals

### Loyal Customers (834 customers — Avg spend £2,395)
**Goal: Deepen relationship**
- Regular personalized product recommendations based on purchase history
- Reward milestone purchases — 10th order, anniversary
- Upsell to higher value products in categories they already buy
- Monitor the 23 High churn risk Loyal customers weekly

### Promising (1,634 customers — Avg spend £874)
**Goal: Convert to second and third purchase**
- Second purchase nudge campaign — well timed, helpful not desperate
- Product recommendations based on first purchase category
- Time-limited incentive for repeat purchase within 30 days
- Immediate intervention for 120 High churn risk Promising customers

### At Risk (147 customers — Avg spend £2,336)
**Goal: Win back before fully lost**
- Personal win-back email acknowledging the gap
- Meaningful incentive — not a generic discount
- Survey to understand why they stopped — valuable product feedback
- Act within 30 days — these customers are close to becoming Lost

### Hibernating (1,272 customers — Avg spend £545)
**Goal: Selective re-engagement**
- One targeted win-back campaign for High churn risk group (825 customers)
- Focus on customers with proven frequent purchase history — avg gap 14 days
- Accept that some will not return — do not over-invest in truly lost customers
- Use cancellation data to identify if product issues drove their departure

### Lost (32 customers — Avg spend £2,317)
**Goal: Last attempt then accept**
- One final re-engagement campaign with a compelling offer
- If no response within 60 days — retire from active marketing
- Analyze their order history for product or service failure patterns
- Use as a learning input not a recovery target

---

## 10. Limitations and Next Steps

### Current Limitations

**No acquisition channel data:**
Cannot determine whether January cohort outperforms June due to acquisition source differences. Enriching with marketing channel data would answer this question.

**Single year dataset:**
Analysis covers 2010 only. Multi-year data would reveal seasonal patterns, year-over-year retention trends, and true long-term customer lifetime value.

**No product category data:**
StockCode and Description available but no formal category hierarchy. Product category analysis would strengthen first-purchase-to-loyalty correlation findings.

**Geographic analysis limited:**
Country data available but city data partially imputed. Cannot perform reliable city-level analysis.

### Recommended Next Steps

1. **Enrich with acquisition channel data** — connect marketing source to cohort retention to identify highest ROI acquisition channels
2. **Build product category hierarchy** — classify products into categories to analyze which first purchases drive highest retention
3. **Extend to multi-year data** — track whether 2010 cohorts continued purchasing in 2011
4. **Build LTV model** — predict future customer value using purchase frequency and monetary patterns
5. **Automate churn alerts** — schedule weekly churn indicator refresh to flag at-risk customers in real time
6. **A/B test win-back campaigns** — measure actual re-engagement rates against churn indicator predictions

---

*Project built by Yassir Saleem — Customer Analytics Analyst*  
*Tools: SQL Server · Python · Excel*  
*Dataset: UK Online Retail II (UCI Machine Learning Repository)*
