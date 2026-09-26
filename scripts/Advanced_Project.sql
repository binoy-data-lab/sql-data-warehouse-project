



--TRENDS: Changes Over Time
select 
	year(order_date) as order_year,
	month(order_date) as order_month,
	SUM(sales_amount) as total_sales,
	count(distinct customer_key) as total_customers,
	sum(quantity) as total_quantity
from gold.fact_sales
where order_date is not null
group by year(order_date), MONTH(order_date)
order by year(order_date), MONTH(order_date)

--

select 
	datetrunc(month,order_date) as order_date,
	SUM(sales_amount) as total_sales,
	count(distinct customer_key) as total_customers,
	sum(quantity) as total_quantity
from gold.fact_sales
where order_date is not null
group by datetrunc(month,order_date)
order by datetrunc(month,order_date)


--CUMULATIVE ANALYSIS

--Calculate the total sales per month and the running total of sales over time.

select
order_date,
total_sales,
sum(total_sales) over (partition by order_date order by order_date) as running_total_sales
from(
	select 
	DATETRUNC(month, order_date) as order_date,
	sum(sales_amount) as total_sales
	from gold.fact_sales
	where order_date is not null
	group by DATETRUNC(month, order_date)
)t

--Moving Average

select
order_date,
total_sales,
sum(total_sales) over (partition by order_date order by order_date) as running_total_sales,
avg(avg_price) over (partition by order_date order by order_date) as moving_average_price

from(
	select 
	DATETRUNC(month, order_date) as order_date,
	sum(sales_amount) as total_sales,
	avg(price) as avg_price
	from gold.fact_sales
	where order_date is not null
	group by DATETRUNC(month, order_date)
)t


--PERFORMANCE ANALYSIS

--Analyze the yearly performance of the products by comparing their sales to 
--both the average sales performance of the product and the previous year's sales. 

with yearly_product_sales as 
	(select 
	YEAR(f.order_date) as order_year,
	p.product_name,
	sum(f.sales_amount) as current_sales
	from gold.fact_sales f
	left join gold.dim_products p
	on f.product_key = p.product_key
	where order_date is not null
	group by 
		YEAR(f.order_date),
		p.product_name
	)

	select
	order_year,
	product_name,
	current_sales,
	avg(current_sales) over (partition by product_name) as avg_sales,
	current_sales - avg(current_sales) over (partition by product_name) as diff_avg,
	case when current_sales - avg(current_sales) over (partition by product_name) > 0 then 'Above Avg'
		 when current_sales - avg(current_sales) over (partition by product_name) < 0 then 'Below Avg'
		 Else 'Avg'
	end avg_change,

	--Year-Over-Year Analysis

	LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) py_sales,
	current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_py,
	CASE WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
		 WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
		 ELSE 'No Change'
	END py_change
	from yearly_product_sales
	order by product_name, order_year


--Part to Whole Analysis

with category_sales as
(
	select 
	category,
	sum(sales_amount) total_sales
	from gold.fact_sales f 
	left join gold.dim_products p
	on p.product_key = f.product_key
	group by category
)
select
	category,
	total_sales,
	sum(total_sales) over() overall_sales,
	concat(round((cast(total_sales as float)/sum(total_sales) over())*100,2), '%') as percentage_of_total 
from category_sales
order by total_sales desc

--DATA SEGMENTATION

with product_segments as(
	SELECT
		product_key,
		product_name,
		cost,
		CASE WHEN cost < 100 THEN 'Below 100'
			 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
			 WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
			 ELSE 'Above 1000'
		END cost_range
	FROM gold.dim_products
	)
SELECT
    cost_range,
    COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC

-- Group customers into three segments based on their spending behavior:
--   - VIP: Customers with at least 12 months of history and spending more than €5,000.
--   - Regular: Customers with at least 12 months of history but spending €5,000 or less.
--   - New: Customers with a lifespan less than 12 months.
-- And find the total number of customers by each group

with customer_spending as
(
	select 
	c.customer_key,
	sum(f.sales_amount) as total_spending,
	min(order_date) as first_order,
	max(order_date) as last_order,
	datediff(month,min(order_date),max(order_date)) as lifespan
	from gold.fact_sales f
	left join gold.dim_customers c
	on f.customer_key = c.customer_key
	group by c.customer_key
)

select 
customer_key,
total_spending,
lifespan,
case when lifespan >= 12 and total_spending >5000  then 'VIP'
	 when lifespan >= 12 and total_spending <=5000 then 'Regular'
	 else 'New'
end customer_types
from customer_spending

===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
    2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
        - total orders
        - total sales
        - total quantity purchased
        - total products
        - lifespan (in months)
    4. Calculates valuable KPIs:
        - recency (months since last order)
        - average order value
        - average monthly spend
===============================================================================
create view gold.report_customers as 
with base_query as (
-- 1) Base Query: Retrieves core columns from tables
-- ---------------------------------------------------------------------------	
	SELECT
		f.order_number,
		f.product_key,
		f.order_date,
		f.sales_amount,
		f.quantity,
		c.customer_key,
		c.customer_number,
		concat(c.first_name,' ', c.last_name) as customer_name,
		datediff(year,c.birthdate,GETDATE()) age
		from gold.fact_sales f
		left join gold.dim_customers c
		on c.customer_key = f.customer_key
		where order_date is not null),

		customer_aggregation as(
/* -------------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the Customer Level
--------------------------------------------------------------------------*/
 SELECT
    customer_key,
    customer_number,
    customer_name,
    age,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT product_key) AS total_products,
    MAX(order_date) AS last_order_date,
    DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
FROM base_query
group by 
	customer_key,
	customer_name,
	customer_number,
	age
	)

	SELECT
    customer_key,
    customer_number,
    customer_name,
    age,
    CASE
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and above'
    END AS age_group,
    CASE
        WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
        ELSE 'New'
    END AS customer_segment,
	last_order_date,
	DATEDIFF(month,last_order_date,getdate()) as recency,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
	lifespan,
	--Compute Average Order Value (AVO)
		case when total_orders = 0 then 0
			 else total_sales/total_orders
		end as avg_order_value,
	--Compute Average Monthly Sales (AMS)
		case when lifespan = 0 then total_sales
			 else total_sales/lifespan
		end as average_monthly_spend
		from customer_aggregation

/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
        - total orders
        - total sales
        - total quantity sold
        - total customers (unique)
        - lifespan (in months)
    4. Calculates valuable KPIs:
        - recency (months since last sale)
        - average order revenue (AOR)
        - average monthly revenue
===============================================================================
*/

CREATE VIEW gold.report_products AS

WITH base_query AS (
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from fact_sales and dim_products
---------------------------------------------------------------------------*/
    SELECT
        f.order_number,
        f.order_date,
        f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE order_date IS NOT NULL  -- only consider valid sales dates
),

product_aggregations AS (
/*---------------------------------------------------------------------------
2) Product Aggregations: Summarizes key metrics at the product level
---------------------------------------------------------------------------*/
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
    MAX(order_date) AS last_sale_date,
    COUNT(DISTINCT order_number) AS total_orders,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)), 1) AS avg_selling_price
FROM base_query
GROUP BY
    product_key,
    product_name,
    category,
    subcategory,
    cost
)

/*---------------------------------------------------------------------------
3) Final Query: Combines all product results into one output
---------------------------------------------------------------------------*/
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    last_sale_date,
    DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency_in_months,
    CASE
        WHEN total_sales > 50000 THEN 'High-Performer'
        WHEN total_sales >= 10000 THEN 'Mid-Range'
        ELSE 'Low-Performer'
    END AS product_segment,
	    lifespan,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    avg_selling_price,
    -- Average Order Revenue (AOR)
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_revenue,

    -- Average Monthly Revenue
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END AS avg_monthly_revenue
FROM product_aggregations
