# AD-HOC QUERIES INSIGHTS

USE atliqHardware;

#1  Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
SELECT market
FROM `dim_customer`
WHERE customer= 'Atliq Exclusive' AND region= 'APAC'
GROUP BY market;


#2  What is the percentage of unique product increase in 2021 vs. 2020?
SELECT 
    A.unq_20 AS unique_products_2020,
    B.unq_21 AS unique_products_2021,
    ROUND((B.unq_21 - A.unq_20) * 100 / A.unq_20,
            2) AS pct_change
FROM
    (SELECT 
        COUNT(DISTINCT product_code) AS unq_20
    FROM
        fact_sales_monthly
    WHERE
        fiscal_year = 2020) A
        CROSS JOIN
    (SELECT 
        COUNT(DISTINCT product_code) AS unq_21
    FROM
        fact_sales_monthly
    WHERE
        fiscal_year = 2021) B;


#3  Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
SELECT 
    segment, COUNT(product) AS product_count
FROM
    dim_product
GROUP BY segment
ORDER BY product_count DESC;


#4  Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?
WITH product_count_2020 AS (
  SELECT
    p.segment AS segment,
    COUNT(DISTINCT s.product_code) AS product_count_2020
  FROM dim_product p
  JOIN fact_sales_monthly s ON p.product_code = s.product_code
  WHERE s.fiscal_year = 2020
  GROUP BY p.segment
),
product_count_2021 AS (
  SELECT
    p.segment AS segment,
    COUNT(DISTINCT s.product_code) AS product_count_2021
  FROM dim_product p
  JOIN fact_sales_monthly s ON p.product_code = s.product_code
  WHERE s.fiscal_year = 2021
  GROUP BY p.segment
)
SELECT
  pc20.segment,
  pc20.product_count_2020,
  pc21.product_count_2021,
  (pc21.product_count_2021 - pc20.product_count_2020) AS difference
FROM product_count_2020 pc20
JOIN product_count_2021 pc21 ON pc20.segment = pc21.segment
ORDER BY difference DESC
LIMIT 1;


#5  Get the products that have the highest and lowest manufacturing costs.
(SELECT
  m.product_code,
  p.product,
  m.manufacturing_cost
FROM fact_manufacturing_cost m
JOIN dim_product p ON m.product_code = p.product_code
ORDER BY m.manufacturing_cost DESC
LIMIT 1)
UNION
(SELECT
  m.product_code,
  p.product,
  m.manufacturing_cost
FROM fact_manufacturing_cost m
JOIN dim_product p ON m.product_code = p.product_code
ORDER BY m.manufacturing_cost ASC
LIMIT 1);


#6  Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
SELECT 
    pr.customer_code,
    c.customer,
    pr.pre_invoice_discount_pct AS average_discount_percentage
FROM
    fact_pre_invoice_deductions pr
        JOIN
    dim_customer c USING (customer_code)
WHERE
    pr.pre_invoice_discount_pct > (SELECT 
            AVG(pre_invoice_discount_pct)
        FROM
            fact_pre_invoice_deductions)
        AND c.market = 'India'
ORDER BY pr.pre_invoice_discount_pct DESC
LIMIT 5;


#7  Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . This analysis helps to get an idea of low and high-performing months and take strategic decisions.
SELECT 
    CONCAT(MONTHNAME(s.date),
            ' (',
            YEAR(s.date),
            ')') AS month,
    s.fiscal_year,
    ROUND(SUM(s.sold_quantity * g.gross_price), 2) AS gross_sales_amount
FROM
    fact_sales_monthly s
        JOIN
    fact_gross_price g ON s.product_code = g.product_code
        JOIN
    dim_customer c ON s.customer_code = c.customer_code
WHERE
    c.customer = 'Atliq Exclusive'
GROUP BY month , s.fiscal_year
ORDER BY s.fiscal_year;


#8  In which quarter of 2020, got the maximum total_sold_quantity?
SELECT 
    CASE
        WHEN date BETWEEN '2019-09-01' AND '2019-11-01' THEN 'Q1'
        WHEN date BETWEEN '2019-12-01' AND '2020-02-01' THEN 'Q2'
        WHEN date BETWEEN '2020-03-01' AND '2020-05-01' THEN 'Q3'
        WHEN date BETWEEN '2020-06-01' AND '2020-08-01' THEN 'Q4'
    END AS quarters,
    ROUND(SUM(sold_quantity) / 1000000, 2) AS total_sold_quantity_in_mln
FROM
    fact_sales_monthly
WHERE
    fiscal_year = 2020
GROUP BY quarters
ORDER BY total_sold_quantity_in_mln DESC;


#9  Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
WITH channel_sales_2021 AS (
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
  ROUND(total_sales / 1000000, 2) AS gross_sales_in_mln,
  ROUND((total_sales / SUM(total_sales) OVER()) * 100, 2) AS percentage
FROM channel_sales_2021
ORDER BY total_sales DESC;


#10  Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
WITH division_product_sales AS (
  SELECT
    p.division, 
    s.product_code, 
    p.product,
    SUM(s.sold_quantity) AS total_sold_quantity
  FROM fact_sales_monthly s
  JOIN dim_product p ON s.product_code = p.product_code
  WHERE s.fiscal_year = 2021 
  GROUP BY s.product_code, p.division, p.product
),
ranked_products_per_division AS (
  SELECT 
    division, 
    product_code, 
    product, 
    total_sold_quantity,
    RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
  FROM division_product_sales
)
SELECT 
  dps.division, 
  dps.product_code, 
  dps.product, 
  rppd.total_sold_quantity, 
  rppd.rank_order
FROM division_product_sales dps
JOIN ranked_products_per_division rppd 
  ON dps.product_code = rppd.product_code
WHERE rppd.rank_order IN (1, 2, 3);

