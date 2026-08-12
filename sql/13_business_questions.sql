-- ============================================================
-- TICKET 5.5 — ANSWER THE FOUR BUSINESS QUESTIONS
--
-- Each section produces a compact result suitable for
-- interpretation and documentation.
-- ============================================================


-- ============================================================
-- Q1 — Are highly engaged users less likely to churn?
--
-- Engagement is measured using number of listening days.
-- ============================================================

\echo ''
\echo '============================================================'
\echo 'Q1 — ENGAGEMENT AND CHURN'
\echo '============================================================'

WITH user_engagement AS (
    SELECT
        c.user_key,
        c.is_churn,
        COUNT(l.date_key) AS listening_days
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
        CASE
            WHEN listening_days = 0 THEN 'No listening'
            WHEN listening_days <= 7 THEN 'Low'
            WHEN listening_days <= 30 THEN 'Medium'
            ELSE 'High'
        END AS engagement_level
    FROM user_engagement
)

SELECT
    engagement_level,
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
GROUP BY engagement_level
ORDER BY
    CASE engagement_level
        WHEN 'No listening' THEN 1
        WHEN 'Low' THEN 2
        WHEN 'Medium' THEN 3
        WHEN 'High' THEN 4
    END;


-- ============================================================
-- Q2 — Does subscription behavior differ between
--      churned and retained users?
-- ============================================================

\echo ''
\echo '============================================================'
\echo 'Q2 — SUBSCRIPTION BEHAVIOR AND CHURN'
\echo '============================================================'

WITH subscription_summary AS (
    SELECT
        c.user_key,
        c.is_churn,

        COUNT(s.user_key) AS transaction_count,

        COALESCE(SUM(s.actual_amount_paid), 0)
            AS total_amount_paid,

        AVG(s.actual_amount_paid)
            AS avg_amount_paid,

        COALESCE(
            SUM(
                CASE
                    WHEN s.is_auto_renew = TRUE THEN 1
                    ELSE 0
                END
            ),
            0
        ) AS auto_renew_transactions,

        COALESCE(
            SUM(
                CASE
                    WHEN s.is_cancel = TRUE THEN 1
                    ELSE 0
                END
            ),
            0
        ) AS cancelled_transactions

    FROM analytics.fact_churn c

    LEFT JOIN analytics.fact_subscription s
        ON c.user_key = s.user_key

    GROUP BY
        c.user_key,
        c.is_churn
)

SELECT
    CASE
        WHEN is_churn = TRUE THEN 'Churned'
        ELSE 'Retained'
    END AS customer_status,

    COUNT(*) AS users,

    ROUND(AVG(transaction_count), 2)
        AS avg_transactions,

    ROUND(AVG(total_amount_paid), 2)
        AS avg_total_amount_paid,

    ROUND(AVG(avg_amount_paid), 2)
        AS avg_transaction_amount,

    ROUND(
        100.0 *
        SUM(auto_renew_transactions)
        / NULLIF(SUM(transaction_count), 0),
        2
    ) AS auto_renew_transaction_pct,

    ROUND(
        100.0 *
        SUM(cancelled_transactions)
        / NULLIF(SUM(transaction_count), 0),
        2
    ) AS cancelled_transaction_pct

FROM subscription_summary
GROUP BY is_churn
ORDER BY is_churn DESC;


-- ============================================================
-- Q3 — Which customer segments have the highest churn?
--
-- We examine registered_via and city separately.
-- A minimum population threshold prevents tiny segments
-- from dominating the ranking.
-- ============================================================

\echo ''
\echo '============================================================'
\echo 'Q3 — CUSTOMER SEGMENTS'
\echo '============================================================'

\echo ''
\echo '--- Q3A: Churn by registration method ---'

SELECT
    COALESCE(u.registered_via::TEXT, 'Unknown') AS registered_via,
    COUNT(*) AS users,
    COUNT(*) FILTER (
        WHERE c.is_churn = TRUE
    ) AS churned_users,
    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE c.is_churn = TRUE
        ) / COUNT(*),
        2
    ) AS churn_rate_pct
FROM analytics.fact_churn c
JOIN analytics.dim_user u
    ON c.user_key = u.user_key
GROUP BY u.registered_via
HAVING COUNT(*) >= 1000
ORDER BY churn_rate_pct DESC;


\echo ''
\echo '--- Q3B: Highest-churn cities ---'

SELECT
    COALESCE(u.city::TEXT, 'Unknown') AS city,
    COUNT(*) AS users,
    COUNT(*) FILTER (
        WHERE c.is_churn = TRUE
    ) AS churned_users,
    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE c.is_churn = TRUE
        ) / COUNT(*),
        2
    ) AS churn_rate_pct
FROM analytics.fact_churn c
JOIN analytics.dim_user u
    ON c.user_key = u.user_key
GROUP BY u.city
HAVING COUNT(*) >= 1000
ORDER BY churn_rate_pct DESC
LIMIT 15;


-- ============================================================
-- Q4 — Is recent listening activity associated with churn?
--
-- We measure recency relative to the final listening date
-- available in the dataset.
--
-- Important:
-- This is an association, not proof that reduced activity
-- causes churn.
-- ============================================================

\echo ''
\echo '============================================================'
\echo 'Q4 — RECENT LISTENING ACTIVITY AND CHURN'
\echo '============================================================'

WITH observation_period AS (
    SELECT MAX(date) AS observation_end_date
    FROM analytics.dim_date d
    JOIN analytics.fact_listening l
        ON d.date_key = l.date_key
),

last_activity AS (
    SELECT
        c.user_key,
        c.is_churn,
        MAX(d.date) AS last_listening_date
    FROM analytics.fact_churn c
    LEFT JOIN analytics.fact_listening l
        ON c.user_key = l.user_key
    LEFT JOIN analytics.dim_date d
        ON l.date_key = d.date_key
    GROUP BY
        c.user_key,
        c.is_churn
),

recency AS (
    SELECT
        user_key,
        is_churn,
        CASE
            WHEN last_listening_date IS NULL
                THEN NULL
            ELSE (
                observation_end_date - last_listening_date
            )
        END AS days_since_last_listening
    FROM last_activity
    CROSS JOIN observation_period
),

recency_bands AS (
    SELECT
        user_key,
        is_churn,
        CASE
            WHEN days_since_last_listening IS NULL
                THEN 'No listening'

            WHEN days_since_last_listening <= 7
                THEN '0-7 days'

            WHEN days_since_last_listening <= 14
                THEN '8-14 days'

            WHEN days_since_last_listening <= 30
                THEN '15-30 days'

            ELSE '31+ days'
        END AS recency_band
    FROM recency
)

SELECT
    recency_band,
    COUNT(*) AS users,
    COUNT(*) FILTER (
        WHERE is_churn = TRUE
    ) AS churned_users,
    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE is_churn = TRUE
        ) / COUNT(*),
        2
    ) AS churn_rate_pct
FROM recency_bands
GROUP BY recency_band
ORDER BY
    CASE recency_band
        WHEN '0-7 days' THEN 1
        WHEN '8-14 days' THEN 2
        WHEN '15-30 days' THEN 3
        WHEN '31+ days' THEN 4
        WHEN 'No listening' THEN 5
    END;