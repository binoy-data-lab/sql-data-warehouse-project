# SQL Data Warehouse Project

A modern data warehouse built with **SQL Server**, covering **ETL processes**, **data modeling** and **analytics**.

This project brings raw data from two source systems (CRM and ERP) into one clean, analysis-ready **star schema**, using a three-layer architecture: **Bronze → Silver → Gold**.

---

## 🏗️ Data Architecture

| Layer | What it does | How it is built |
|-------|--------------|-----------------|
| **Bronze** | Raw data loaded as-is from the source CSV files | Tables loaded with `BULK INSERT` through the stored procedure `bronze.load_bronze` |
| **Silver** | Cleaned, standardized and validated data | Tables loaded with transformations through the stored procedure `silver.load_silver` |
| **Gold** | Business-ready data modeled as a star schema | Views: `gold.dim_customers`, `gold.dim_products`, `gold.fact_sales` |

---

## 📥 Data Sources

Six CSV files from two source systems, stored in `datasets/`:

| System | File | Content |
|--------|------|---------|
| CRM | `cust_info.csv` | Customer details |
| CRM | `prd_info.csv` | Product details with start and end dates |
| CRM | `sales_details.csv` | Sales transactions |
| ERP | `cust_az12.csv` | Customer birth date and gender |
| ERP | `loc_a101.csv` | Customer country |
| ERP | `px_cat_g1v2.csv` | Product categories and subcategories |

---

## 🔄 ETL Process

### Bronze layer: Extract and Load
- Truncates each Bronze table and reloads it from the CSV file using `BULK INSERT`.
- Logs the load duration for each table and for the full batch.
- Uses `TRY...CATCH` to report errors during the load.

### Silver layer: Clean and Transform
Data cleaning and standardization performed in `silver.load_silver`:

- **Text cleanup:** trimmed extra spaces from names and categorical fields.
- **Standardized values:** marital status (`S`/`M` → Single/Married), gender (`F`/`M` → Female/Male), product line (`M`/`R`/`S`/`T` → Mountain/Road/Other Sales/Touring) and country codes (`DE` → Germany, `US`/`USA` → United States).
- **Missing values:** replaced missing or blank values with `n/a`; replaced null product costs with `0`.
- **Product keys:** split the combined product key into a category ID and a product key.
- **Historical product records:** derived each product's end date from the next record's start date using the `LEAD()` window function.
- **Dates:** converted sales dates stored as integers (`YYYYMMDD`) into proper `DATE` values and set invalid order dates to `NULL`.
- **Sales validation:** recalculated sales and price where values were missing, zero, negative or inconsistent with `quantity × price`.
- **ID and date fixes:** removed the `NAS` prefix and dashes from ERP customer IDs and set future birth dates to `NULL`.
- Every Silver table also stores a `dwh_create_date` load timestamp.

### Gold layer: Model
Views that join the Silver tables into a **star schema**:

| View | Type | Description |
|------|------|-------------|
| `gold.dim_customers` | Dimension | Combines CRM customer data with ERP birth date, gender and country. CRM is treated as the master source for gender. Uses a surrogate key (`customer_key`). |
| `gold.dim_products` | Dimension | Combines CRM product data with ERP category data. Keeps only current products by filtering out historical records. Uses a surrogate key (`product_key`). |
| `gold.fact_sales` | Fact | Sales transactions linked to the product and customer dimensions through their surrogate keys. |

---

## 📂 Repository Structure

```
sql-data-warehouse-project/
│
├── datasets/     # Source CSV files (source_crm and source_erp)
├── docs/         # Project documentation
├── scripts/      # SQL scripts for the Bronze, Silver and Gold layers
├── tests/        # Test scripts
├── LICENSE       # MIT License
└── README.md     # Project overview (this file)
```

---

## 🛠️ Tools and Technologies

- **SQL Server** (database and data warehouse)
- **T-SQL** (stored procedures, views, window functions, transformations)
- **Git and GitHub** (version control)

---

## 🚀 How to Run

1. Install **SQL Server** and a client such as **SQL Server Management Studio (SSMS)**.
2. Clone this repository:
   ```bash
   git clone https://github.com/binoy-data-lab/sql-data-warehouse-project.git
   ```
3. Create the database and the `bronze`, `silver` and `gold` schemas.
4. Create the Bronze and Silver tables using the DDL scripts in `scripts/`.
5. In the Bronze load script, **update the CSV file paths** to match the location of the `datasets/` folder on your machine.
6. Run the ETL procedures in order:
   ```sql
   EXEC bronze.load_bronze;
   EXEC silver.load_silver;
   ```
7. Run the Gold layer script to create the views, then query them:
   ```sql
   SELECT * FROM gold.fact_sales;
   ```

---

## 🙏 Acknowledgements

Built as a hands-on learning project to practice data warehousing, ETL and data modeling with SQL Server.

---

## 👤 About Me

**Binoy Roy**
Aspiring Data Analyst | SQL · Google Sheets · Tableau

- LinkedIn: [binoy-roy](https://www.linkedin.com/in/binoy-roy-885966280/)
- GitHub: [binoy-data-lab](https://github.com/binoy-data-lab)

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
