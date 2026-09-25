/*
========================================================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
========================================================================================================
Script Purpose: 
		This stored procedure performs the ETL (Extract, Transform, Load) process to populate the 'silver' 
		schema tables from the 'bronze' schema. 

Actions Performed: 
	    - Truncates Silver tables.
	    - Inserts tranformed and cleansed data from Bronze into Silver Tables.

Parameters:
	  None.
	  This stored procedure does not accept any parameters or return any values. 

Usage Eg.:
	  EXEC silver.load_silver;
========================================================================================================
  */

create or alter procedure silver.load_silver as
begin
	Declare @start_time Datetime, @end_time Datetime, @batch_start_time datetime, @batch_end_time datetime;
	Begin Try
		set @batch_start_time = GETDATE();
		print '==================================';
		print 'Loading Silver Layer';
		print '==================================';

		print '----------------------------------';
		print 'Loading CRM Tables';
		print '----------------------------------';


		set @start_time = Getdate();
		--1
		print '>> Truncating Table: Silver.crm_cust_info';
		truncate table Silver.crm_cust_info;
		print '>> Inserting Data Into: Silver.crm_cust_info';
		insert into Silver.crm_cust_info(
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_material_status,
			cst_gndr,
			cst_create_date
			)
			select 
				cst_id,
				cst_key,
				TRIM(cst_firstname) as cst_firstname,
				TRIM(cst_lastname) as cst_lastname,
				Case when UPPER(trim(cst_material_status)) = 'S' then 'Single'
					when UPPER(trim(cst_material_status)) = 'M' then 'Married'
					Else 'n/a'
				End cst_marital_status,
				Case when UPPER(trim(cst_gndr)) = 'F' then 'Female'
					when UPPER(trim(cst_gndr)) = 'M' then 'Male'
					Else 'n/a'
				End cst_gndr,
				cst_create_date
			from bronze.crm_cust_info
		set @end_time = Getdate();
		print '>> Load Duration: ' + Cast(Datediff(second, @start_time, @end_time) as Nvarchar) + 'seconds';
		print '----------------'

		set @start_time = Getdate();

		--2
		print '>> Truncating Table: Silver.crm_prd_info';
		truncate table Silver.crm_prd_info;
		print '>> Inserting Data Into: Silver.crm_prd_info';
		insert into Silver.crm_prd_info(
				prd_id,
				cat_id,
				prd_key,
				prd_nm,
				prd_cost,
				prd_line,
				prd_start_dt,
				prd_end_dt
			)

			select 
				prd_id,
				replace(SUBSTRING(prd_key,1,5),'-','_') as cat_id,
				SUBSTRING(prd_key,7,len(prd_key)) as prd_key,
				prd_nm,
				isnull(prd_cost,0) as prd_cost,
				case when upper(trim(prd_line)) = 'M' then 'Mountain'
					 when upper(trim(prd_line)) = 'R' then 'Road'
					 when upper(trim(prd_line)) = 'S' then 'Other Sales'
					 when upper(trim(prd_line)) = 'T' then 'Touring'
					 else 'n/a'
				end as prd_line,
				cast(prd_start_dt as date) as prd_start_dt,
				cast(LEAD(prd_start_dt) over (partition by prd_key order by prd_start_dt)-1 as date) as prd_end_dt
			from Bronze.crm_prd_info
		set @end_time = Getdate();
		print '>> Load Duration: ' + Cast(Datediff(second, @start_time, @end_time) as Nvarchar) + 'seconds';
		print '----------------'

		set @start_time = Getdate();

		--3
		print '>> Truncating Table: Silver.crm_sales_details';
		truncate table Silver.crm_sales_details;
		print '>> Inserting Data Into: Silver.crm_sales_details';

		insert into Silver.crm_sales_details (
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)

		select 
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			case when sls_order_dt = 0 or len(sls_order_dt) <> 8 then null
				 else cast(cast(sls_order_dt as varchar) as date)
			end as sls_order_dt,
			cast(cast(sls_ship_dt as varchar) as date) as sls_ship_dt,
			cast(cast(sls_due_dt as varchar) as date) as sls_due_dt,
			case when sls_sales is null or sls_sales <=0 or sls_sales <> sls_quantity * ABS(sls_price)
				then sls_quantity * abs(sls_price)
			else sls_sales
		end as sls_sales,
			sls_quantity,
			case when sls_price is null or sls_price <=0
				then sls_sales/nullif(sls_quantity,0)
			else sls_price
		end as sls_price
		from Bronze.crm_sales_details
		set @end_time = Getdate();
		print '>> Load Duration: ' + Cast(Datediff(second, @start_time, @end_time) as Nvarchar) + 'seconds';
		print '----------------'

		print '----------------------------------';
		print 'Loading ERP Tables';
		print '----------------------------------';

		set @start_time = Getdate();

		--4
		print '>> Truncating Table: Silver.erp_cust_az12';
		truncate table Silver.erp_cust_az12;
		print '>> Inserting Data Into: Silver.erp_cust_az12';

		insert into Silver.erp_cust_az12(
			cid,
			bdate,
			gen
		)

		select 
			case when cid like 'NAS%' then SUBSTRING(cid,4,len(cid))
				else cid
			end cid,
			case when bdate > GETDATE() then null
			else bdate
			end bdate,
			case when UPPER(trim(gen)) in ('F', 'FEMALE') then 'Female'
				 when UPPER(trim(gen)) in ('M', 'MALE') then 'Male'
				 else 'n/a'
			end gen
		from Bronze.erp_cust_az12
		set @end_time = Getdate();
		print '>> Load Duration: ' + Cast(Datediff(second, @start_time, @end_time) as Nvarchar) + 'seconds';
		print '----------------'

		set @start_time = Getdate();

		--5
		print '>> Truncating Table: Silver.erp_loc_a101';
		truncate table Silver.erp_loc_a101;
		print '>> Inserting Data Into: Silver.erp_loc_a101';

		insert into Silver.erp_loc_a101(
			cid,cntry
		)
		select 
		REPLACE(cid,'-','') cid,
		case when trim(cntry) = 'DE' then 'Germany'
			 when trim(cntry) = 'US' then 'United States'
			 when trim(cntry) = '' then 'n/a'
			 when trim(cntry) = null then 'n/a'
			 when trim(cntry) = 'USA' then 'United States'
			 else cntry
		end cntry
		from Bronze.erp_loc_a101
		set @end_time = Getdate();
		print '>> Load Duration: ' + Cast(Datediff(second, @start_time, @end_time) as Nvarchar) + 'seconds';
		print '----------------'

		set @start_time = Getdate();

		--6
		print '>> Truncating Table: Silver.erp_px_cat_g1v2';
		truncate table Silver.erp_px_cat_g1v2;
		print '>> Inserting Data Into: Silver.erp_px_cat_g1v2';
		insert into Silver.erp_px_cat_g1v2(
			id,
			cat,
			subcat,
			maintenance
		)
		select 
		id,
		cat,
		subcat,
		maintenance
		from Bronze.erp_px_cat_g1v2
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
	end
