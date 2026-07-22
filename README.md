# Project 3: SQL Data Analysis — E-Commerce Orders

**DecodeLabs Data Analytics Internship**

## 📌 Overview
This project applies core SQL techniques — `SELECT`, `WHERE`, `ORDER BY`, `GROUP BY`, `HAVING`, and aggregate functions (`COUNT`, `SUM`, `AVG`) — to extract actionable business insights from a 1,200-row e-commerce orders dataset. The data is loaded into a real **SQL Server** database via `BULK INSERT` and queried directly in **SQL Server Management Studio (SSMS)**, following the **Input → Process → Output (IPO)** framework taught in this milestone.

This builds on the cleaned/explored dataset from Projects 1 and 2, moving from *cleaning* and *exploring* the data to *querying it for specific business answers* using T-SQL.

##  Objectives
- Load a flat-file dataset into a SQL Server database using `BULK INSERT`
- Write filtering and sorting queries (`WHERE`, `ORDER BY`)
- Perform aggregations (`COUNT`, `SUM`, `AVG`)
- Group data into business-meaningful buckets (`GROUP BY`)
- Filter aggregated groups (`HAVING`)
- Translate SQL output into a non-technical, business-facing executive summary

## Repository Structure
```
├── Project3_SQL_Data_Analysis.sql     # Main T-SQL script — schema, data load, all queries (IPO structure)
├── ecommerce_orders.csv               # Source dataset (1,200 orders, 14 columns)
└── README.md
```

##  How to Run
1. Save `ecommerce_orders.csv` somewhere your SQL Server instance can read (e.g. `C:\Data\ecommerce_orders.csv`).
2. Open `Project3_SQL_Data_Analysis.sql` in SSMS.
3. Update the file path in the `BULK INSERT` statement (Section 1.2) to match where you saved the CSV.
4. Execute the script (F5). It creates the `DecodeLabs_Project3` database, builds the `orders` table, loads all 1,200 rows, and runs every analysis query in sequence.
5. If `BULK INSERT` throws a permissions error, use the built-in GUI fallback noted in the script: right-click the database → **Tasks → Import Flat File**.

##  Key Analyses Performed
1. **Data loading & schema inspection** — CSV → SQL Server table via `BULK INSERT`, `INFORMATION_SCHEMA.COLUMNS`
2. **Filtering & sorting** — high-value orders, cancelled/returned orders, coupon-driven orders
3. **Aggregation fundamentals** — total orders, total revenue, average order value; a live demonstration of how `COUNT(*)` vs `COUNT(column)`/`AVG()` handle NULLs differently
4. **Group-by analysis** — revenue by product, order status, payment method, referral source, and year
5. **HAVING** — isolating products that are both high-volume *and* above-average order value
6. **Advanced queries** — top 10 customers by spend, each product's percentage contribution to total revenue

## 💡 Key Business Insights
- **Cancelled + Returned orders make up 41.4%** of all orders (~₹5.2L in reversed/lost revenue) — the biggest opportunity area in the dataset.
- Revenue is **evenly spread across the product catalog** — no single product dominates (each is roughly 12–15% of total revenue).
- **Laptop, Chair, and Printer** are the only products that clear both a volume bar (>170 orders) and an above-average order-value bar.
- The customer base is **almost entirely one-time buyers** — a clear whitespace for a retention/loyalty program.
- Coupon codes produce only a **marginal lift** in order value; `WINTER15` actually underperforms the no-coupon baseline.

## 🛠️ Tools Used
- SQL Server Management Studio (SSMS), T-SQL

## 👤 Author
Zohair — Data Analytics Intern, DecodeLabs (Batch 2026)
