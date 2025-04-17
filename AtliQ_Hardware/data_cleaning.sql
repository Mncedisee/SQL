# DATA CLEANING QUERIES 

SELECT 
  date, product_code, customer_code, sold_quantity, fiscal_year,
  COUNT(*) AS cnt
FROM fact_sales_monthly
GROUP BY 
  date, product_code, customer_code, sold_quantity, fiscal_year
HAVING COUNT(*) > 1;

SELECT 
    COUNT(*) AS null_count
FROM
    dim_customer
WHERE
    customer_code IS NULL
        OR customer IS NULL;
SELECT 
    COUNT(*) AS null_count
FROM
    dim_product
WHERE
    product_code IS NULL OR product IS NULL;
SELECT 
    COUNT(*) AS null_count
FROM
    fact_sales_monthly
WHERE
    date IS NULL OR product_code IS NULL
        OR customer_code IS NULL;
        
SELECT 
    *
FROM
    fact_sales_monthly
WHERE
    date NOT BETWEEN '2019-09-01' AND '2021-08-31';
    
SELECT 
    *
FROM
    fact_sales_monthly
WHERE
    sold_quantity <= 0;

SELECT DISTINCT
    product_code
FROM
    fact_sales_monthly
WHERE
    product_code NOT IN (SELECT 
            product_code
        FROM
            dim_product);


