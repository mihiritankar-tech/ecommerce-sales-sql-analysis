-- =====================================================================
-- 04 | PRODUCT ANALYSIS
-- Business question: Which categories and products drive revenue and profit?
-- =====================================================================

-- Q5. Revenue, profit and margin by category
SELECT p.category,
       ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2)                  AS revenue,
       ROUND(SUM(oi.quantity * (oi.unit_price * (1 - oi.discount) - p.unit_cost)), 2)  AS profit,
       ROUND(100.0 * SUM(oi.quantity * (oi.unit_price * (1 - oi.discount) - p.unit_cost))
             / SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 1)                AS margin_pct,
       SUM(oi.quantity)                                                                AS units_sold
FROM orders o
JOIN order_items oi ON oi.order_id  = o.order_id
JOIN products    p  ON p.product_id = oi.product_id
WHERE o.status = 'Delivered'
GROUP BY p.category
ORDER BY revenue DESC;

-- Q6. Top 10 products by revenue, with their rank inside their category
WITH product_sales AS (
    SELECT p.product_name,
           p.category,
           SUM(oi.quantity)                                          AS units_sold,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount))      AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id  = o.order_id
    JOIN products    p  ON p.product_id = oi.product_id
    WHERE o.status = 'Delivered'
    GROUP BY p.product_name, p.category
)
SELECT RANK() OVER (ORDER BY revenue DESC)                          AS overall_rank,
       product_name,
       category,
       units_sold,
       ROUND(revenue, 2)                                            AS revenue,
       RANK() OVER (PARTITION BY category ORDER BY revenue DESC)    AS rank_in_category
FROM product_sales
ORDER BY revenue DESC
LIMIT 10;

-- Q7. Bottom 5 products by revenue (candidates for review / promotion)
--     LEFT JOIN keeps products even if they never sold
WITH delivered_sales AS (
    SELECT oi.product_id,
           SUM(oi.quantity)                                        AS units_sold,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount))    AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'Delivered'
    GROUP BY oi.product_id
)
SELECT p.product_name,
       p.category,
       COALESCE(ds.units_sold, 0)              AS units_sold,
       ROUND(COALESCE(ds.revenue, 0), 2)       AS revenue
FROM products p
LEFT JOIN delivered_sales ds ON ds.product_id = p.product_id
ORDER BY revenue ASC
LIMIT 5;
