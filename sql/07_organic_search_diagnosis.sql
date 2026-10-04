-- ============================================================
-- 07. Organic Search Conversion Diagnosis
-- Custom extension of the GA4 Ecommerce Conversion Analysis
-- ============================================================


-- ------------------------------------------------------------
-- 1. Device × marketing channel View-to-Cart
-- Goal:
-- Check whether the low View-to-Cart conversion is mainly
-- associated with device differences.
-- ------------------------------------------------------------

SELECT
    device.category AS device_type,

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

    ROUND(
        SAFE_DIVIDE(
            COUNT(DISTINCT IF(
                event_name = 'add_to_cart',
                user_pseudo_id,
                NULL
            )),
            COUNT(DISTINCT IF(
                event_name = 'view_item',
                user_pseudo_id,
                NULL
            ))
        ) * 100,
        2
    ) AS view_to_cart_rate

FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

WHERE
    event_name IN (
        'view_item',
        'add_to_cart'
    )

GROUP BY
    device_type,
    marketing_channel

HAVING
    view_users >= 500

ORDER BY
    view_to_cart_rate ASC;


-- ------------------------------------------------------------
-- 2. Product × marketing channel conversion
-- Goal:
-- Identify product/channel combinations with low View-to-Cart.
-- A minimum of 300 viewers is required to reduce small-sample
-- volatility.
-- ------------------------------------------------------------

WITH product_channel AS (
    SELECT
        item.item_name,

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

        COUNT(DISTINCT IF(
            event_name = 'view_item',
            user_pseudo_id,
            NULL
        )) AS view_users,

        COUNT(DISTINCT IF(
            event_name = 'add_to_cart',
            user_pseudo_id,
            NULL
        )) AS cart_users

    FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
        UNNEST(items) AS item

    WHERE
        event_name IN (
            'view_item',
            'add_to_cart'
        )
        AND item.item_name IS NOT NULL
        AND item.item_name != '(not set)'

    GROUP BY
        item.item_name,
        marketing_channel
)

SELECT
    item_name,
    marketing_channel,
    view_users,
    cart_users,

    ROUND(
        SAFE_DIVIDE(
            cart_users,
            view_users
        ) * 100,
        2
    ) AS view_to_cart_rate

FROM
    product_channel

WHERE
    view_users >= 300

ORDER BY
    view_to_cart_rate ASC;


-- ------------------------------------------------------------
-- 3. Channel gap by product
-- Goal:
-- Compare the same product across multiple channels and measure
-- the maximum View-to-Cart gap.
-- ------------------------------------------------------------

WITH product_channel AS (
    SELECT
        item.item_name,

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

        COUNT(DISTINCT IF(
            event_name = 'view_item',
            user_pseudo_id,
            NULL
        )) AS view_users,

        COUNT(DISTINCT IF(
            event_name = 'add_to_cart',
            user_pseudo_id,
            NULL
        )) AS cart_users

    FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
        UNNEST(items) AS item

    WHERE
        event_name IN (
            'view_item',
            'add_to_cart'
        )
        AND item.item_name IS NOT NULL
        AND item.item_name != '(not set)'

    GROUP BY
        item.item_name,
        marketing_channel
),

qualified AS (
    SELECT
        item_name,
        marketing_channel,
        view_users,
        cart_users,

        SAFE_DIVIDE(
            cart_users,
            view_users
        ) * 100 AS view_to_cart_rate

    FROM
        product_channel

    WHERE
        view_users >= 300
)

SELECT
    item_name,

    COUNT(*) AS channels_compared,

    ROUND(
        MIN(view_to_cart_rate),
        2
    ) AS lowest_rate,

    ROUND(
        MAX(view_to_cart_rate),
        2
    ) AS highest_rate,

    ROUND(
        MAX(view_to_cart_rate)
        - MIN(view_to_cart_rate),
        2
    ) AS channel_gap_pp,

    ARRAY_AGG(
        marketing_channel
        ORDER BY view_to_cart_rate ASC
        LIMIT 1
    )[OFFSET(0)] AS lowest_channel,

    ARRAY_AGG(
        marketing_channel
        ORDER BY view_to_cart_rate DESC
        LIMIT 1
    )[OFFSET(0)] AS highest_channel

FROM
    qualified

GROUP BY
    item_name

HAVING
    COUNT(*) >= 2

ORDER BY
    channel_gap_pp DESC;


-- ------------------------------------------------------------
-- 4. Which channel most often underperforms?
-- Only products with a channel gap >= 5 percentage points
-- are included.
-- ------------------------------------------------------------

WITH product_channel AS (
    SELECT
        item.item_name,

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

        COUNT(DISTINCT IF(
            event_name = 'view_item',
            user_pseudo_id,
            NULL
        )) AS view_users,

        COUNT(DISTINCT IF(
            event_name = 'add_to_cart',
            user_pseudo_id,
            NULL
        )) AS cart_users

    FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
        UNNEST(items) AS item

    WHERE
        event_name IN (
            'view_item',
            'add_to_cart'
        )
        AND item.item_name IS NOT NULL
        AND item.item_name != '(not set)'

    GROUP BY
        item.item_name,
        marketing_channel
),

qualified AS (
    SELECT
        item_name,
        marketing_channel,

        SAFE_DIVIDE(
            cart_users,
            view_users
        ) * 100 AS view_to_cart_rate

    FROM
        product_channel

    WHERE
        view_users >= 300
),

product_gap AS (
    SELECT
        item_name,

        MAX(view_to_cart_rate)
        - MIN(view_to_cart_rate)
            AS channel_gap_pp,

        ARRAY_AGG(
            marketing_channel
            ORDER BY view_to_cart_rate ASC
            LIMIT 1
        )[OFFSET(0)] AS lowest_channel

    FROM
        qualified

    GROUP BY
        item_name

    HAVING
        COUNT(*) >= 2
)

SELECT
    lowest_channel,

    COUNT(*) AS products_where_lowest,

    ROUND(
        AVG(channel_gap_pp),
        2
    ) AS avg_gap_pp

FROM
    product_gap

WHERE
    channel_gap_pp >= 5

GROUP BY
    lowest_channel

ORDER BY
    products_where_lowest DESC;


-- ------------------------------------------------------------
-- 5. Matched-product Organic Search benchmark
-- Goal:
-- Compare Organic Search against the average conversion rate
-- of other channels for the same products.
-- ------------------------------------------------------------

WITH product_channel AS (
    SELECT
        item.item_name,

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

        COUNT(DISTINCT IF(
            event_name = 'view_item',
            user_pseudo_id,
            NULL
        )) AS view_users,

        COUNT(DISTINCT IF(
            event_name = 'add_to_cart',
            user_pseudo_id,
            NULL
        )) AS cart_users

    FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
        UNNEST(items) AS item

    WHERE
        event_name IN (
            'view_item',
            'add_to_cart'
        )
        AND item.item_name IS NOT NULL
        AND item.item_name != '(not set)'

    GROUP BY
        item.item_name,
        marketing_channel
),

qualified AS (
    SELECT
        item_name,
        marketing_channel,
        view_users,
        cart_users,

        SAFE_DIVIDE(
            cart_users,
            view_users
        ) AS view_to_cart_rate

    FROM
        product_channel

    WHERE
        view_users >= 300
),

product_compare AS (
    SELECT
        item_name,

        MAX(IF(
            marketing_channel = 'Organic Search',
            view_to_cart_rate,
            NULL
        )) AS organic_rate,

        AVG(IF(
            marketing_channel != 'Organic Search',
            view_to_cart_rate,
            NULL
        )) AS other_channel_avg_rate,

        COUNTIF(
            marketing_channel != 'Organic Search'
        ) AS other_channels

    FROM
        qualified

    GROUP BY
        item_name
)

SELECT
    COUNT(*) AS compared_products,

    COUNTIF(
        organic_rate < other_channel_avg_rate
    ) AS organic_lower_products,

    ROUND(
        SAFE_DIVIDE(
            COUNTIF(
                organic_rate < other_channel_avg_rate
            ),
            COUNT(*)
        ) * 100,
        2
    ) AS organic_lower_share,

    ROUND(
        AVG(organic_rate) * 100,
        2
    ) AS avg_organic_rate,

    ROUND(
        AVG(other_channel_avg_rate) * 100,
        2
    ) AS avg_other_channel_rate,

    ROUND(
        AVG(
            other_channel_avg_rate
            - organic_rate
        ) * 100,
        2
    ) AS avg_gap_pp

FROM
    product_compare

WHERE
    organic_rate IS NOT NULL
    AND other_channels >= 1;


-- ------------------------------------------------------------
-- 6. Weighted benchmark impact
-- Goal:
-- Estimate the Cart Gap if Organic Search reached the matched
-- average conversion of other channels for the same products.
--
-- Important:
-- This is a benchmark gap, NOT a causal estimate of lost users.
-- ------------------------------------------------------------

WITH product_channel AS (
    SELECT
        item.item_name,

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

        COUNT(DISTINCT IF(
            event_name = 'view_item',
            user_pseudo_id,
            NULL
        )) AS view_users,

        COUNT(DISTINCT IF(
            event_name = 'add_to_cart',
            user_pseudo_id,
            NULL
        )) AS cart_users

    FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
        UNNEST(items) AS item

    WHERE
        event_name IN (
            'view_item',
            'add_to_cart'
        )
        AND item.item_name IS NOT NULL
        AND item.item_name != '(not set)'

    GROUP BY
        item.item_name,
        marketing_channel
),

qualified AS (
    SELECT
        item_name,
        marketing_channel,
        view_users,
        cart_users,

        SAFE_DIVIDE(
            cart_users,
            view_users
        ) AS view_to_cart_rate

    FROM
        product_channel

    WHERE
        view_users >= 300
),

product_compare AS (
    SELECT
        item_name,

        MAX(IF(
            marketing_channel = 'Organic Search',
            view_users,
            NULL
        )) AS organic_views,

        MAX(IF(
            marketing_channel = 'Organic Search',
            cart_users,
            NULL
        )) AS organic_carts,

        MAX(IF(
            marketing_channel = 'Organic Search',
            view_to_cart_rate,
            NULL
        )) AS organic_rate,

        AVG(IF(
            marketing_channel != 'Organic Search',
            view_to_cart_rate,
            NULL
        )) AS other_channel_avg_rate,

        COUNTIF(
            marketing_channel != 'Organic Search'
        ) AS other_channels

    FROM
        qualified

    GROUP BY
        item_name
)

SELECT
    COUNT(*) AS compared_products,

    SUM(organic_views)
        AS organic_views,

    SUM(organic_carts)
        AS actual_organic_carts,

    ROUND(
        SAFE_DIVIDE(
            SUM(organic_carts),
            SUM(organic_views)
        ) * 100,
        2
    ) AS weighted_organic_rate,

    ROUND(
        SAFE_DIVIDE(
            SUM(
                organic_views
                * other_channel_avg_rate
            ),
            SUM(organic_views)
        ) * 100,
        2
    ) AS weighted_benchmark_rate,

    ROUND(
        SUM(
            organic_views
            * other_channel_avg_rate
        ),
        0
    ) AS benchmark_carts,

    ROUND(
        SUM(
            organic_views
            * other_channel_avg_rate
        )
        - SUM(organic_carts),
        0
    ) AS cart_gap,

    ROUND(
        SAFE_DIVIDE(
            SUM(
                organic_views
                * other_channel_avg_rate
            )
            - SUM(organic_carts),
            SUM(organic_carts)
        ) * 100,
        2
    ) AS cart_gap_pct

FROM
    product_compare

WHERE
    organic_rate IS NOT NULL
    AND other_channels >= 1;


-- ------------------------------------------------------------
-- 7. Create Power BI table for product-level Organic Cart Gap
--
-- Do NOT round product-level benchmark_carts or cart_gap here.
-- Keeping full precision prevents aggregation rounding errors.
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE
`ga4-ecommerce-project-510513.ga4_analysis.organic_product_gap`
AS

WITH product_channel AS (
    SELECT
        item.item_name,

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

        COUNT(DISTINCT IF(
            event_name = 'view_item',
            user_pseudo_id,
            NULL
        )) AS view_users,

        COUNT(DISTINCT IF(
            event_name = 'add_to_cart',
            user_pseudo_id,
            NULL
        )) AS cart_users

    FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
        UNNEST(items) AS item

    WHERE
        event_name IN (
            'view_item',
            'add_to_cart'
        )
        AND item.item_name IS NOT NULL
        AND item.item_name != '(not set)'

    GROUP BY
        item.item_name,
        marketing_channel
),

qualified AS (
    SELECT
        item_name,
        marketing_channel,
        view_users,
        cart_users,

        SAFE_DIVIDE(
            cart_users,
            view_users
        ) AS view_to_cart_rate

    FROM
        product_channel

    WHERE
        view_users >= 300
),

product_compare AS (
    SELECT
        item_name,

        MAX(IF(
            marketing_channel = 'Organic Search',
            view_users,
            NULL
        )) AS organic_views,

        MAX(IF(
            marketing_channel = 'Organic Search',
            cart_users,
            NULL
        )) AS organic_carts,

        MAX(IF(
            marketing_channel = 'Organic Search',
            view_to_cart_rate,
            NULL
        )) AS organic_rate,

        AVG(IF(
            marketing_channel != 'Organic Search',
            view_to_cart_rate,
            NULL
        )) AS other_channel_avg_rate,

        COUNTIF(
            marketing_channel != 'Organic Search'
        ) AS other_channels

    FROM
        qualified

    GROUP BY
        item_name
)

SELECT
    item_name,
    organic_views,
    organic_carts,

    organic_rate,

    other_channel_avg_rate,

    other_channel_avg_rate
        - organic_rate AS gap_rate,

    organic_views
        * other_channel_avg_rate
            AS benchmark_carts,

    organic_views
        * other_channel_avg_rate
        - organic_carts
            AS cart_gap

FROM
    product_compare

WHERE
    organic_rate IS NOT NULL
    AND other_channels >= 1

ORDER BY
    cart_gap DESC;
