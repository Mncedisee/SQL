USE `retail_events_db`;

-- SCHEMA ANALYSIS AND DATA CLEANING
SELECT * FROM dim_campaigns;
SELECT * FROM dim_products;
SELECT * FROM dim_stores;
SELECT * FROM fact_events;

-- CHECKING FOR DUPLICATES
SELECT campaign_id, COUNT(*) FROM dim_campaigns GROUP BY campaign_id HAVING COUNT(*) > 1;
SELECT product_code, COUNT(*) FROM dim_products GROUP BY product_code HAVING COUNT(*) > 1;
SELECT store_id, COUNT(*) FROM dim_stores GROUP BY store_id HAVING COUNT(*) > 1;
SELECT event_id, COUNT(*) FROM fact_events GROUP BY event_id HAVING COUNT(*) > 1;

-- CHECKING FOR NULLS
SELECT COUNT(*) FROM dim_campaigns WHERE campaign_id IS NULL OR campaign_name IS NULL OR start_date IS NULL OR end_date IS NULL;
SELECT COUNT(*) FROM dim_products WHERE product_code IS NULL OR product_name IS NULL OR category IS NULL;
SELECT COUNT(*) FROM dim_stores WHERE store_id IS NULL OR city IS NULL;
SELECT COUNT(*) FROM fact_events WHERE event_id IS NULL OR store_id IS NULL OR campaign_id IS NULL OR product_code IS NULL OR base_price IS NULL OR promo_type IS NULL;

-- CREATING INDEXES
CREATE INDEX idx_fact_events_store_id ON fact_events(store_id);
CREATE INDEX idx_fact_events_campaign_id ON fact_events(campaign_id);
CREATE INDEX idx_fact_events_product_code ON fact_events(product_code);

-- Create partitioned table for optimized queries
CREATE TABLE fact_events_partitioned (
    event_id VARCHAR(50),
    store_id VARCHAR(50),
    store_number INT,
    campaign_id VARCHAR(50),
    product_code VARCHAR(50),
    base_price INT,
    promo_type VARCHAR(50),
    quantity_sold_before_promo INT,
    quantity_sold_after_promo INT
) PARTITION BY HASH(store_number) PARTITIONS 4;


-- Check the query execution plan for optimization
EXPLAIN ANALYZE
SELECT fe.store_id, ds.city, SUM(fe.`quantity_sold(after_promo)` - fe.`quantity_sold(before_promo)`) AS sales_increase
FROM fact_events fe
JOIN dim_stores ds ON fe.store_id = ds.store_id
GROUP BY fe.store_id, ds.city
ORDER BY sales_increase DESC;

-- Join fact_events with campaign, product, and store details
SELECT fe.event_id, fe.store_id, ds.city, fe.product_code, dp.product_name, dc.campaign_name, fe.promo_type, 
       fe.base_price, fe.`quantity_sold(before_promo)`, fe.`quantity_sold(after_promo)` AS quantity_sold_after_promo
FROM fact_events fe
JOIN dim_stores ds ON fe.store_id = ds.store_id
JOIN dim_products dp ON fe.product_code = dp.product_code
JOIN dim_campaigns dc ON fe.campaign_id = dc.campaign_id
LIMIT 10;

-- Best Performing Promotion Type
SELECT promo_type, SUM(`quantity_sold(after_promo)` - `quantity_sold(before_promo)`) AS total_increase
FROM fact_events
GROUP BY promo_type
ORDER BY total_increase DESC;

-- Store-Level Sales Performance
SELECT ds.city, fe.store_id, SUM(`fe`.`quantity_sold(after_promo)`) AS total_sales_after_promo
FROM fact_events fe
JOIN dim_stores ds ON fe.store_id = ds.store_id
GROUP BY ds.city, fe.store_id
ORDER BY total_sales_after_promo DESC;

-- Revenue Impact Per Campaign
SELECT dc.campaign_name, 
    ROUND(SUM(fe.base_price * `fe`.`quantity_sold(before_promo)`), 2) AS revenue_before,
    ROUND(SUM(fe.base_price * `fe`.`quantity_sold(after_promo)`), 2) AS revenue_after,
    ROUND(SUM(fe.base_price * (`fe`.`quantity_sold(after_promo)` - `fe`.`quantity_sold(before_promo)`)), 2) AS revenue_lift
FROM fact_events fe
JOIN dim_campaigns dc ON fe.campaign_id = dc.campaign_id
GROUP BY dc.campaign_name;

-- Campaign Effectiveness
SELECT dc.campaign_name, SUM(`quantity_sold(after_promo)` - `quantity_sold(before_promo)`) AS total_sales_growth
FROM fact_events fe
JOIN dim_campaigns dc ON fe.campaign_id = dc.campaign_id
GROUP BY dc.campaign_name
ORDER BY total_sales_growth DESC;

-- Total revenue generated during each campaign
SELECT 
    c.campaign_name,
    ROUND(SUM(e.base_price * e.`quantity_sold(after_promo)`), 2) AS total_revenue
FROM fact_events e
JOIN dim_campaigns c ON e.campaign_id = c.campaign_id
GROUP BY c.campaign_name;

-- Revenue increase per store during campaigns
SELECT 
    s.store_id,
    s.city,
    ROUND(SUM(e.base_price * e.`quantity_sold(before_promo)`), 2) AS revenue_before,
    ROUND(SUM(e.base_price * e.`quantity_sold(after_promo)`), 2) AS revenue_after,
    ROUND(SUM(e.base_price * (e.`quantity_sold(after_promo)` - e.`quantity_sold(before_promo)`)), 2) AS revenue_increase
FROM fact_events e
JOIN dim_stores s ON e.store_id = s.store_id
GROUP BY s.store_id, s.city
ORDER BY revenue_increase DESC;

-- Most effective promotion types by revenue impact
SELECT 
    promo_type,
    ROUND(SUM(e.base_price * (e.`quantity_sold(after_promo)` - e.`quantity_sold(before_promo)`)), 2) AS revenue_lift
FROM fact_events e
GROUP BY promo_type
ORDER BY revenue_lift DESC;

-- Campaign with highest sales uplift (units sold)
SELECT 
    c.campaign_name,
    SUM(e.`quantity_sold(after_promo)` - e.`quantity_sold(before_promo)`) AS total_uplift
FROM fact_events e
JOIN dim_campaigns c ON e.campaign_id = c.campaign_id
GROUP BY c.campaign_name
ORDER BY total_uplift DESC;

-- Top 5 stores with highest revenue during Diwali
SELECT 
    s.store_id,
    s.city,
    ROUND(SUM(e.base_price * e.`quantity_sold(after_promo)`), 2) AS diwali_revenue
FROM fact_events e
JOIN dim_campaigns c ON e.campaign_id = c.campaign_id
JOIN dim_stores s ON e.store_id = s.store_id
WHERE c.campaign_name = 'Diwali'
GROUP BY s.store_id, s.city
ORDER BY diwali_revenue DESC
LIMIT 5;

-- Promotion type usage frequency
SELECT 
    promo_type,
    COUNT(*) AS usage_count
FROM fact_events
GROUP BY promo_type
ORDER BY usage_count DESC;

-- Top 5 cities by campaign revenue
SELECT 
    s.city,
    ROUND(SUM(e.base_price * e.`quantity_sold(after_promo)`), 2) AS city_revenue
FROM fact_events e
JOIN dim_stores s ON e.store_id = s.store_id
GROUP BY s.city
ORDER BY city_revenue DESC
LIMIT 5;

-- Category-wise sales performance
SELECT 
    p.category,
    SUM(e.`quantity_sold(before_promo)`) AS sales_before,
    SUM(e.`quantity_sold(after_promo)`) AS sales_after,
    SUM(e.`quantity_sold(after_promo)` - e.`quantity_sold(before_promo)`) AS sales_lift
FROM fact_events e
JOIN dim_products p ON e.product_code = p.product_code
GROUP BY p.category
ORDER BY sales_lift DESC;

-- Summary Table for Power BI. Save processed data for visualization
DROP TABLE IF EXISTS campaign_summary;
CREATE TABLE campaign_summary AS
SELECT fe.store_id, ds.city, fe.product_code, dp.product_name, fe.promo_type, dc.campaign_name, 
       SUM(fe.`quantity_sold(after_promo)` - fe.`quantity_sold(before_promo)`) AS sales_increase, 
       SUM(fe.base_price * fe.`quantity_sold(after_promo)`) AS revenue_generated
FROM fact_events fe
JOIN dim_stores ds ON fe.store_id = ds.store_id
JOIN dim_products dp ON fe.product_code = dp.product_code
JOIN dim_campaigns dc ON fe.campaign_id = dc.campaign_id
GROUP BY fe.store_id, ds.city, fe.product_code, dp.product_name, fe.promo_type, dc.campaign_name;

SELECT * FROM campaign_summary;

-- Partitioning to improve retrieval speed for large datasets
CREATE TABLE fact_events_partitioned (
    event_id VARCHAR(50),
    store_id VARCHAR(50),
    store_number INT,  -- New integer column
    campaign_id VARCHAR(50),
    product_code VARCHAR(50),
    base_price INT,
    promo_type VARCHAR(50),
    quantity_sold_before_promo INT,
    quantity_sold_after_promo INT
)
PARTITION BY HASH(store_number)
PARTITIONS 4;

SELECT * FROM fact_events_partitioned;

-- STORED PROCEDURES:

-- % Sales growth per campaign
DROP PROCEDURE IF EXISTS campaign_sales_growth;

DELIMITER $$
CREATE PROCEDURE campaign_sales_growth()
BEGIN
    SELECT dc.campaign_name,
        ROUND(((SUM(`quantity_sold(after_promo)`) - SUM(`quantity_sold(before_promo)`)) / 
        NULLIF(SUM(`quantity_sold(before_promo)`), 0)) * 100, 2) AS percent_sales_growth
    FROM fact_events fe
    JOIN dim_campaigns dc ON fe.campaign_id = dc.campaign_id
    GROUP BY dc.campaign_name;
END$$

DELIMITER ;

CALL campaign_sales_growth();

-- Stored Procedure to Analyze Sales Increase by Campaign
DELIMITER $$
CREATE PROCEDURE GetSalesImpactByCampaign()
BEGIN
    SELECT dc.campaign_name, 
		SUM(fe.`quantity_sold(after_promo)` - fe.`quantity_sold(before_promo)`) AS sales_increase
    FROM fact_events fe
    JOIN dim_campaigns dc ON fe.campaign_id = dc.campaign_id
    GROUP BY dc.campaign_name
    ORDER BY sales_increase DESC;
END $$

DELIMITER ;

CALL GetSalesImpactByCampaign();

-- Stored Procedure to Retrieve Store Sales Performance
DELIMITER $$
CREATE PROCEDURE GetStoreSalesByCampaign(IN campaign_id VARCHAR(50))
BEGIN
    SELECT ds.city, fe.store_id, 
		SUM(`fe`.`quantity_sold(after_promo)`) AS total_sales_after_promo
    FROM fact_events fe
    JOIN dim_stores ds ON fe.store_id = ds.store_id
    WHERE fe.campaign_id = campaign_id
    GROUP BY ds.city, fe.store_id;
END$$
DELIMITER ;

CALL GetStoreSalesByCampaign('CAMP_DIW_01');

-- CTEs & Subqueries for Deep Insights

-- Top 5 Cities by Campaign Revenue
WITH city_revenue AS (
    SELECT ds.city, 
		SUM(fe.base_price * `fe`.`quantity_sold(after_promo)`) AS revenue
    FROM fact_events fe
    JOIN dim_stores ds ON fe.store_id = ds.store_id
    GROUP BY ds.city
),
total AS (SELECT SUM(revenue) AS total_revenue FROM city_revenue)
SELECT city, ROUND((revenue / total.total_revenue) * 100, 2) AS percent_contribution
FROM city_revenue, total
ORDER BY percent_contribution DESC
LIMIT 5;

-- SUBQUERIES
-- % Increase in quantity sold per product
SELECT 
    dp.product_name,
    ROUND(
        (SUM(fe.`quantity_sold(after_promo)`) - SUM(fe.`quantity_sold(before_promo)`) 
        / NULLIF(SUM(fe.`quantity_sold(before_promo)`), 0)) * 100, 2
    ) AS percent_quantity_increase
FROM fact_events fe
JOIN dim_products dp ON fe.product_code = dp.product_code
GROUP BY dp.product_name
ORDER BY percent_quantity_increase DESC;

-- Identify Products with Highest Revenue Increase
SELECT product_name,sold_before, revenue_difference
FROM (
    SELECT dp.product_name, 
		SUM(fe.base_price * fe.`quantity_sold(before_promo)`) AS sold_before,
        SUM(fe.base_price * `fe`.`quantity_sold(after_promo)`) - SUM(fe.base_price * `fe`.`quantity_sold(before_promo)`) AS revenue_difference
    FROM fact_events fe
    JOIN dim_products dp ON fe.product_code = dp.product_code
    GROUP BY dp.product_name
) AS revenue_calculation
ORDER BY revenue_difference DESC;

-- Rank Stores by Sales Improvement
SELECT store_id, city, sales_increase, 
	RANK() OVER (ORDER BY sales_increase DESC) AS store_rank
FROM (
    SELECT fe.store_id, ds.city, 
		SUM(`fe`.`quantity_sold(after_promo)` - `fe`.`quantity_sold(before_promo)`) AS sales_increase
    FROM fact_events fe
    JOIN dim_stores ds ON fe.store_id = ds.store_id
    GROUP BY fe.store_id, ds.city
) AS ranked_stores;


-- TOP 5 PRODUCTS BY SALES LIFT WITH CATEGORY AND PERFORMANCE TAG
WITH product_lift AS (
  SELECT 
    dp.product_name,
    dp.category,
    SUM(fe.`quantity_sold(after_promo)`) AS total_after,
    SUM(fe.`quantity_sold(before_promo)`) AS total_before,
    (SUM(fe.`quantity_sold(after_promo)`) - SUM(fe.`quantity_sold(before_promo)`)) AS lift
  FROM fact_events fe
  JOIN dim_products dp ON fe.product_code = dp.product_code
  GROUP BY dp.product_name, dp.category
),
ranked_products AS (
  SELECT *,
    RANK() OVER (ORDER BY lift DESC) AS `rank`,
    CASE 
      WHEN lift > 100 THEN 'High Performer'
      WHEN lift BETWEEN 50 AND 100 THEN 'Moderate Performer'
      ELSE 'Low Performer'
    END AS performance_tag
  FROM product_lift
)
SELECT *
FROM ranked_products
LIMIT 5;





