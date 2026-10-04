-- ============================================================
-- 03. Business Metrics
-- GA4 Ecommerce Conversion Analysis
-- Dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- ============================================================


-- 1. Overall ecommerce KPIs
SELECT
    COUNT(*) AS purchase_events,

    COUNT(DISTINCT ecommerce.transaction_id)
        AS transactions,

    ROUND(
        SUM(ecommerce.purchase_revenue),
        2
    ) AS total_revenue,

    ROUND(
        SAFE_DIVIDE(
            SUM(ecommerce.purchase_revenue),
            COUNT(DISTINCT ecommerce.transaction_id)
        ),
        2
    ) AS average_order_value

FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

WHERE
    event_name = 'purchase'
    AND ecommerce.transaction_id IS NOT NULL
    AND ecommerce.purchase_revenue IS NOT NULL;


-- 2. Monthly revenue trend
SELECT
    FORMAT_DATE(
        '%Y-%m',
        PARSE_DATE('%Y%m%d', event_date)
    ) AS month,

    COUNT(DISTINCT ecommerce.transaction_id)
        AS transactions,

    ROUND(
        SUM(ecommerce.purchase_revenue),
        2
    ) AS revenue

FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

WHERE
    event_name = 'purchase'
    AND ecommerce.transaction_id IS NOT NULL
    AND ecommerce.purchase_revenue IS NOT NULL

GROUP BY
    month

ORDER BY
    month;


-- 3. Revenue by country
SELECT
    geo.country AS country,

    COUNT(DISTINCT ecommerce.transaction_id)
        AS transactions,

    ROUND(
        SUM(ecommerce.purchase_revenue),
        2
    ) AS revenue,

    ROUND(
        SAFE_DIVIDE(
            SUM(ecommerce.purchase_revenue),
            COUNT(DISTINCT ecommerce.transaction_id)
        ),
        2
    ) AS average_order_value

FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

WHERE
    event_name = 'purchase'
    AND ecommerce.transaction_id IS NOT NULL
    AND ecommerce.purchase_revenue IS NOT NULL

GROUP BY
    country

ORDER BY
    revenue DESC;


-- 4. Revenue by traffic source / medium
SELECT
    traffic_source.source AS source,
    traffic_source.medium AS medium,

    COUNT(DISTINCT ecommerce.transaction_id)
        AS transactions,

    ROUND(
        SUM(ecommerce.purchase_revenue),
        2
    ) AS revenue,

    ROUND(
        SAFE_DIVIDE(
            SUM(ecommerce.purchase_revenue),
            COUNT(DISTINCT ecommerce.transaction_id)
        ),
        2
    ) AS average_order_value

FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

WHERE
    event_name = 'purchase'
    AND ecommerce.transaction_id IS NOT NULL
    AND ecommerce.purchase_revenue IS NOT NULL

GROUP BY
    source,
    medium

ORDER BY
    revenue DESC;


-- 5. Ecommerce conversion funnel
SELECT
    event_name,

    COUNT(DISTINCT user_pseudo_id)
        AS users,

    CASE
        WHEN event_name = 'view_item' THEN 1
        WHEN event_name = 'add_to_cart' THEN 2
        WHEN event_name = 'begin_checkout' THEN 3
        WHEN event_name = 'purchase' THEN 4
    END AS funnel_step

FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

WHERE
    event_name IN (
        'view_item',
        'add_to_cart',
        'begin_checkout',
        'purchase'
    )

GROUP BY
    event_name

ORDER BY
    funnel_step;


-- 6. Funnel conversion rates
WITH funnel AS (
    SELECT
        COUNT(DISTINCT IF(
            event_name = 'view_item',
            user_pseudo_id,
            NULL
        )) AS view_users,

        COUNT(DISTINCT IF(
            event_name = 'add_to_cart',
            user_pseudo_id,
            NULL
        )) AS cart_users,

        COUNT(DISTINCT IF(
            event_name = 'begin_checkout',
            user_pseudo_id,
            NULL
        )) AS checkout_users,

        COUNT(DISTINCT IF(
            event_name = 'purchase',
            user_pseudo_id,
            NULL
        )) AS purchase_users

    FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

    WHERE
        event_name IN (
            'view_item',
            'add_to_cart',
            'begin_checkout',
            'purchase'
        )
)

SELECT
    view_users,
    cart_users,
    checkout_users,
    purchase_users,

    ROUND(
        SAFE_DIVIDE(cart_users, view_users) * 100,
        2
    ) AS view_to_cart_rate,

    ROUND(
        SAFE_DIVIDE(checkout_users, cart_users) * 100,
        2
    ) AS cart_to_checkout_rate,

    ROUND(
        SAFE_DIVIDE(purchase_users, checkout_users) * 100,
        2
    ) AS checkout_to_purchase_rate,

    ROUND(
        SAFE_DIVIDE(purchase_users, view_users) * 100,
        2
    ) AS overall_conversion_rate

FROM funnel;
