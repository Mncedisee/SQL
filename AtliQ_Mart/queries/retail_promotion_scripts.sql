-- Overall uplift for each campaign
SELECT 
    c.campaign_name,
    SUM(e.`quantity_sold(before_promo)`) AS total_before,
    SUM(e.`quantity_sold(after_promo)`) AS total_after,
    SUM(e.`quantity_sold(after_promo)`) - SUM(e.`quantity_sold(before_promo)`) AS uplift
FROM fact_events e 
JOIN dim_campaigns c ON e.campaign_id = c.campaign_id
GROUP BY c.campaign_name;


SELECT * FROM fact_events;
SELECT * FROM dim_campaigns;
SELECT * FROM dim_products;

-- promotion_type_effectiveness.sql
-- Uplift by promotion type
SELECT 
    promo_type,
    SUM(`quantity_sold(after_promo)`) - SUM(`quantity_sold(before_promo)`) AS total_uplift
FROM fact_events
GROUP BY promo_type
ORDER BY total_uplift DESC;

-- top_categories.sql
-- Top 5 product categories by post-promo sales
SELECT 
    p.category,
    SUM(e.`quantity_sold(after_promo)`) AS total_after
FROM fact_events e
JOIN dim_products p ON e.product_code = p.product_code
GROUP BY p.category
ORDER BY total_after DESC
LIMIT 5;

-- city_campaign_uplift.sql
-- City-wise uplift from campaigns
SELECT 
    s.city,
    SUM(e.`quantity_sold(after_promo)`) - SUM(e.`quantity_sold(before_promo)`) AS uplift
FROM fact_events e
JOIN dim_stores s ON e.store_id = s.store_id
GROUP BY s.city
ORDER BY uplift DESC;

-- campaign_revenue_uplift.sql
-- Revenue uplift from each campaign
SELECT 
    c.campaign_name,
    ROUND(SUM(e.base_price * e.`quantity_sold(after_promo)`), 2) AS revenue_after,
    ROUND(SUM(e.base_price * e.`quantity_sold(before_promo)`), 2) AS revenue_before,
    ROUND(SUM(e.base_price * (e.`quantity_sold(after_promo)`) - e.`quantity_sold(before_promo)`), 2) AS revenue_uplift
FROM fact_events e
JOIN dim_campaigns c ON e.campaign_id = c.campaign_id
GROUP BY c.campaign_name;

-- product_performance_view.sql
-- Create a view for product campaign summary
CREATE VIEW vw_product_campaign_summary AS
SELECT 
    p.product_name,
    c.campaign_name,
    SUM(e.`quantity_sold(before_promo)`) AS before_qty,
    SUM(e.`quantity_sold(after_promo)`) AS after_qty,
    SUM(e.`quantity_sold(after_promo)`) - SUM(e.`quantity_sold(before_promo)`) AS uplift,
    ROUND(SUM(base_price * `quantity_sold(after_promo)`), 2) AS revenue_after
FROM fact_events e
JOIN dim_products p ON e.product_code = p.product_code
JOIN dim_campaigns c ON e.campaign_id = c.campaign_id
GROUP BY p.product_name, c.campaign_name;

SELECT * FROM vw_product_campaign_summary;

-- top_products_per_campaign.sql
-- Top 5 products by campaign using window functions
SELECT *
FROM (
    SELECT 
        p.product_name,
        c.campaign_name,
        SUM(e.`quantity_sold(before_promo)`) AS total_qty,
        RANK() OVER (PARTITION BY c.campaign_name ORDER BY SUM(e.`quantity_sold(after_promo)`) DESC) AS rnk
    FROM fact_events e
    JOIN dim_products p ON e.product_code = p.product_code
    JOIN dim_campaigns c ON e.campaign_id = c.campaign_id
    GROUP BY p.product_name, c.campaign_name
) ranked
WHERE rnk <= 5;
