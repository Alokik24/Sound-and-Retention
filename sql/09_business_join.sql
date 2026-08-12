-- ============================================================
-- TICKET 5.1 — BUSINESS JOIN
--
-- Grain of final result:
-- one row per labelled user
--
-- Listening and subscription facts are aggregated to user grain
-- before being joined to prevent one-to-many row multiplication.
-- ============================================================

WITH listening_summary AS (
    SELECT
        user_key,
        COUNT(*) AS listening_days,
        SUM(total_secs) AS total_listening_secs,
        SUM(num_unq) AS total_unique_songs,
        MAX(date_key) AS last_listening_date_key
    FROM analytics.fact_listening
    GROUP BY user_key
),

subscription_summary AS (
    SELECT
        user_key,
        COUNT(*) AS transaction_count,
        SUM(actual_amount_paid) AS total_amount_paid,
        AVG(actual_amount_paid) AS avg_amount_paid,
        SUM(payment_plan_days) AS total_plan_days,
        COUNT(*) FILTER (
            WHERE is_auto_renew = TRUE
        ) AS auto_renew_transactions,
        COUNT(*) FILTER (
            WHERE is_cancel = TRUE
        ) AS cancelled_transactions
    FROM analytics.fact_subscription
    GROUP BY user_key
)

SELECT
    u.user_key,
    u.msno,
    u.city,
    u.gender,
    u.registered_via,
    u.registration_date,

    c.is_churn,

    -- Listening behaviour
    COALESCE(l.listening_days, 0) AS listening_days,
    COALESCE(l.total_listening_secs, 0) AS total_listening_secs,
    COALESCE(l.total_unique_songs, 0) AS total_unique_songs,

    -- Subscription behaviour
    COALESCE(s.transaction_count, 0) AS transaction_count,
    COALESCE(s.total_amount_paid, 0) AS total_amount_paid,
    s.avg_amount_paid,
    COALESCE(s.total_plan_days, 0) AS total_plan_days,
    COALESCE(s.auto_renew_transactions, 0) AS auto_renew_transactions,
    COALESCE(s.cancelled_transactions, 0) AS cancelled_transactions

FROM analytics.fact_churn c

JOIN analytics.dim_user u
    ON c.user_key = u.user_key

LEFT JOIN listening_summary l
    ON u.user_key = l.user_key

LEFT JOIN subscription_summary s
    ON u.user_key = s.user_key;