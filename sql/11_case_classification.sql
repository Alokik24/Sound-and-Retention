-- ============================================================
-- TICKET 5.3 — CASE CLASSIFICATION
--
-- Classify users into business-friendly engagement levels.
--
-- Grain:
-- one row per labelled user
-- ============================================================
WITH user_activity AS (
    SELECT
        c.user_key,
        COUNT(l.date_key) AS listening_days
    FROM analytics.fact_churn c
    LEFT JOIN analytics.fact_listening l
        ON c.user_key = l.user_key
    GROUP BY c.user_key
)

SELECT
    CASE
        WHEN listening_days = 0 THEN 'No listening'
        WHEN listening_days <= 7 THEN 'Low'
        WHEN listening_days <= 30 THEN 'Medium'
        ELSE 'High'
    END AS engagement_level,
    COUNT(*) AS users
FROM user_activity
GROUP BY engagement_level
ORDER BY users DESC;