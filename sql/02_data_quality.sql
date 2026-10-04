-- ============================================================
-- 02. Data Quality Check
-- GA4 Ecommerce Conversion Analysis
-- Dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- ============================================================


-- 1. Check missing user IDs
SELECT
    COUNT(*) AS total_events,
    COUNTIF(user_pseudo_id IS NOT NULL) AS available_user_ids,
    COUNTIF(user_pseudo_id IS NULL) AS missing_user_ids
FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`;


-- 2. Check missing timestamps
SELECT
    COUNT(*) AS total_events,
    COUNTIF(event_timestamp IS NOT NULL) AS available_timestamps,
    COUNTIF(event_timestamp IS NULL) AS missing_timestamps
FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`;


-- 3. Purchase event completeness
SELECT
    COUNT(*) AS purchase_events,

    COUNTIF(
        ecommerce.transaction_id IS NOT NULL
    ) AS transactions_with_id,

    COUNTIF(
        ecommerce.purchase_revenue IS NOT NULL
    ) AS purchases_with_revenue,

    COUNTIF(
        ecommerce.transaction_id IS NULL
    ) AS missing_transaction_id,

    COUNTIF(
        ecommerce.purchase_revenue IS NULL
    ) AS missing_revenue

FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

WHERE
    event_name = 'purchase';


-- 4. Revenue range and abnormal values
SELECT
    MIN(ecommerce.purchase_revenue) AS min_revenue,
    MAX(ecommerce.purchase_revenue) AS max_revenue,
    AVG(ecommerce.purchase_revenue) AS avg_revenue,

    COUNTIF(
        ecommerce.purchase_revenue <= 0
    ) AS non_positive_revenue

FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

WHERE
    event_name = 'purchase'
    AND ecommerce.purchase_revenue IS NOT NULL;


-- 5. Item-level completeness across all events
SELECT
    COUNT(*) AS item_rows,

    COUNTIF(item.item_name IS NOT NULL)
        AS available_item_names,

    COUNTIF(item.item_name IS NULL)
        AS missing_item_names,

    COUNTIF(item.price IS NOT NULL)
        AS available_prices,

    COUNTIF(item.price IS NULL)
        AS missing_prices

FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
    UNNEST(items) AS item;


-- 6. Purchased item completeness
SELECT
    COUNT(*) AS purchased_items,

    COUNTIF(item.item_id IS NOT NULL)
        AS items_with_id,

    COUNTIF(item.item_name IS NOT NULL)
        AS items_with_name,

    COUNTIF(item.price IS NOT NULL)
        AS items_with_price,

    COUNTIF(item.quantity IS NOT NULL)
        AS items_with_quantity,

    COUNTIF(item.price IS NULL)
        AS missing_price,

    COUNTIF(item.quantity IS NULL)
        AS missing_quantity

FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
    UNNEST(items) AS item

WHERE
    event_name = 'purchase';
