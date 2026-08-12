-- ============================================================
-- TICKET 5.2 — CTE-BASED ANALYSIS
--
-- Purpose:
-- Build user-level engagement measures in stages and classify
-- labelled users into engagement groups.
--
-- Final grain:
-- one row per labelled user
-- ============================================================

WITH user_engagement AS (
    SELECT
        c.user_key,
        c.is_churn,

        COUNT(l.date_key) AS listening_days,
        COALESCE(SUM(l.total_secs), 0) AS total_listening_secs,
        COALESCE(SUM(l.num_unq), 0) AS total_unique_songs

    FROM analytics.fact_churn c

    LEFT JOIN analytics.fact_listening l
        ON c.user_key = l.user_key

    GROUP BY
        c.user_key,
        c.is_churn
),

engagement_bands AS (
    SELECT
        user_key,
        is_churn,
        listening_days,
        total_listening_secs,
        total_unique_songs,

        CASE
            WHEN listening_days = 0 THEN 'No listening'
            WHEN listening_days <= 7 THEN 'Low'
            WHEN listening_days <= 30 THEN 'Medium'
            ELSE 'High'
        END AS engagement_band

    FROM user_engagement
)

SELECT
    engagement_band,
    COUNT(*) AS users,
    COUNT(*) FILTER (
        WHERE is_churn = TRUE
    ) AS churned_users,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE is_churn = TRUE
        ) / COUNT(*),
        2
    ) AS churn_rate_pct
FROM engagement_bands
GROUP BY engagement_band
ORDER BY
    CASE engagement_band
        WHEN 'No listening' THEN 1
        WHEN 'Low' THEN 2
        WHEN 'Medium' THEN 3
        WHEN 'High' THEN 4
    END;