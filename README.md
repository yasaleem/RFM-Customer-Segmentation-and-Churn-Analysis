## <h1>1. Project Overview </h1>

BritGifts Online is a UK-based e-commerce retailer selling gifts and homeware products across Europe and beyond. This project builds a complete customer analytics pipeline — from raw transactional data to actionable customer segments and churn indicators — designed to help the marketing team make data-driven decisions about customer retention, loyalty, and lifetime value.

The project simulates a real-world analytics workflow:

- Data extracted from two source systems — an e-commerce platform and a CRM system
- Loaded into SQL Server as a central data warehouse
- Cleaned and transformed across raw, staging, and analytics layers
- Analyzed to answer four core business questions

## 2. Business Questions

This project was designed to answer four specific business questions:

 1 - Who are our highest value customers and what behaviors define them?
 2 - Which customer segments are at risk of churning and why?
 3 - What does the repeat purchase pattern look like and where does it break down?
 4 - What specific actions should the marketing team take for each customer segment?

The SQL queries utilized to inspect and perform quality checks can be found [here] (scripts/Data_quality_checks.sql)
The SQL queries utilized to clean, organize, and prepare data for the dashboard can be found here
Targeted SQL queries regarding various business questions can be found here

## 2. Data Structure & Initial Checks
BritGifts Online database structure as seen below consists of four tables: Customer, order, order_item, with a total row count of 500,989 records.

Diagram

## 🛡️ License

This project is licensed under the [MIT License](LICENSE). You are free to use, modify, and share this project with proper attribution.


