# ADVANCED QUERIES AND INSIGHTS (CTEs, Views, Stored Procedures, and Temp Tables)
USE atliqHardware;

# ✅ CTEs (Common Table Expressions)

# CTE for top 5 markets by total sales:
WITH market_sales AS (
  SELECT 
    c.market,
    SUM(s.sold_quantity) AS total_units
  FROM fact_sales_monthly s
  JOIN dim_customer c ON s.customer_code = c.customer_code
  GROUP BY c.market
)
SELECT 
    *
FROM
    market_sales
ORDER BY total_units DESC
LIMIT 5;

# CTE to find products with declining sales between 2020 and 2021:
WITH yearly_sales AS (
  SELECT 
    product_code,
    fiscal_year,
    SUM(sold_quantity) AS total_units
  FROM fact_sales_monthly
  GROUP BY product_code, fiscal_year
),
pivot_sales AS (
  SELECT 
    product_code,
    MAX(CASE WHEN fiscal_year = 2020 THEN total_units END) AS sales_2020,
    MAX(CASE WHEN fiscal_year = 2021 THEN total_units END) AS sales_2021
  FROM yearly_sales
  GROUP BY product_code
)
SELECT * 
FROM pivot_sales 
WHERE sales_2021 < sales_2020;


# ✅ Views

# View to get monthly revenue per product:
CREATE VIEW monthly_product_revenue AS
    SELECT 
        s.date,
        s.product_code,
        p.product,
        SUM(s.sold_quantity * g.gross_price) AS revenue
    FROM
        fact_sales_monthly s
            JOIN
        fact_gross_price g ON s.product_code = g.product_code
            AND s.fiscal_year = g.fiscal_year
            JOIN
        dim_product p ON s.product_code = p.product_code
    GROUP BY s.date , s.product_code , p.product;
    
SELECT * FROM monthly_product_revenue;

# View to join customer and sales with market and region:
CREATE VIEW customer_sales_region AS
    SELECT 
        s.date,
        c.customer,
        c.market,
        c.region,
        s.product_code,
        s.sold_quantity
    FROM
        fact_sales_monthly s
            JOIN
        dim_customer c ON s.customer_code = c.customer_code;

SELECT * FROM customer_sales_region LIMIT 5;

# ✅ Stored Procedures

# Procedure to get top N products by sales volume:
DELIMITER //
CREATE PROCEDURE top_products_by_sales(IN limit_val INT)
BEGIN
  SELECT 
    p.product,
    SUM(s.sold_quantity) AS total_units
  FROM fact_sales_monthly s
  JOIN dim_product p ON s.product_code = p.product_code
  GROUP BY p.product
  ORDER BY total_units DESC
  LIMIT limit_val;
END //
DELIMITER ;
CALL top_products_by_sales(10);

# Procedure to get total sales by a given region:
DELIMITER //
CREATE PROCEDURE region_sales_summary(IN region_name VARCHAR(50))
BEGIN
  SELECT 
    c.region,
    SUM(s.sold_quantity) AS total_units
  FROM fact_sales_monthly s
  JOIN dim_customer c ON s.customer_code = c.customer_code
  WHERE c.region = region_name
  GROUP BY c.region;
END //
DELIMITER ;

# ✅ Temporary Tables

# Temp table to store top 10 products by revenue:
CREATE TEMPORARY TABLE top10_products_revenue AS
SELECT 
  s.product_code,
  p.product,
  SUM(s.sold_quantity * g.gross_price) AS revenue
FROM fact_sales_monthly s
JOIN fact_gross_price g ON s.product_code = g.product_code AND s.fiscal_year = g.fiscal_year
JOIN dim_product p ON s.product_code = p.product_code
GROUP BY s.product_code, p.product
ORDER BY revenue DESC
LIMIT 10;

SELECT * FROM top10_products_revenue;

# Temp table for customer-level sales and discount summary:
CREATE TEMPORARY TABLE customer_discount_summary AS
SELECT 
  s.customer_code,
  c.customer,
  SUM(s.sold_quantity) AS total_units,
  ROUND(AVG(d.pre_invoice_discount_pct), 1) * 100 AS avg_discount
FROM fact_sales_monthly s
JOIN dim_customer c ON s.customer_code = c.customer_code
JOIN fact_pre_invoice_deductions d ON s.customer_code = d.customer_code AND s.fiscal_year = d.fiscal_year
GROUP BY s.customer_code, c.customer;

SELECT * FROM customer_discount_summary LIMIT 5;