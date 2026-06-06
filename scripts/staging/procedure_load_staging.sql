============================================================================================================
Stored procedure: Load Staging Layer (Raw -> Staging)
============================================================================================================
Purpose:
  This Procedure performs the ETL (Extract, Transform, Load) process to populate the 'staging' schema tables
  from the 'raw' schema.
Actions Performed:
  - Truncate Staging tables
  - Inserts transformed and cleansed data from Raw into Staging tables.

Parameters:
  None.
  This stored procedure does not accept any parameters or return any values.

Usage Example:
  EXEC Staging.load_staging;
============================================================================================================

CREATE OR ALTER PROCEDURE staging.load_staging as
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '====================================================';
        PRINT 'Loading Staging Layer';
        PRINT '====================================================';

        PRINT '----------------------------------------------------';
        PRINT 'Loading CRM Table';
        PRINT '----------------------------------------------------';

	--- Loading staging.crm_customers
	SET @start_time = GETDATE();
	PRINT '>> Truncating Table: staging.crm_customers'
	TRUNCATE TABLE staging.crm_customers;

	PRINT '>> Inserting Data Into: staging.crm_customers'
	INSERT INTO staging.crm_customers (
	Customer_ID,
	Email,
	City,
	Country,
	Registration_Date)

	SELECT 
	TRY_CAST (Customer_ID AS INT),
	CASE  WHEN TRIM(Email) NOT LIKE '%@%'   THEN NULL
		  WHEN TRIM(Email) LIKE '%@@%'      THEN REPLACE(TRIM(Email), '@@', '@')
		  ELSE TRIM(Email)
	END AS Email,
	CASE  WHEN City IS NULL OR City = '' 
		  THEN 'Unknown - ' + Country
		  ELSE City
	END AS City,
	CASE WHEN UPPER(TRIM(Country)) IN ('UK', 'U.K.', 'UNITED KINGDOM', 'UNITED KINDOM') THEN 'United Kingdom'
		 WHEN UPPER(TRIM(Country)) = 'EIRE' THEN 'Ireland'
		 ELSE UPPER(LEFT(TRIM(Country), 1)) + LOWER(SUBSTRING(TRIM(Country), 2, LEN(Country)))
	END Country,
	TRY_CAST(CASE  WHEN LEFT(Registration_Date, 4) = '2025'
		  THEN '2010' + SUBSTRING(Registration_Date, 5, LEN(Registration_Date))
		  ELSE Registration_Date 
	END AS DATE) AS Registration_Date 
	From (
		   SELECT *,
		   ROW_NUMBER() OVER (PARTITION BY Customer_ID ORDER BY Registration_Date ASC) AS Flag_last
		   FROM raw.crm_customers)t
		   Where Flag_last = 1

		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '----------------';

		PRINT '----------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '----------------------------------------------------';

	--- Loading staging.erp_orders
	 SET @start_time = GETDATE();
	 PRINT '>> Truncating Table: staging.erp_orders'
	 TRUNCATE TABLE staging.erp_orders;

	PRINT '>> Inserting Data Into: staging.erp_orders'
	INSERT INTO staging.erp_orders (
		Invoice,
		Customer_ID,
		InvoiceDate)

	Select Invoice,TRY_CAST (Customer_ID AS INT), TRY_CAST (InvoiceDate AS DATE)
	from (
	SELECT *,
		CASE WHEN Invoice NOT LIKE 'C%' THEN 1 ELSE 0 END
		AS valid_orders
	FROM (
	SELECT *,
	ROW_NUMBER() OVER (
		PARTITION BY Invoice
		ORDER BY CASE WHEN Customer_ID IS NULL THEN 1 ELSE 0 END ) AS Flag_last
	FROM raw.erp_orders
	)t
	WHERE Flag_last = 1 )t
	where valid_orders = 1

	SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '----------------';

		PRINT '----------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '----------------------------------------------------';


	-- Loading staging.erp_order_items
	 SET @start_time = GETDATE();
	 PRINT '>> Truncating Table: staging.erp_order_items'
	 TRUNCATE TABLE staging.erp_order_items;

	PRINT '>> Inserting Data Into: staging.erp_order_items'
	INSERT INTO staging.erp_order_items (
		Invoice,
		StockCode,
		Description,
		Quantity,
		Price)

	SELECT Invoice, StockCode, Description,TRY_CAST( Quantity AS INT), TRY_CAST(Price AS FLOAT)
		FROM(
		SELECT 
			Invoice,
			UPPER(TRIM(StockCode))   AS StockCode,
			UPPER(TRIM(Description)) AS Description,
			Quantity,
			CASE 
				WHEN CAST(Price AS FLOAT) = 0 
					THEN (
						SELECT AVG(CAST(Price AS FLOAT))
						FROM raw.erp_order_items oi2
						WHERE oi2.StockCode = oi.StockCode
						AND CAST(oi2.Price AS FLOAT) > 0
					)
				ELSE CAST(Price AS FLOAT)
			END AS Price,
			ROW_NUMBER() OVER (PARTITION BY Invoice, StockCode ORDER BY Quantity desc) AS flg
			FROM raw.erp_order_items oi
			WHERE CAST(Quantity AS int) > 0 AND CAST(Quantity AS INT) < 5000)t
		WHERE flg = 1;
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '----------------';

		 SET @batch_end_time = GETDATE();
        PRINT '===================================='
        PRINT 'Loading Staging Layer is Completed';
        PRINT '    - Total Load Duration: ' + CAST(DATEDIFF(SECOND,@batch_start_time,@batch_end_time) AS NVARCHAR) +' seconds';
        PRINT '===================================='
    END TRY
    BEGIN CATCH
        PRINT '========================================'
        PRINT 'ERROR OCCURED DURING LOADIND Staging LAYER'
        PRINT 'Error Message' + ERROR_MESSAGE();
        PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '========================================'
    END CATCH   
END
