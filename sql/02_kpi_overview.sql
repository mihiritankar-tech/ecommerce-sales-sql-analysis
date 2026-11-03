-- =====================================================================
-- 02 | KPI OVERVIEW
-- Business question: How is the business performing overall?
-- Net revenue = quantity * unit_price * (1 - discount), Delivered orders only
-- =====================================================================

-- Q1. Headline KPIs: revenue, profit, orders, customers, average order value
WITH delivered_items AS (
    SELECT o.order_id,
           o.customer_id,
           oi.quantity * oi.unit_price * (1 - oi.discount)                    AS net_revenue,
           oi.quantity * (oi.unit_price * (1 - oi.discount) - p.unit_cost)    AS gross_profit
    FROM orders o
    JOIN order_items oi ON oi.order_id  = o.order_id
    JOIN products    p  ON p.product_id = oi.product_id
    WHERE o.status = 'Delivered'
)
SELECT ROUND(SUM(net_revenue), 2)                                  AS total_revenue,
       ROUND(SUM(gross_profit), 2)                                 AS total_profit,
       ROUND(100.0 * SUM(gross_profit) / SUM(net_revenue), 1)      AS profit_margin_pct,
       COUNT(DISTINCT order_id)                                    AS total_orders,
       COUNT(DISTINCT customer_id)                                 AS active_customers,
       ROUND(SUM(net_revenue) / COUNT(DISTINCT order_id), 2)       AS avg_order_value
FROM delivered_items;
