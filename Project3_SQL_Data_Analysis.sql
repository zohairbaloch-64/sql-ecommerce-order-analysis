/* ============================================================================
   Project 3: SQL Data Analysis — E-Commerce Orders
   DecodeLabs Data Analytics Internship — Batch 2026
   Analyst: Zohair

   Tool: SQL Server Management Studio (T-SQL)

   Structure follows the Input -> Process -> Output (IPO) framework:
     1. INPUT   - Create database & table, BULK LOAD data from CSV, inspect schema
     2. PROCESS - Filtering, sorting, aggregation, grouping, HAVING
     3. OUTPUT  - Business-translated summary queries

   Execution order reminder (per DecodeLabs training):
   The engine evaluates FROM -> WHERE -> GROUP BY -> HAVING -> SELECT -> ORDER BY,
   NOT the order the clauses are typed in.

   ----------------------------------------------------------------------------
   BEFORE YOU RUN THIS:
   1. Copy 'ecommerce_orders.csv' onto the machine running SQL Server
      (not just your local PC — if you're on SQL Server Express on your own
      laptop, that's the same machine, so this is usually a non-issue).
   2. Update the file path in the BULK INSERT statement below (Section 1.2)
      to match wherever you saved the CSV, e.g. 'C:\Data\ecommerce_orders.csv'.
   3. If BULK INSERT still fails with a permissions error, use the GUI
      alternative instead — see the note right above the BULK INSERT block.
   ============================================================================ */


/* ============================================================================
   SECTION 1: INPUT — Database & Table Setup
   ============================================================================ */

-- Create a dedicated database for this project (skip if it already exists)
IF DB_ID('DecodeLabs_Project3') IS NULL
BEGIN
    CREATE DATABASE DecodeLabs_Project3;
END

USE DecodeLabs_Project3;


-- Drop the table if re-running this script
IF OBJECT_ID('dbo.orders', 'U') IS NOT NULL
    DROP TABLE dbo.orders;

CREATE TABLE dbo.orders (
    OrderID          VARCHAR(20)     NOT NULL PRIMARY KEY,
    OrderDate        DATE            NOT NULL,
    CustomerID       VARCHAR(20)     NOT NULL,
    Product          VARCHAR(50)     NOT NULL,
    Quantity         INT             NOT NULL,
    UnitPrice        DECIMAL(10,2)   NOT NULL,
    ShippingAddress  VARCHAR(200)    NOT NULL,
    PaymentMethod    VARCHAR(50)     NOT NULL,
    OrderStatus      VARCHAR(50)     NOT NULL,
    TrackingNumber   VARCHAR(30)     NOT NULL,
    ItemsInCart      INT             NOT NULL,
    CouponCode       VARCHAR(30)     NULL,
    ReferralSource   VARCHAR(50)     NOT NULL,
    TotalPrice       DECIMAL(12,2)   NOT NULL
);

-- Note: OrderDate is used instead of the reserved-word-adjacent "Date" for
-- cleaner querying in SSMS.

/* ----------------------------------------------------------------------------
   1.2 Load the data — BULK INSERT (recommended, safe, scalable)

   This reads directly from the CSV file rather than hardcoding rows into
   the script. It requires the SQL Server *service account* to have file
   read access to the CSV's location — that's why the path must point to
   somewhere the server itself can see.

   FIRSTROW = 2       -> skips the header row (OrderID, Date, CustomerID, ...)
   FIELDTERMINATOR     -> CSV uses commas
   ROWTERMINATOR       -> handles Windows-style line endings
   TABLOCK             -> speeds up the load by minimizing logging
   ---------------------------------------------------------------------------- */

-- >>> UPDATE THIS PATH to wherever you saved ecommerce_orders.csv <<<
BULK INSERT dbo.orders
FROM 'C:\Users\User\Desktop\Data Analyist work\Decode-Lab-Intership\week 3\ecommerce_orders.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK,
    CODEPAGE = '65001'   -- UTF-8, in case of special characters
);

/* ----------------------------------------------------------------------------
   ALTERNATIVE (no-code, GUI-based — use this if BULK INSERT throws a
   permissions/"Cannot bulk load" error, which is common on locked-down or
   cloud-hosted SQL Server instances):

   1. In SSMS Object Explorer, right-click the DecodeLabs_Project3 database
   2. Tasks -> Import Flat File...
   3. Point it at ecommerce_orders.csv, name the table "orders"
   4. SSMS will auto-detect column types — review/adjust to match the
      CREATE TABLE definition above, then finish the wizard.

   Either method lands you in the exact same place: a populated dbo.orders
   table, ready for the queries below.
   ---------------------------------------------------------------------------- */

-- Sanity check: row count
SELECT COUNT(*) AS rows_loaded FROM dbo.orders;


/* ============================================================================
   1.3 Inspecting the Table Structure
   ============================================================================ */

-- Schema check: column names, data types, nullability
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'orders'
ORDER BY ORDINAL_POSITION;

-- Preview the first 5 rows
SELECT TOP 5 *
FROM dbo.orders;


/* ============================================================================
   SECTION 2: PROCESS — Filtering & Sorting (WHERE, ORDER BY)
   ============================================================================ */

-- 2.1 High-value orders (> 2500), sorted highest first
SELECT TOP 10
    OrderID, CustomerID, Product, TotalPrice, OrderStatus, OrderDate
FROM dbo.orders
WHERE TotalPrice > 2500
ORDER BY TotalPrice DESC;

-- How big is the high-value segment overall?
SELECT
    COUNT(*) AS high_value_orders,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM dbo.orders), 2) AS pct_of_all_orders,
    SUM(TotalPrice) AS revenue_from_segment
FROM dbo.orders
WHERE TotalPrice > 2500;


-- 2.2 Orders at risk: Cancelled & Returned
SELECT
    OrderStatus,
    COUNT(*) AS orders,
    SUM(TotalPrice) AS revenue_impacted
FROM dbo.orders
WHERE OrderStatus IN ('Cancelled', 'Returned')
GROUP BY OrderStatus;


-- 2.3 Coupon-driven orders
SELECT TOP 10
    OrderID, CustomerID, CouponCode, TotalPrice
FROM dbo.orders
WHERE CouponCode IS NOT NULL
ORDER BY TotalPrice DESC;



/* ============================================================================
   SECTION 3: PROCESS — Aggregation Fundamentals (COUNT, SUM, AVG)
   ============================================================================ */

-- 3.1 Business snapshot — the whole store in one query
SELECT
    COUNT(*)                                  AS total_orders,
    SUM(TotalPrice)                           AS total_revenue,
    ROUND(AVG(TotalPrice), 2)                 AS avg_order_value,
    ROUND(AVG(CAST(ItemsInCart AS FLOAT)), 2) AS avg_items_in_cart,
    ROUND(AVG(CAST(Quantity AS FLOAT)), 2)    AS avg_quantity_per_order
FROM dbo.orders;


-- 3.2 The NULL trap: COUNT(*) vs COUNT(column) vs AVG() on a nullable column
SELECT
    COUNT(*) AS total_orders,
    COUNT(CouponCode) AS orders_with_coupon_counted,
    COUNT(*) - COUNT(CouponCode) AS orders_with_null_coupon
FROM dbo.orders;

-- COUNT(*) counts every row; COUNT(CouponCode) skips NULLs;
-- the gap between the two is exactly how many orders had no coupon.


/* ============================================================================
   SECTION 4: PROCESS — Grouping Data (GROUP BY)
   ============================================================================ */

-- 4.1 Revenue & orders by product
SELECT
    Product,
    COUNT(*)                  AS orders,
    SUM(TotalPrice)           AS revenue,
    ROUND(AVG(TotalPrice), 2) AS avg_order_value
FROM dbo.orders
GROUP BY Product
ORDER BY revenue DESC;


-- 4.2 Orders by status — fulfillment health check
SELECT
    OrderStatus,
    COUNT(*) AS orders,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM dbo.orders), 2) AS pct_of_total
FROM dbo.orders
GROUP BY OrderStatus
ORDER BY orders DESC;


-- 4.3 Revenue by payment method
SELECT
    PaymentMethod,
    COUNT(*)                  AS orders,
    SUM(TotalPrice)           AS revenue,
    ROUND(AVG(TotalPrice), 2) AS avg_order_value
FROM dbo.orders
GROUP BY PaymentMethod
ORDER BY revenue DESC;


-- 4.4 Revenue by marketing/referral source
SELECT
    ReferralSource,
    COUNT(*)                  AS orders,
    SUM(TotalPrice)           AS revenue,
    ROUND(AVG(TotalPrice), 2) AS avg_order_value
FROM dbo.orders
GROUP BY ReferralSource
ORDER BY revenue DESC;

-- 4.5 Yearly order trend
SELECT
    YEAR(OrderDate) AS order_year,
    COUNT(*)         AS orders,
    SUM(TotalPrice)  AS revenue
FROM dbo.orders
GROUP BY YEAR(OrderDate)
ORDER BY order_year;

-- Note: 2025 only covers Jan-Jun in this dataset, so its lower total
-- reflects a partial year, not a decline.

-- 4.6 Coupon effectiveness — does a promo code change order value?
SELECT
    CASE WHEN CouponCode IS NULL THEN 'No Coupon' ELSE CouponCode END AS coupon_group,
    COUNT(*)                  AS orders,
    ROUND(AVG(TotalPrice), 2) AS avg_order_value
FROM dbo.orders
GROUP BY CASE WHEN CouponCode IS NULL THEN 'No Coupon' ELSE CouponCode END
ORDER BY avg_order_value DESC;



/* ============================================================================
   SECTION 5: PROCESS — Filtering Grouped Data (HAVING)
   ============================================================================ */

-- Which products are both popular (>170 orders) AND above-average order value?
-- HAVING filters the GROUP BY buckets themselves, after grouping has happened —
-- unlike WHERE, which filters individual rows before grouping.
SELECT
    Product,
    COUNT(*)                  AS orders,
    ROUND(AVG(TotalPrice), 2) AS avg_order_value
FROM dbo.orders
GROUP BY Product
HAVING COUNT(*) > 170
   AND AVG(TotalPrice) > (SELECT AVG(TotalPrice) FROM dbo.orders)
ORDER BY avg_order_value DESC;



/* ============================================================================
   SECTION 6: PROCESS — Advanced Queries: Top Customers & Revenue Share
   ============================================================================ */

-- 6.1 Top 10 customers by total spend
SELECT TOP 10
    CustomerID,
    COUNT(*)         AS orders,
    SUM(TotalPrice)  AS total_spent
FROM dbo.orders
GROUP BY CustomerID
ORDER BY total_spent DESC;


-- 6.2 Each product's percentage contribution to total revenue
SELECT
    Product,
    SUM(TotalPrice) AS revenue,
    ROUND(100.0 * SUM(TotalPrice) / (SELECT SUM(TotalPrice) FROM dbo.orders), 2) AS pct_of_total_revenue
FROM dbo.orders
GROUP BY Product
ORDER BY pct_of_total_revenue DESC;



/* ============================================================================
   SECTION 7: OUTPUT — Business-Translated Executive Summary
   ============================================================================

   Revenue Snapshot
   -----------------
   1,200 orders worth Rs. 12,64,761.96 total revenue (avg Rs. 1,053.97/order).
   No single runaway bestseller — the top 3 products (Chair, Printer, Laptop)
   each contribute ~15% of revenue: a balanced catalog, not one hero product.

   Fulfillment Health Needs Attention
   -----------------------------------
   Cancelled (20.8%) + Returned (20.6%) = 41.4% of all orders, representing
   roughly Rs. 5,19,673 in reversed/lost revenue. This is the single biggest
   opportunity area in the dataset.

   Payment & Marketing Channels Are Evenly Split
   -----------------------------------------------
   No payment method or referral source dominates — all are within a few
   percentage points of each other. Healthy diversification, but no single
   channel to double down on without further testing.

   Coupons Show a Small, Not Dramatic, Lift
   -------------------------------------------
   FREESHIP (avg Rs. 1,070) and SAVE10 (avg Rs. 1,066) both slightly beat
   no-coupon orders (avg Rs. 1,043); WINTER15 (avg Rs. 1,036) actually
   underperforms the no-coupon baseline.

   Premium-and-Popular Products
   -------------------------------
   HAVING isolates Laptop, Chair, and Printer as the only products that are
   simultaneously high-volume (>170 orders) AND above-average order value —
   the natural anchor for inventory/ad-spend prioritization.

   A Highly Fragmented Customer Base
   ------------------------------------
   The top customer by spend placed only 2 orders; every other top-10
   customer made a single purchase. No repeat-buyer segment exists yet —
   a loyalty/retention program is untapped whitespace.
   ============================================================================ */
