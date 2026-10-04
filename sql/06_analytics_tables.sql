-- ============================================================
-- 06. Analytics Tables for Power BI
-- GA4 Ecommerce Conversion Analysis
-- ============================================================


-- ------------------------------------------------------------
-- 1. Monthly revenue
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE
`ga4-ecommerce-project-510513.ga4_analysis.revenue_monthly`
AS

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


-- ------------------------------------------------------------
-- 2. Revenue by country
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE
`ga4-ecommerce-project-510513.ga4_analysis.revenue_by_country`
AS

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


-- ------------------------------------------------------------
-- 3. Channel performance
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE
`ga4-ecommerce-project-510513.ga4_analysis.channel_performance`
AS

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


-- ------------------------------------------------------------
-- 4. Product performance
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE
`ga4-ecommerce-project-510513.ga4_analysis.product_performance`
AS

SELECT
    item.item_name,

    COUNT(DISTINCT ecommerce.transaction_id)
        AS transactions,

    SUM(item.quantity)
        AS items_sold,

    ROUND(
        SUM(item.quantity * item.price),
        2
    ) AS revenue

FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
    UNNEST(items) AS item

WHERE
    event_name = 'purchase'
    AND ecommerce.transaction_id IS NOT NULL

GROUP BY
    item.item_name

ORDER BY
    revenue DESC;


-- ------------------------------------------------------------
-- 5. Customer metrics
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE
`ga4-ecommerce-project-510513.ga4_analysis.customer_metrics`
AS

WITH customer_orders AS (
    SELECT
        user_pseudo_id,

        COUNT(DISTINCT ecommerce.transaction_id)
            AS orders,

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
        user_pseudo_id
)

SELECT
    user_pseudo_id,
    orders,
    revenue,

    CASE
        WHEN orders = 1 THEN 'One-time customer'
        WHEN orders > 1 THEN 'Returning customer'
    END AS customer_type

FROM
    customer_orders;


-- ------------------------------------------------------------
-- 6. Funnel metrics
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE
`ga4-ecommerce-project-510513.ga4_analysis.funnel_metrics`
AS

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


-- ------------------------------------------------------------
-- 7. Product conversion
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE
`ga4-ecommerce-project-510513.ga4_analysis.product_conversion`
AS

WITH product_events AS (
    SELECT
        item.item_name,

        COUNT(DISTINCT IF(
            event_name = 'view_item',
            user_pseudo_id,
            NULL
        )) AS viewed_users,

        COUNT(DISTINCT IF(
            event_name = 'add_to_cart',
            user_pseudo_id,
            NULL
        )) AS cart_users,

        COUNT(DISTINCT IF(
            event_name = 'purchase',
            user_pseudo_id,
            NULL
        )) AS purchased_users

    FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
        UNNEST(items) AS item

    WHERE
        event_name IN (
            'view_item',
            'add_to_cart',
            'purchase'
        )

    GROUP BY
        item.item_name
)

SELECT
    item_name,
    viewed_users,
    cart_users,
    purchased_users,

    ROUND(
        SAFE_DIVIDE(
            cart_users,
            viewed_users
        ),
        4
    ) AS view_to_cart_rate,

    ROUND(
        SAFE_DIVIDE(
            purchased_users,
            viewed_users
        ),
        4
    ) AS view_to_purchase_rate

FROM
    product_events;


-- ------------------------------------------------------------
-- 8. Marketing channels
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE
`ga4-ecommerce-project-510513.ga4_analysis.marketing_channels`
AS

SELECT
    CASE
        WHEN traffic_source.source = '(direct)'
            THEN 'Direct'

        WHEN traffic_source.medium = 'organic'
            THEN 'Organic Search'

        WHEN traffic_source.medium = 'cpc'
            THEN 'Paid Search'

        WHEN traffic_source.medium = 'referral'
            THEN 'Referral'

        ELSE 'Other'
    END AS marketing_channel,

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
    marketing_channel

ORDER BY
    revenue DESC;
