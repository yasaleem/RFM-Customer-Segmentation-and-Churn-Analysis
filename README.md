### Project Overview 

BritGifts Online is a UK-based e-commerce retailer selling gifts and homeware products across Europe and beyond. This project builds a complete customer analytics pipeline — from raw transactional data to actionable customer segments and churn indicators — designed to help the marketing team make data-driven decisions about customer retention, loyalty, and lifetime value.

An Interactive Power BI dashboard can found [here](docs/RFM_powerbi.md).\
The SQL queries utilized to inspect and perform quality checks can be found [here](scripts/Data_quality_checks.sql).\
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

<img width="2556" height="1653" alt="erd_staging_layer" src="https://github.com/user-attachments/assets/5b0cc30d-2bd1-49c1-be0f-c5b0d058edf5" />



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

#### Recommendation 1 — Protect Champions Before Anything Else
> **Linked to Finding 1 (revenue concentration) + Finding 3 (early churn signals)**

289 Champions generate £3.67M — 45% of total revenue. 4 are already
2x overdue on their purchase cycle. Immediate personal contact required.
Target: Zero Champions moving to At Risk per quarter.

---

#### Recommendation 2 — Win Back Hibernating Before They Are Truly Lost
> **Linked to Finding 2 — 825 once bought every 14 days**

825 High risk Hibernating customers are proven frequent buyers.
One targeted campaign focused on this group. Reference previous
purchases — not a generic message.
Target: 15% response = £67K recovered revenue.

---

#### Recommendation 3 — The Second Purchase Is the Critical Moment
> **Linked to Finding 5 — 64% lost in Month 1**

Trigger second purchase nudge within 7 days of first order.
Product recommendation not discount. Track second purchase
conversion as primary KPI.
Target: Increase Month 1 retention from 21.9% to 28%.

---

#### Recommendation 4 — Acquire More January-Like Customers
> **Linked to Finding 4 — January retains 2.3x better than June**

Analyse what January buyers purchased first. Identify acquisition
channels active in January. Share cohort findings with marketing
to shift budget toward quality acquisition.
Target: Improve average Month 1 retention across all cohorts.

---

#### Recommendation 5 — At Risk Needs Urgent Action Not Routine Outreach
> **Linked to Finding 1 — At Risk spend matches Loyal Customers**

147 customers, £2,336 avg spend, 120 days silent. Personal email
within 7 days. Acknowledge the gap. Act within 30 days or move
to final campaign.
Target: 25% win-back = £86K recovered revenue.

---

### Recommendation 6 — Loyal Customers Are Your Growth Engine
> **Linked to Finding 1 + Finding 5**

834 customers, 6 avg orders, proven retention. Monthly personalised
recommendations. Clear upgrade path to Champions.
Target: 10% upgrade to Champions = £1M additional revenue.

### 🛡️ License

This project is licensed under the [MIT License](LICENSE). You are free to use, modify, and share this project with proper attribution.


