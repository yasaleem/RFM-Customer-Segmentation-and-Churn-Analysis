### Project Overview 

BritGifts Online is a UK-based e-commerce retailer selling gifts and homeware products across Europe and beyond. This project builds a complete customer analytics pipeline — from raw transactional data to actionable customer segments and churn indicators — designed to help the marketing team make data-driven decisions about customer retention, loyalty, and lifetime value.

An Interactive Power BI dashboard can be downloaded [here].\
The SQL queries utilized to inspect and perform quality checks can be found [here](www.google.com).\
The SQL queries utilized to clean, organize, and prepare data for the dashboard can be found [here](scripts/Data_cleaning.sql).\
Targeted SQL queries regarding various business questions can be found [here](scripts/Analytics).

### Business Questions

This project was designed to answer four specific business questions:

 1 - Who are our highest value customers and what behaviors define them?\
 2 - Which customer segments are at risk of churning and why?\
 3 - What does the repeat purchase pattern look like and where does it break down?\
 4 - What specific actions should the marketing team take for each customer segment?



### Data Structure & Initial Checks
BritGifts Online database structure as seen below consists of four tables: Customer, order, order_item, with a total row count of 500,989 records.

Entity Relationship Diagram can be found [here](datasets/Charts/erd_staging_layer.png)


### Key Findings

#### Finding 1 — Champions: 7% of customers, 45% of revenue
<img width="1657" height="1106" alt="finding1_champions_revenue" src="https://github.com/user-attachments/assets/186c2a43-4a03-4168-bc20-2f547119509c" />

> 289 Champions generate £3.67M — more than all other segments combined.
> Revenue is dangerously concentrated. Losing even 10% of Champions
> costs more than losing the entire Lost segment.

---

#### Finding 2 — (825) Hibernating customers were once frequent buyers
<img width="1820" height="1106" alt="finding2_hibernating_gap" src="https://github.com/user-attachments/assets/f89132a3-3be7-4c27-acc7-229aaac7c02f" />

> These customers used to buy every 14 days on average.
> They have now been silent for 245 days. Something specific caused
> them to leave — a win-back campaign has strong ROI potential.

---

### Finding 3 — 4 Champions already showing early churn signals
<img width="1669" height="1106" alt="finding3_champions_churn" src="https://github.com/user-attachments/assets/ef67217f-7968-4755-b282-c995f53ef2de" />

> 4 Champions are 2x overdue relative to their own normal purchase cycle.
> Each is worth £12,684 on average. These customers need personal
> outreach — not a mass email campaign.

---

### Finding 4 — January retains 2.3x better than June
<img width="1797" height="1106" alt="finding4_cohort_retention" src="https://github.com/user-attachments/assets/e09cfc1b-e83d-4e64-b798-bf8f670d8a07" />

> January cohort: 36.4% Month 1 retention.
> June cohort: 15.9% Month 1 retention.
> Same business, different customer quality — likely driven by
> acquisition channel or first product purchased.

---

### Finding 5 — 64% of customers lost in Month 1 — then retention stabilises
<img width="1813" height="1106" alt="finding5_month1_drop" src="https://github.com/user-attachments/assets/c720429b-5ca4-44f2-8d4a-1898f8fbaf41" />

> The sharpest drop happens between first and second purchase.
> Customers who survive Month 1 retain at 35-47% consistently.
> The second purchase is the most critical conversion moment.

---

### Business Recommendations
#### Champions — 289 customers — Avg spend £12,684
**Goal: Retain and reward**
- Personal outreach — not mass email
- Exclusive early access to new products
- Loyalty reward programme enrollment
- **Urgent:** 4 Champions showing early churn signals — immediate personal contact required

#### Loyal Customers — 834 customers — Avg spend £2,395
**Goal: Deepen relationship**
- Personalised product recommendations based on purchase history
- Reward milestone purchases — 10th order, anniversary
- Upsell within categories they already buy
- Weekly monitoring for 23 High churn risk Loyal customers

#### Promising — 1,634 customers — Avg spend £874
**Goal: Convert to second purchase**
- Second purchase nudge campaign within 30 days of first order
- Product recommendations based on first purchase category
- Time-limited free shipping offer to reduce friction
- Immediate intervention for 120 High churn risk Promising customers

#### At Risk — 147 customers — Avg spend £2,336
**Goal: Win back before fully lost**
- Personal win-back email acknowledging the gap — not a mass campaign
- Meaningful incentive — not a generic 10% discount
- Survey to understand why they stopped — valuable product feedback
- Act within 30 days — window is closing fast

#### Hibernating — 1,272 customers — Avg spend £545
**Goal: Selective re-engagement**
- One targeted win-back campaign for High risk group — 825 customers
- Focus on customers with 14-day avg order gap — proven frequent buyers
- Review cancellation data for product quality signals
- Accept that some will not return — do not over-invest

#### Lost — 32 customers — Avg spend £2,317
**Goal: Last attempt then accept**
- One final re-engagement campaign with a compelling offer
- If no response within 60 days — retire from active marketing
- Analyse order history for product or service failure patterns
- Use as a learning input — not a recovery target

### 🛡️ License

This project is licensed under the [MIT License](LICENSE). You are free to use, modify, and share this project with proper attribution.


