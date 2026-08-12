-- ============================================================
-- SOUND & RETENTION — RELATIONAL VALIDATION
--
-- Python/Pandas handles source-level data-quality validation:
--   - required keys
--   - invalid dates
--   - invalid flags
--   - impossible numeric values
--   - source-level duplicates
--
-- PostgreSQL handles checks that require the complete
-- relational dataset.
-- ============================================================


-- ============================================================
-- 1. ANALYTICAL GRAIN
--
-- user_logs should contain at most one row per user per day.
-- This check is performed in PostgreSQL because the Python ETL
-- processes user_logs in chunks and therefore cannot reliably
-- detect duplicates occurring across chunk boundaries.
-- ============================================================

SELECT
    'user_logs: duplicate msno + date' AS check_name,
    COUNT(*) AS failed_rows,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM (
    SELECT
        msno,
        date
    FROM staging.user_logs
    GROUP BY
        msno,
        date
    HAVING COUNT(*) > 1
) duplicates;


-- ============================================================
-- 2. CROSS-TABLE RELATIONSHIPS
--
-- members is treated as the customer/master population.
--
-- These are warnings rather than hard failures because the
-- source data does contain users appearing in other tables
-- without a corresponding members record.
-- ============================================================

SELECT
    'transactions: msno missing from members' AS check_name,
    COUNT(*) AS affected_users,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'WARN'
    END AS status
FROM (
    SELECT DISTINCT
        t.msno
    FROM staging.transactions t
    LEFT JOIN staging.members m
        ON t.msno = m.msno
    WHERE m.msno IS NULL
) missing;


SELECT
    'user_logs: msno missing from members' AS check_name,
    COUNT(*) AS affected_users,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'WARN'
    END AS status
FROM (
    SELECT DISTINCT
        l.msno
    FROM staging.user_logs l
    LEFT JOIN staging.members m
        ON l.msno = m.msno
    WHERE m.msno IS NULL
) missing;


SELECT
    'churn: msno missing from members' AS check_name,
    COUNT(*) AS affected_users,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'WARN'
    END AS status
FROM (
    SELECT DISTINCT
        c.msno
    FROM staging.churn c
    LEFT JOIN staging.members m
        ON c.msno = m.msno
    WHERE m.msno IS NULL
) missing;