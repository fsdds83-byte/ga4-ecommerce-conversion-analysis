-- ============================================================
-- 01. Data Discovery
-- GA4 Ecommerce Conversion Analysis
-- Dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- ============================================================


-- 1. Date range and total event volume
SELECT
    MIN(event_date) AS start_date,
    MAX(event_date) AS end_date,
    COUNT(*) AS total_events
FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`;


-- 2. Event distribution
SELECT
    event_name,
    COUNT(*) AS events
FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
GROUP BY
    event_name
ORDER BY
    events DESC;


-- 3. User volume
SELECT
    COUNT(*) AS total_events,
    COUNT(DISTINCT user_pseudo_id) AS unique_users
FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`;


-- 4. Users and events by country
SELECT
    geo.country AS country,
    COUNT(DISTINCT user_pseudo_id) AS users,
    COUNT(*) AS events
FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
GROUP BY
    country
ORDER BY
    users DESC;


-- 5. Users and events by device
SELECT
    device.category AS device_type,
    COUNT(DISTINCT user_pseudo_id) AS users,
    COUNT(*) AS events
FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
GROUP BY
    device_type
ORDER BY
    users DESC;


-- 6. Session overview
WITH user_sessions AS (
    SELECT
        user_pseudo_id,
        COUNTIF(event_name = 'session_start') AS sessions
    FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    GROUP BY
        user_pseudo_id
)

SELECT
    SUM(sessions) AS total_sessions,
    COUNTIF(sessions > 0) AS users_with_sessions,
    ROUND(
        SAFE_DIVIDE(
            SUM(sessions),
            COUNTIF(sessions > 0)
        ),
        2
    ) AS avg_sessions_per_user
FROM
    user_sessions;


-- 7. Traffic source / medium overview
SELECT
    traffic_source.source AS source,
    traffic_source.medium AS medium,
    COUNT(DISTINCT user_pseudo_id) AS users
FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
GROUP BY
    source,
    medium
ORDER BY
    users DESC;
