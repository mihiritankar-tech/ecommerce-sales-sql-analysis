-- =====================================================================
-- 03 | SALES TRENDS
-- Business question: How are sales changing over time? Is there seasonality?
-- Note: strftime() is SQLite. PostgreSQL: TO_CHAR(order_date,'YYYY-MM'),
--       MySQL: DATE_FORMAT(order_date,'%Y-%m')
-- =====================================================================

-- Q2. Monthly revenue with month-over-month growth (window function LAG)
WITH monthly AS (
    SELECT strftime('%Y-%m', o.order_date)                        AS month,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount))   AS revenue,
           COUNT(DISTINCT o.order_id)                             AS orders
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'Delivered'
    GROUP BY strftime('%Y-%m', o.order_date)
)
SELECT month,
       ROUND(revenue, 2)                                                    AS revenue,
       orders,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
             / LAG(revenue) OVER (ORDER BY month), 1)                       AS mom_growth_pct
FROM monthly
ORDER BY month;

-- Q3. Year-over-year comparison
SELECT strftime('%Y', o.order_date)                                       AS year,
       ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2)     AS revenue,
       COUNT(DISTINCT o.order_id)                                         AS orders,
       COUNT(DISTINCT o.customer_id)                                      AS customers
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'Delivered'
GROUP BY strftime('%Y', o.order_date)
ORDER BY year;

-- Q4. Seasonality: share of revenue earned in each calendar month (both years combined)
WITH by_month AS (
    SELECT CAST(strftime('%m', o.order_date) AS INTEGER)            AS month_num,
           SUM(oi.quantity * oi.unit_price * (1 - oi.discount))     AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'Delivered'
    GROUP BY CAST(strftime('%m', o.order_date) AS INTEGER)
)
SELECT month_num,
       ROUND(revenue, 2)                                       AS revenue,
       ROUND(100.0 * revenue / SUM(revenue) OVER (), 1)        AS pct_of_annual_revenue
FROM by_month
ORDER BY month_num;
