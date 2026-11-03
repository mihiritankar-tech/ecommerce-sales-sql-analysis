-- =====================================================================
-- 05 | CUSTOMER ANALYSIS
-- Business question: Who are our best customers, and do customers come back?
-- =====================================================================

-- Q8. Top 10 customers by lifetime revenue
WITH customer_value AS (
    SELECT c.customer_id,
           c.customer_name,
           c.segment,
           c.region,
           COUNT(DISTINCT o.order_id)                                AS orders,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount))      AS lifetime_revenue
    FROM customers c
    JOIN orders      o  ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id   = o.order_id
    WHERE o.status = 'Delivered'
    GROUP BY c.customer_id, c.customer_name, c.segment, c.region
)
SELECT DENSE_RANK() OVER (ORDER BY lifetime_revenue DESC)   AS rank,
       customer_name, segment, region, orders,
       ROUND(lifetime_revenue, 2)                           AS lifetime_revenue
FROM customer_value
ORDER BY lifetime_revenue DESC
LIMIT 10;

-- Q9. Revenue concentration: what share of revenue comes from the top 20% of customers?
WITH customer_value AS (
    SELECT o.customer_id,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'Delivered'
    GROUP BY o.customer_id
),
ranked AS (
    SELECT revenue, NTILE(5) OVER (ORDER BY revenue DESC) AS quintile
    FROM customer_value
)
SELECT quintile                                                   AS customer_quintile,
       COUNT(*)                                                   AS customers,
       ROUND(SUM(revenue), 2)                                     AS revenue,
       ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1) AS pct_of_revenue
FROM ranked
GROUP BY quintile
ORDER BY quintile;

-- Q10. Repeat purchase rate: one-time vs repeat customers
WITH order_counts AS (
    SELECT customer_id, COUNT(*) AS orders
    FROM orders
    WHERE status = 'Delivered'
    GROUP BY customer_id
)
SELECT CASE WHEN orders = 1 THEN '1 order (one-time)'
            WHEN orders BETWEEN 2 AND 3 THEN '2-3 orders'
            WHEN orders BETWEEN 4 AND 6 THEN '4-6 orders'
            ELSE '7+ orders (loyal)' END                       AS customer_group,
       COUNT(*)                                                AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)      AS pct_of_customers
FROM order_counts
GROUP BY CASE WHEN orders = 1 THEN '1 order (one-time)'
              WHEN orders BETWEEN 2 AND 3 THEN '2-3 orders'
              WHEN orders BETWEEN 4 AND 6 THEN '4-6 orders'
              ELSE '7+ orders (loyal)' END
ORDER BY MIN(orders);

-- Q11. Performance by customer segment
SELECT c.segment,
       COUNT(DISTINCT c.customer_id)                                                    AS customers,
       COUNT(DISTINCT o.order_id)                                                       AS orders,
       ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2)                   AS revenue,
       ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount))
             / COUNT(DISTINCT o.order_id), 2)                                           AS avg_order_value,
       ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount))
             / COUNT(DISTINCT c.customer_id), 2)                                        AS revenue_per_customer
FROM customers c
JOIN orders      o  ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
WHERE o.status = 'Delivered'
GROUP BY c.segment
ORDER BY revenue DESC;
