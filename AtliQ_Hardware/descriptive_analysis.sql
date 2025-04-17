# KEY QUERIES AND ANALYSIS

USE atliqHardware;

# Monthly sales trend (by month-year):
SELECT 
    DATE_FORMAT(date, '%Y-%m') AS month,
    SUM(sold_quantity) AS total_units_sold
FROM
    fact_sales_monthly
GROUP BY month
ORDER BY month;

# Top 5 customers by total quantity sold:
SELECT 
    c.customer, SUM(s.sold_quantity) AS total_units
FROM
    fact_sales_monthly s
        JOIN
    dim_customer c ON s.customer_code = c.customer_code
GROUP BY c.customer
ORDER BY total_units DESC
LIMIT 5;

# Most profitable products (estimated gross revenue):
SELECT 
    p.product,
    SUM(s.sold_quantity * g.gross_price) AS estimated_revenue
FROM
    fact_sales_monthly s
        JOIN
    fact_gross_price g ON s.product_code = g.product_code
        AND s.fiscal_year = g.fiscal_year
        JOIN
    dim_product p ON s.product_code = p.product_code
GROUP BY p.product
ORDER BY estimated_revenue DESC
LIMIT 10;

# Average manufacturing cost per division:
SELECT 
    d.division, AVG(m.manufacturing_cost) AS avg_cost
FROM
    fact_manufacturing_cost m
        JOIN
    dim_product d ON m.product_code = d.product_code
GROUP BY d.division;

# Effective discount by customer (pre-invoice deductions):
SELECT 
    c.customer, AVG(d.pre_invoice_discount_pct) AS avg_discount
FROM
    fact_pre_invoice_deductions d
        JOIN
    dim_customer c ON d.customer_code = c.customer_code
GROUP BY c.customer
ORDER BY avg_discount DESC;

# Compare revenue vs. cost by product:
SELECT 
    p.product,
    SUM(s.sold_quantity * g.gross_price) AS total_revenue,
    SUM(s.sold_quantity * m.manufacturing_cost) AS total_cost,
    SUM(s.sold_quantity * g.gross_price) - SUM(s.sold_quantity * m.manufacturing_cost) AS profit
FROM
    fact_sales_monthly s
        JOIN
    fact_gross_price g ON s.product_code = g.product_code
        AND s.fiscal_year = g.fiscal_year
        JOIN
    fact_manufacturing_cost m ON s.product_code = m.product_code
        AND s.fiscal_year = m.cost_year
        JOIN
    dim_product p ON s.product_code = p.product_code
GROUP BY p.product
ORDER BY profit DESC;

# Gross Profit
SELECT 
    ROUND(SUM(s.sold_quantity * g.gross_price), 2) AS total_revenue,
    ROUND(SUM(s.sold_quantity * mc.manufacturing_cost), 2) AS total_cost,
    ROUND(SUM((s.sold_quantity * g.gross_price) - (s.sold_quantity * mc.manufacturing_cost)), 2) AS gross_profit
FROM
    fact_sales_monthly s
        JOIN
    fact_gross_price g ON s.product_code = g.product_code
        JOIN
    fact_manufacturing_cost mc ON s.product_code = mc.product_code;

