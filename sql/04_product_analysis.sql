-- ============================================================
-- 04. Product Analysis
-- GA4 Ecommerce Conversion Analysis
-- Dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- ============================================================


-- 1. Product revenue performance
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
    AND item.item_name IS NOT NULL
    AND item.item_name != '(not set)'

GROUP BY
    item.item_name

ORDER BY
    revenue DESC;


-- 2. Product view-to-cart and view-to-purchase conversion
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
        AND item.item_name IS NOT NULL
        AND item.item_name != '(not set)'

    GROUP BY
        item.item_name
)

SELECT
    item_name,
    viewed_users,
    cart_users,
    purchased_users,

    ROUND(
        SAFE_DIVIDE(cart_users, viewed_users) * 100,
        2
    ) AS view_to_cart_rate,

    ROUND(
        SAFE_DIVIDE(purchased_users, viewed_users) * 100,
        2
    ) AS view_to_purchase_rate

FROM
    product_events

ORDER BY
    view_to_purchase_rate DESC;


-- 3. High-interest but low-conversion products
WITH product_events AS (
    SELECT
        item.item_name,

        COUNT(DISTINCT IF(
            event_name = 'view_item',
            user_pseudo_id,
            NULL
        )) AS viewed_users,

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
            'purchase'
        )
        AND item.item_name IS NOT NULL
        AND item.item_name != '(not set)'

    GROUP BY
        item.item_name
)

SELECT
    item_name,
    viewed_users,
    purchased_users,

    ROUND(
        SAFE_DIVIDE(
            purchased_users,
            viewed_users
        ) * 100,
        2
    ) AS view_to_purchase_rate

FROM
    product_events

WHERE
    viewed_users > 1000
    AND SAFE_DIVIDE(
        purchased_users,
        viewed_users
    ) <= 0.01

ORDER BY
    viewed_users DESC;
