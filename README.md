## 1. Project Overview

BritGifts Online is a UK-based e-commerce retailer selling gifts and homeware products across Europe and beyond. This project builds a complete customer analytics pipeline — from raw transactional data to actionable customer segments and churn indicators — designed to help the marketing team make data-driven decisions about customer retention, loyalty, and lifetime value.

The project simulates a real-world analytics workflow:

- Data extracted from two source systems — an e-commerce platform and a CRM system
- Loaded into SQL Server as a central data warehouse
- Cleaned and transformed across raw, staging, and analytics layers
- Analyzed to answer four core business questions

- ## 2. Business Questions

This project was designed to answer four specific business questions:

| # | Question | Answered By |
|---|----------|-------------|
| 1 | Who are our highest value customers and what behaviors define them? | RFM Scores + Customer Segments |
| 2 | Which customer segments are at risk of churning and why? | Churn Indicators |
| 3 | What does the repeat purchase pattern look like and where does it break down? | Cohort Retention Analysis |
| 4 | What specific actions should the marketing team take for each customer segment? | Business Recommendations |


The SQL queries utilized to inspect and perform quality checks can be found [here]
The SQL queries utilized to clean, organize, and prepare data for the dashboard can be found here
Targeted SQL queries regarding various business questions can be found here



# Data Warehouse and Analytics Project

Welcome to the **Data Warehouse Project Analytics Project** repository!  
This project demonstrates a comprehensive data warehousing and analytics solution, from building a data warehouse to generating actionable insights. Designed as a portfolio project.


## 🚀 Project Requirements

### Building the Data Warehouse (Data Engineering)

#### Objective
Develop a modern data warehouse using SQL Server to consolidate sales data, enabling analytical reporting and informed decision-making.

#### Specifications
- **Data Sources**: Import data from two source systems (ERP and CRM) provided as CSV files.
- **Data Quality**: Cleanse and resolve data quality issues prior to analysis.
- **Integration**: Combine both sources into a single, user-friendly data model designed for analytical queries.
- **Scope**: Focus on the latest dataset only; historization of data is not required.
- **Documentation**: Provide clear documentation of the data model to support both business stakeholders and analytics teams.


### BI: Analytics & Reporting (Data Analysis)

#### Objective
Develop SQL-based analytics to deliver detailed insights into:
- **RFM Analysis**
    
These insights empower stakeholders with key business metrics, enabling strategic decision-making.

## 🛡️ License

This project is licensed under the [MIT License](LICENSE). You are free to use, modify, and share this project with proper attribution.


