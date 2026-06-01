=================================================================================================
DDL Script: Create the staging Tables
  This script create tables in the 'staging' schema, dropping existing tables if they already exist.
  Run this script to re-define the DDL of the 'staging' Tables.
=================================================================================================

-- staging CRM customers table
IF OBJECT_ID('staging.crm_system', 'U') is NOT NULL
    DROP TABLE staging.crm_system
CREATE TABLE staging.crm_customers (
    Customer_ID     INT,
    Email           NVARCHAR(255),
    City            NVARCHAR(100),
    Country         NVARCHAR(100),
    Registration_Date DATE,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);

-- staging Valid orders table
IF OBJECT_ID('staging.orders', 'U') is NOT NULL
    DROP TABLE staging.orders
CREATE TABLE staging.erp_orders (
    Invoice         NVARCHAR(20),
    Customer_ID     INT,
    InvoiceDate     DATE,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- staging Cancelation Order table
IF OBJECT_ID('staging.erp_orders_cancellations', 'U') is NOT NULL
    DROP TABLE staging.erp_orders_cancellations
CREATE TABLE staging.erp_orders_cancellations (
    Invoice         NVARCHAR(20),
    Customer_ID     INT,
    InvoiceDate     DATE,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
  
  
-- staging order items 
IF OBJECT_ID('staging.erp_order_items', 'U') is NOT NULL
    DROP TABLE staging.erp_order_items
CREATE TABLE staging.erp_order_items (
    Invoice         NVARCHAR(20),
    StockCode       NVARCHAR(20),
    Description     NVARCHAR(255),
    Quantity        INT,
    Price           FLOAT,
  dwh_create_date DATETIME2 DEFAULT GETDATE()
);
