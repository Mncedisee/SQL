-- Retail Sales Analysis

-- 1. High-Value Products with BOGOF Promotion
SELECT 
  p.product_name,
  f.base_price,
  f.promo_type
FROM fact_events f
JOIN dim_products p 
  ON f.product_code = p.product_code
WHERE f.base_price > 500 
  AND f.promo_type = 'BOGOF'
ORDER BY base_price DESC;

-- 2. Store Count by City
SELECT 
  city,
  COUNT(store_id) AS store_count
FROM dim_stores
GROUP BY city
ORDER BY store_count DESC;

-- 3. Campaign Revenue Before & After (in Millions)
SELECT 
  c.campaign_name,
  ROUND(SUM(f.`quantity_sold(before_promo)` * f.base_price) / 1000000, 2) AS total_revenue_before_promotion,
  ROUND(SUM(f.`quantity_sold(after_promo)` * f.base_price) / 1000000, 2) AS total_revenue_after_promotion
FROM fact_events f
JOIN dim_campaigns c 
  ON f.campaign_id = c.campaign_id
GROUP BY c.campaign_name;

-- 4. Diwali Campaign ISU% by Category
WITH DiwaliSales AS (
  SELECT 
    p.category,
    c.campaign_name,
    SUM(f.`quantity_sold(before_promo)`) AS total_before,
    SUM(f.`quantity_sold(after_promo)`) AS total_after
  FROM fact_events f
  JOIN dim_products p ON f.product_code = p.product_code
  JOIN dim_campaigns c ON f.campaign_id = c.campaign_id
  WHERE c.campaign_name = 'Diwali'
  GROUP BY p.category
)
SELECT 
  category,
  campaign_name,
  ROUND(((total_after - total_before) / total_before) * 100, 2) AS `isu%`,
  RANK() OVER (ORDER BY ((total_after - total_before) / total_before) DESC) AS rank_order
FROM DiwaliSales;


-- 5. Sankranti Campaign ISU% by Category
WITH SankrantiSales AS (
  SELECT 
    p.category,
    c.campaign_name,
    SUM(f.`quantity_sold(before_promo)`) AS total_before,
    SUM(f.`quantity_sold(after_promo)`) AS total_after
  FROM fact_events f
  JOIN dim_products p ON f.product_code = p.product_code
  JOIN dim_campaigns c ON f.campaign_id = c.campaign_id
  WHERE c.campaign_name = 'Sankranti'
  GROUP BY p.category
)
SELECT 
  category,
  campaign_name,
  ROUND(((total_after - total_before) / total_before) * 100, 2) AS `isu%`,
  RANK() OVER (ORDER BY ((total_after - total_before) / total_before) DESC) AS rank_order
FROM SankrantiSales;

-- Logic: Calculate percentage change in quantity sold and rank categories.

-- 6. Top 5 Products by IR%
WITH RevenueCalculation AS (
  SELECT 
    p.product_name,
    p.category,
    SUM(f.`quantity_sold(before_promo)` * f.base_price) AS revenue_before,
    SUM(f.`quantity_sold(after_promo)` * f.base_price) AS revenue_after
  FROM fact_events f
  JOIN dim_products p ON f.product_code = p.product_code
  GROUP BY p.product_name, p.category
)
SELECT 
  product_name,
  category,
  ROUND(((revenue_after - revenue_before) / revenue_before) * 100, 2) AS `ir%`
FROM RevenueCalculation
ORDER BY `ir%` DESC
LIMIT 5;

-- Note: IR% measures revenue growth due to promotions.

