/*
========================================================================================================
Stored Procedure: Load Brronze Layer (Source -> Bronze)
========================================================================================================
Script Purpose: 
    This stored procedure loads data into the 'bronze' schema from external CSV files.
    It performs the following actions: 
    - Truncates the bronze tables before loading data. 
    - Uses the 'Bulk Insert' command to load data from CSV files to Bronze Tables.

Parameters:
  None.
This stored procedure does not accept any parameters or return any values. 

Usage Eg.:
    EXEC bronze.load_bronze;
========================================================================================================
  */
      
Create or alter procedure bronze.load_bronze as
Begin
	Declare @start_time Datetime, @end_time Datetime, @batch_start_time datetime, @batch_end_time datetime;
	Begin Try
		set @batch_start_time = GETDATE();
		print '==================================';
		print 'Loading Bronze Layer';
		print '==================================';

		print '----------------------------------';
		print 'Loading CRM Tables';
		print '----------------------------------';


		set @start_time = Getdate();
		print '>> Truncating Table: bronze.crm_cust_info';
		truncate table bronze.crm_cust_info;

		print '>>Inserting Data Into: bronze.crm_cust_info';
		Bulk insert bronze.crm_cust_info
		from 'C:\Users\Binoy\OneDrive\Desktop\SQL\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = Getdate();
		print '>> Load Duration: ' + Cast(Datediff(second, @start_time, @end_time) as Nvarchar) + 'seconds';
		print '----------------'

		set @start_time = Getdate();
		print '>> Truncating Table: bronze.crm_prd_info';
		truncate table bronze.crm_prd_info;

		print '>>Inserting Data Into:  bronze.crm_prd_info';
		Bulk insert bronze.crm_prd_info
		from 'C:\Users\Binoy\OneDrive\Desktop\SQL\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = Getdate();
		print '>> Load Duration: ' + Cast(Datediff(second, @start_time, @end_time) as Nvarchar) + 'seconds';
		print '----------------'

		set @start_time = Getdate();
		print '>> Truncating Table: bronze.crm_sales_details';
		truncate table bronze.crm_sales_details;

		print '>>Inserting Data Into: bronze.crm_sales_details';
		Bulk insert bronze.crm_sales_details
		from 'C:\Users\Binoy\OneDrive\Desktop\SQL\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = Getdate();
		print '>> Load Duration: ' + Cast(Datediff(second, @start_time, @end_time) as Nvarchar) + 'seconds';
		print '----------------'

		print '----------------------------------';
		print 'Loading ERP Tables';
		print '----------------------------------';

		set @start_time = Getdate();
		print '>> Truncating Table: bronze.erp_loc_a101';
		truncate table bronze.erp_loc_a101;

		print '>>Inserting Data Into: bronze.erp_loc_a101';
		Bulk insert bronze.erp_loc_a101
		from 'C:\Users\Binoy\OneDrive\Desktop\SQL\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = Getdate();
		print '>> Load Duration: ' + Cast(Datediff(second, @start_time, @end_time) as Nvarchar) + 'seconds';
		print '----------------'

		set @start_time = Getdate();
		print '>> Truncating Table: bronze.erp_cust_az12';
		truncate table bronze.erp_cust_az12;

		print '>>Inserting Data Into:bronze.erp_cust_az12';
		Bulk insert bronze.erp_cust_az12
		from 'C:\Users\Binoy\OneDrive\Desktop\SQL\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = Getdate();
		print '>> Load Duration: ' + Cast(Datediff(second, @start_time, @end_time) as Nvarchar) + 'seconds';
		print '----------------'

		set @start_time = Getdate();
		print '>> Truncating Table: bronze.erp_px_cat_g1v2';
		truncate table bronze.erp_px_cat_g1v2;

		print '>>Inserting Data Into: bronze.erp_px_cat_g1v2';
		Bulk insert bronze.erp_px_cat_g1v2
		from 'C:\Users\Binoy\OneDrive\Desktop\SQL\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = Getdate();
		print '>> Load Duration: ' + Cast(Datediff(second, @start_time, @end_time) as Nvarchar) + 'seconds';
		print '----------------'

		set @batch_end_time = GETDATE();
		print '========================================='
		print 'Loading Bronze Layer is Completed';
		print ' - Total Load Duration: ' + Cast(datediff(second, @batch_start_time, @batch_end_time) as nvarchar) + 'seconds';
		print '========================================='
		End try
		Begin catch
			Print '=============================================='
			Print 'Error Occured during Bronze Layer Load'
			Print 'Error Message' + Error_message();
			Print 'Error Message' + Cast(Error_number() as nvarchar);
			Print 'Error Message' + Cast(Error_state() as nvarchar);
			Print '=============================================='
		End catch
End
