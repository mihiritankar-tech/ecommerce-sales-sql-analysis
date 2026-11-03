-- =====================================================================
-- 06 | REGIONAL, CHANNEL & OPERATIONS ANALYSIS
-- Business question: Where and how do we sell, and where are we losing money?
-- =====================================================================

-- Q12. Revenue by region with share of total
SELECT c.region,
       COUNT(DISTINCT c.customer_id)                                          AS customers,
       ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2)         AS revenue,
       ROUND(100.0 * SUM(oi.quantity * oi.unit_price * (1 - oi.discount))
             / SUM(SUM(oi.quantity * oi.unit_price * (1 - oi.discount))) OVER (), 1) AS pct_of_revenue
FROM customers c
JOIN orders      o  ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
WHERE o.status = 'Delivered'
GROUP BY c.region
ORDER BY revenue DESC;

-- Q13. Sales channel performance
SELECT o.channel,
       COUNT(DISTINCT o.order_id)                                             AS orders,
       ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2)         AS revenue,
       ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount))
             / COUNT(DISTINCT o.order_id), 2)                                 AS avg_order_value
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'Delivered'
GROUP BY o.channel
ORDER BY revenue DESC;

-- Q14. Return and cancellation rate by category (lost revenue)
SELECT p.category,
       COUNT(DISTINCT o.order_id)                                                         AS orders,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.status = 'Returned'  THEN o.order_id END)
             / COUNT(DISTINCT o.order_id), 1)                                             AS return_rate_pct,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.status = 'Cancelled' THEN o.order_id END)
             / COUNT(DISTINCT o.order_id), 1)                                             AS cancel_rate_pct,
       ROUND(SUM(CASE WHEN o.status <> 'Delivered'
                      THEN oi.quantity * oi.unit_price * (1 - oi.discount) ELSE 0 END), 2) AS lost_revenue
FROM orders o
JOIN order_items oi ON oi.order_id  = o.order_id
JOIN products    p  ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY lost_revenue DESC;

-- Q15. Discount impact: does discounting hurt profit margin?
SELECT CASE WHEN oi.discount = 0 THEN 'No discount'
            ELSE CAST(CAST(oi.discount * 100 AS INTEGER) AS TEXT) || '% off' END            AS discount_level,
       COUNT(*)                                                                             AS line_items,
       ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2)                       AS revenue,
       ROUND(100.0 * SUM(oi.quantity * (oi.unit_price * (1 - oi.discount) - p.unit_cost))
             / SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 1)                     AS margin_pct
FROM orders o
JOIN order_items oi ON oi.order_id  = o.order_id
JOIN products    p  ON p.product_id = oi.product_id
WHERE o.status = 'Delivered'
GROUP BY oi.discount
ORDER BY oi.discount;
