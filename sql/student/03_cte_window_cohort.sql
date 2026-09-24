
-- =========================================================
-- PHẦN 1.1 - CTE
-- =========================================================

-- CTE1: TOP 10 CUSTOMERS BY TOTAL SPENDING
WITH customer_spending AS (
    SELECT
        customer_id,
        SUM(order_total) AS total_spending
    FROM orders
    GROUP BY customer_id
)
SELECT
    customer_id,
    total_spending
FROM customer_spending
ORDER BY total_spending DESC
LIMIT 10;


-- =========================================================
-- CTE2: CUSTOMER SPENDING SEGMENT
-- Low < 500 / Medium 500-2000 / High > 2000
-- =========================================================

WITH customer_spending AS (
    SELECT
        customer_id,
        SUM(order_total) AS total_spending
    FROM orders
    GROUP BY customer_id
)
SELECT
    customer_id,
    total_spending,
    CASE
        WHEN total_spending < 500 THEN 'Low'
        WHEN total_spending <= 2000 THEN 'Medium'
        ELSE 'High'
    END AS spending_segment
FROM customer_spending
ORDER BY total_spending DESC;


-- =========================================================
-- CTE3: MULTIPLE / NESTED CTE
-- CTE 1: đếm order/customer
-- CTE 2: tính MAX và AVG từ CTE 1
-- =========================================================

WITH orders_per_customer AS (
    SELECT
        customer_id,
        COUNT(order_id) AS order_count
    FROM orders
    GROUP BY customer_id
),
customer_stats AS (
    SELECT
        MAX(order_count) AS max_orders,
        AVG(order_count) AS avg_orders
    FROM orders_per_customer
)
SELECT
    max_orders,
    avg_orders
FROM customer_stats;


-- =========================================================
-- CTE4: AOV PER CUSTOMER
-- AOV = Total Spending / Order Count
-- =========================================================

WITH customer_stats AS (
    SELECT
        customer_id,
        COUNT(order_id) AS order_count,
        SUM(order_total) AS total_spending
    FROM orders
    GROUP BY customer_id
)
SELECT
    customer_id,
    order_count,
    total_spending,
    ROUND(
        total_spending / NULLIF(order_count, 0),
        2
    ) AS aov
FROM customer_stats
ORDER BY aov DESC;


-- =========================================================
-- CTE5: SIMPLE RETENTION
-- Cohort = tháng order đầu tiên của customer
-- =========================================================

WITH customer_cohort AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM orders
    GROUP BY customer_id
),
customer_months AS (
    SELECT DISTINCT
        customer_id,
        DATE_TRUNC('month', order_date) AS order_month
    FROM orders
),
cohort_activity AS (
    SELECT
        c.cohort_month,
        cm.order_month,
        COUNT(DISTINCT cm.customer_id) AS active_customers
    FROM customer_cohort c
    JOIN customer_months cm
        ON c.customer_id = cm.customer_id
    GROUP BY
        c.cohort_month,
        cm.order_month
)
SELECT
    cohort_month,
    order_month,
    active_customers
FROM cohort_activity
ORDER BY
    cohort_month,
    order_month;


-- =========================================================
-- PHẦN 1.2 - WINDOW FUNCTIONS
-- =========================================================

-- W1: ROW_NUMBER - RANK CUSTOMERS BY SPENDING

WITH customer_spending AS (
    SELECT
        customer_id,
        SUM(order_total) AS total_spending
    FROM orders
    GROUP BY customer_id
)
SELECT
    customer_id,
    total_spending,
    ROW_NUMBER() OVER (
        ORDER BY total_spending DESC
    ) AS customer_rank
FROM customer_spending
ORDER BY customer_rank;


-- =========================================================
-- W2: RANK VS DENSE_RANK
--
-- RANK():
-- Nếu có đồng hạng thì thứ hạng phía sau bị nhảy số.
-- Ví dụ: 1, 2, 2, 4
--
-- DENSE_RANK():
-- Nếu có đồng hạng thì thứ hạng phía sau không bị nhảy.
-- Ví dụ: 1, 2, 2, 3
-- =========================================================

WITH customer_spending AS (
    SELECT
        customer_id,
        SUM(order_total) AS total_spending
    FROM orders
    GROUP BY customer_id
)
SELECT
    customer_id,
    total_spending,
    RANK() OVER (
        ORDER BY total_spending DESC
    ) AS rank_position,
    DENSE_RANK() OVER (
        ORDER BY total_spending DESC
    ) AS dense_rank_position
FROM customer_spending
ORDER BY total_spending DESC;


-- =========================================================
-- W3: ORDER SEQUENCE PER CUSTOMER
-- =========================================================

SELECT
    order_id,
    customer_id,
    order_date,
    order_total,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY order_date
    ) AS order_number
FROM orders
ORDER BY
    customer_id,
    order_date;


-- =========================================================
-- W4: LAG / LEAD
-- So sánh order hiện tại với order trước và sau
-- =========================================================

SELECT
    order_id,
    customer_id,
    order_date,
    order_total,

    LAG(order_total) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
    ) AS previous_order_total,

    LEAD(order_total) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
    ) AS next_order_total,

    order_total
        - LAG(order_total) OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        ) AS difference_from_previous

FROM orders
ORDER BY
    customer_id,
    order_date;


-- =========================================================
-- W5: CUMULATIVE REVENUE
-- =========================================================

SELECT
    order_id,
    order_date,
    order_total,
    SUM(order_total) OVER (
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue
FROM orders
ORDER BY order_date;


-- =========================================================
-- PHẦN 1.3 - RFM ANALYSIS
-- Recency / Frequency / Monetary
-- =========================================================

SELECT
    customer_id,

    CURRENT_DATE
        - MAX(order_date::date) AS recency_days,

    COUNT(order_id) AS frequency,

    SUM(order_total) AS monetary

FROM orders
GROUP BY customer_id
ORDER BY monetary DESC;


-- =========================================================
-- PHẦN 1.4 - COHORT ANALYSIS
-- Retention theo tháng: M0, M1, M2, M3
-- =========================================================

WITH customer_cohort AS (

    -- Xác định cohort month của mỗi customer
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM orders
    GROUP BY customer_id

),

customer_orders AS (

    -- Các tháng customer có phát sinh order
    SELECT DISTINCT
        customer_id,
        DATE_TRUNC('month', order_date) AS order_month
    FROM orders

),

cohort_activity AS (

    -- Xác định customer hoạt động ở tháng thứ mấy
    SELECT
        c.customer_id,
        c.cohort_month,
        o.order_month,
        (
            EXTRACT(YEAR FROM o.order_month)
            - EXTRACT(YEAR FROM c.cohort_month)
        ) * 12
        +
        (
            EXTRACT(MONTH FROM o.order_month)
            - EXTRACT(MONTH FROM c.cohort_month)
        ) AS month_number
    FROM customer_cohort c
    JOIN customer_orders o
        ON c.customer_id = o.customer_id

),

cohort_size AS (

    -- Số customer ban đầu của mỗi cohort
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_customers
    FROM customer_cohort
    GROUP BY cohort_month

),

retention AS (

    -- Số customer active tại từng tháng
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM cohort_activity
    GROUP BY
        cohort_month,
        month_number

)

SELECT
    r.cohort_month,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN r.month_number = 0
                THEN r.active_customers
                ELSE 0
            END
        ) / MAX(c.cohort_customers),
        2
    ) AS m0,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN r.month_number = 1
                THEN r.active_customers
                ELSE 0
            END
        ) / MAX(c.cohort_customers),
        2
    ) AS m1,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN r.month_number = 2
                THEN r.active_customers
                ELSE 0
            END
        ) / MAX(c.cohort_customers),
        2
    ) AS m2,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN r.month_number = 3
                THEN r.active_customers
                ELSE 0
            END
        ) / MAX(c.cohort_customers),
        2
    ) AS m3

FROM retention r
JOIN cohort_size c
    ON r.cohort_month = c.cohort_month
GROUP BY r.cohort_month
ORDER BY r.cohort_month;


-- =========================================================
-- BONUS 2.1 - RFM SEGMENT
-- Score 1-5 cho R/F/M
-- =========================================================

WITH rfm AS (

    SELECT
        customer_id,
        CURRENT_DATE - MAX(order_date::date) AS recency_days,
        COUNT(order_id) AS frequency,
        SUM(order_total) AS monetary
    FROM orders
    GROUP BY customer_id

),

rfm_score AS (

    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,

        -- Recency nhỏ hơn = tốt hơn
        NTILE(5) OVER (
            ORDER BY recency_days DESC
        ) AS r_score,

        -- Frequency lớn hơn = tốt hơn
        NTILE(5) OVER (
            ORDER BY frequency
        ) AS f_score,

        -- Monetary lớn hơn = tốt hơn
        NTILE(5) OVER (
            ORDER BY monetary
        ) AS m_score

    FROM rfm

)

SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_segment
FROM rfm_score
ORDER BY monetary DESC;


-- =========================================================
-- BONUS 2.2 - TIME SERIES
-- MoM growth theo tháng
-- =========================================================

WITH monthly_revenue AS (

    SELECT
        DATE_TRUNC('month', order_date) AS revenue_month,
        SUM(order_total) AS revenue
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date)

)

SELECT
    revenue_month,
    revenue,

    LAG(revenue) OVER (
        ORDER BY revenue_month
    ) AS previous_month_revenue,

    ROUND(
        100.0 *
        (
            revenue
            - LAG(revenue) OVER (
                ORDER BY revenue_month
            )
        )
        /
        NULLIF(
            LAG(revenue) OVER (
                ORDER BY revenue_month
            ),
            0
        ),
        2
    ) AS mom_growth_pct

FROM monthly_revenue
ORDER BY revenue_month;


-- =========================================================
-- BONUS 2.2 - TIME SERIES
-- Moving Average 7 ngày / 30 ngày
-- =========================================================

WITH daily_revenue AS (

    SELECT
        order_date::date AS revenue_date,
        SUM(order_total) AS revenue
    FROM orders
    GROUP BY order_date::date

)

SELECT
    revenue_date,
    revenue,

    ROUND(
        AVG(revenue) OVER (
            ORDER BY revenue_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_7d,

    ROUND(
        AVG(revenue) OVER (
            ORDER BY revenue_date
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_30d

FROM daily_revenue
ORDER BY revenue_date;
