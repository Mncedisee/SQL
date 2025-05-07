USE atliqHardware;

-- 1. Markets where "Atliq Exclusive" operates in APAC
SELECT DISTINCT market
FROM dim_customer
WHERE customer = 'Atliq Exclusive' AND region = 'APAC';

-- 2. % increase in unique products from 2020 to 2021
SELECT
  A.unique_2020,
  B.unique_2021,
  ROUND((B.unique_2021 - A.unique_2020) * 100.0 / A.unique_2020, 2) AS pct_change
FROM
  (SELECT COUNT(DISTINCT product_code) AS unique_2020 FROM fact_sales_monthly WHERE fiscal_year = 2020) A,
  (SELECT COUNT(DISTINCT product_code) AS unique_2021 FROM fact_sales_monthly WHERE fiscal_year = 2021) B;

-- 3. Unique product count by segment, descending
SELECT segment, COUNT(DISTINCT product) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- 4. Segment with most increase in unique products (2021 vs 2020)
WITH products_2020 AS (
  SELECT p.segment, COUNT(DISTINCT s.product_code) AS count_2020
  FROM dim_product p
  JOIN fact_sales_monthly s ON p.product_code = s.product_code
  WHERE s.fiscal_year = 2020
  GROUP BY p.segment
),
products_2021 AS (
  SELECT p.segment, COUNT(DISTINCT s.product_code) AS count_2021
  FROM dim_product p
  JOIN fact_sales_monthly s ON p.product_code = s.product_code
  WHERE s.fiscal_year = 2021
  GROUP BY p.segment
)
SELECT
  p20.segment,
  p20.count_2020,
  p21.count_2021,
  (p21.count_2021 - p20.count_2020) AS difference
FROM products_2020 p20
JOIN products_2021 p21 ON p20.segment = p21.segment
ORDER BY difference DESC;

-- 5. Products with highest and lowest manufacturing cost
(
  SELECT m.product_code, p.product, m.manufacturing_cost
  FROM fact_manufacturing_cost m
  JOIN dim_product p ON m.product_code = p.product_code
  ORDER BY m.manufacturing_cost DESC
  LIMIT 1
)
UNION ALL
(
  SELECT m.product_code, p.product, m.manufacturing_cost
  FROM fact_manufacturing_cost m
  JOIN dim_product p ON m.product_code = p.product_code
  ORDER BY m.manufacturing_cost ASC
  LIMIT 1
);

-- 6. Top 5 Indian customers with highest avg pre_invoice_discount_pct (FY 2021)
SELECT
  pr.customer_code,
  c.customer,
  AVG(pr.pre_invoice_discount_pct) AS average_discount_percentage
FROM fact_pre_invoice_deductions pr
JOIN dim_customer c ON pr.customer_code = c.customer_code
WHERE c.market = 'India' AND pr.fiscal_year = 2021
GROUP BY pr.customer_code, c.customer
ORDER BY average_discount_percentage DESC
LIMIT 5;

-- 7. Monthly gross sales for "Atliq Exclusive"
SELECT
  DATE_FORMAT(s.date, '%M (%Y)') AS month,
  s.fiscal_year,
  ROUND(SUM(s.sold_quantity * g.gross_price), 2) AS gross_sales_amount
FROM fact_sales_monthly s
JOIN fact_gross_price g ON s.product_code = g.product_code
JOIN dim_customer c ON s.customer_code = c.customer_code
WHERE c.customer = 'Atliq Exclusive'
GROUP BY month, s.fiscal_year
ORDER BY s.fiscal_year, month;

-- 8. Quarter in 2020 with max total sold quantity
SELECT
  CASE
    WHEN MONTH(date) BETWEEN 9 AND 11 THEN 'Q1'
    WHEN MONTH(date) BETWEEN 12 OR MONTH(date) = 1 OR MONTH(date) = 2 THEN 'Q2'
    WHEN MONTH(date) BETWEEN 3 AND 5 THEN 'Q3'
    WHEN MONTH(date) BETWEEN 6 AND 8 THEN 'Q4'
  END AS quarter,
  ROUND(SUM(sold_quantity) / 1e6, 2) AS total_sold_quantity_in_mln
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY quarter
ORDER BY total_sold_quantity_in_mln DESC;

-- 9. Channel with highest gross sales in FY 2021 and % contribution
WITH sales_by_channel AS (
  SELECT
    c.channel,
    SUM(s.sold_quantity * g.gross_price) AS total_sales
  FROM fact_sales_monthly s
  JOIN dim_customer c ON s.customer_code = c.customer_code
  JOIN fact_gross_price g ON s.product_code = g.product_code
  WHERE s.fiscal_year = 2021
  GROUP BY c.channel
)
SELECT
  channel,
  ROUND(total_sales / 1e6, 2) AS gross_sales_in_mln,
  ROUND(total_sales * 100.0 / SUM(total_sales) OVER (), 2) AS percentage
FROM sales_by_channel
ORDER BY total_sales DESC;

-- 10. Top 3 products by sold quantity per division in FY 2021
WITH product_sales AS (
  SELECT
    p.division,
    s.product_code,
    p.product,
    SUM(s.sold_quantity) AS total_sold_quantity
  FROM fact_sales_monthly s
  JOIN dim_product p ON s.product_code = p.product_code
  WHERE s.fiscal_year = 2021
  GROUP BY p.division, s.product_code, p.product
),
ranked_products AS (
  SELECT *,
    RANK() OVER (PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
  FROM product_sales
)
SELECT
  division,
  product_code,
  product,
  total_sold_quantity,
  rank_order
FROM ranked_products
WHERE rank_order <= 3
ORDER BY division, rank_order;
