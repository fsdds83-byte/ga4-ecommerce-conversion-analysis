-- ============================================================
-- 05. Customer Analysis
-- GA4 Ecommerce Conversion Analysis
-- Dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- ============================================================


-- 1. Customer-level purchase metrics
WITH customer_orders AS (
    SELECT
        user_pseudo_id,

        COUNT(DISTINCT ecommerce.transaction_id)
            AS total_orders,

        ROUND(
            SUM(ecommerce.purchase_revenue),
            2
        ) AS total_revenue

    FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

    WHERE
        event_name = 'purchase'
        AND user_pseudo_id IS NOT NULL
        AND ecommerce.transaction_id IS NOT NULL
        AND ecommerce.purchase_revenue IS NOT NULL

    GROUP BY
        user_pseudo_id
)

SELECT
    user_pseudo_id,
    total_orders,
    total_revenue,

    CASE
        WHEN total_orders = 1 THEN 'one-time buyer'
        WHEN total_orders > 1 THEN 'repeat buyer'
    END AS customer_type

FROM
    customer_orders

ORDER BY
    total_revenue DESC;


-- 2. One-time vs repeat buyers
WITH customer_orders AS (
    SELECT
        user_pseudo_id,

        COUNT(DISTINCT ecommerce.transaction_id)
            AS total_orders,

        ROUND(
            SUM(ecommerce.purchase_revenue),
            2
        ) AS total_revenue

    FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

    WHERE
        event_name = 'purchase'
        AND user_pseudo_id IS NOT NULL
        AND ecommerce.transaction_id IS NOT NULL
        AND ecommerce.purchase_revenue IS NOT NULL

    GROUP BY
        user_pseudo_id
),

customer_segment AS (
    SELECT
        user_pseudo_id,
        total_orders,
        total_revenue,

        CASE
            WHEN total_orders = 1 THEN 'one-time buyer'
            WHEN total_orders > 1 THEN 'repeat buyer'
        END AS customer_type

    FROM
        customer_orders
)

SELECT
    customer_type,

    COUNT(*) AS users,

    SUM(total_orders) AS total_orders,

    ROUND(
        SUM(total_revenue),
        2
    ) AS total_revenue,

    ROUND(
        AVG(total_revenue),
        2
    ) AS avg_revenue_per_user

FROM
    customer_segment

GROUP BY
    customer_type

ORDER BY
    total_revenue DESC;


-- 3. New vs returning users
WITH user_purchase AS (
    SELECT
        user_pseudo_id,

        COUNT(DISTINCT IF(
            event_name = 'purchase',
            ecommerce.transaction_id,
            NULL
        )) AS purchase_orders

    FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

    WHERE
        user_pseudo_id IS NOT NULL

    GROUP BY
        user_pseudo_id
)

SELECT
    CASE
        WHEN purchase_orders = 0 THEN 'new_user'
        WHEN purchase_orders > 0 THEN 'returning_user'
    END AS user_segment,

    COUNT(*) AS users

FROM
    user_purchase

GROUP BY
    user_segment

ORDER BY
    users DESC;
