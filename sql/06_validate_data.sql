-- ============================================================
-- SOUND & RETENTION — STAGING DATA VALIDATION
-- ============================================================

DROP TABLE IF EXISTS validation_results;

CREATE TEMP TABLE validation_results (
    check_name TEXT,
    failed_rows BIGINT,
    status TEXT
);


-- ============================================================
-- 1. REQUIRED KEYS
-- ============================================================

INSERT INTO validation_results
SELECT
    'churn: null msno',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM staging.churn
WHERE msno IS NULL OR TRIM(msno) = '';


INSERT INTO validation_results
SELECT
    'members: null msno',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM staging.members
WHERE msno IS NULL OR TRIM(msno) = '';


INSERT INTO validation_results
SELECT
    'transactions: null msno',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM staging.transactions
WHERE msno IS NULL OR TRIM(msno) = '';


INSERT INTO validation_results
SELECT
    'user_logs: null msno',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM staging.user_logs
WHERE msno IS NULL OR TRIM(msno) = '';


-- ============================================================
-- 2. DUPLICATES WHERE UNIQUENESS IS EXPECTED
-- ============================================================

INSERT INTO validation_results
SELECT
    'churn: duplicate msno',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT msno
    FROM staging.churn
    GROUP BY msno
    HAVING COUNT(*) > 1
) d;


INSERT INTO validation_results
SELECT
    'members: duplicate msno',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT msno
    FROM staging.members
    GROUP BY msno
    HAVING COUNT(*) > 1
) d;


-- user_logs expected grain = one row per msno + date
INSERT INTO validation_results
SELECT
    'user_logs: duplicate msno + date',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT msno, date
    FROM staging.user_logs
    GROUP BY msno, date
    HAVING COUNT(*) > 1
) d;


-- ============================================================
-- 3. INVALID CHURN VALUES
-- ============================================================

INSERT INTO validation_results
SELECT
    'churn: invalid is_churn',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM staging.churn
WHERE is_churn IS NULL;


-- ============================================================
-- 4. INVALID DATES
--
-- We validate the RAW values as well because PostgreSQL's
-- TO_DATE can normalize some invalid calendar dates rather
-- than rejecting them.
-- ============================================================

INSERT INTO validation_results
SELECT
    'transactions: invalid transaction_date',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.transactions
WHERE
    transaction_date IS NULL
    OR transaction_date::TEXT !~ '^[0-9]{8}$'
    OR TO_CHAR(
        TO_DATE(transaction_date::TEXT, 'YYYYMMDD'),
        'YYYYMMDD'
    ) <> transaction_date::TEXT;


INSERT INTO validation_results
SELECT
    'transactions: invalid membership_expire_date',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.transactions
WHERE
    membership_expire_date IS NULL
    OR membership_expire_date::TEXT !~ '^[0-9]{8}$'
    OR TO_CHAR(
        TO_DATE(membership_expire_date::TEXT, 'YYYYMMDD'),
        'YYYYMMDD'
    ) <> membership_expire_date::TEXT;


INSERT INTO validation_results
SELECT
    'members: invalid registration_init_time',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.members
WHERE
    registration_init_time IS NULL
    OR registration_init_time::TEXT !~ '^[0-9]{8}$'
    OR TO_CHAR(
        TO_DATE(registration_init_time::TEXT, 'YYYYMMDD'),
        'YYYYMMDD'
    ) <> registration_init_time::TEXT;


INSERT INTO validation_results
SELECT
    'user_logs: invalid date',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.user_logs
WHERE
    date IS NULL
    OR date::TEXT !~ '^[0-9]{8}$'
    OR TO_CHAR(
        TO_DATE(date::TEXT, 'YYYYMMDD'),
        'YYYYMMDD'
    ) <> date::TEXT;


-- ============================================================
-- 5. IMPOSSIBLE NUMERIC VALUES
-- ============================================================

INSERT INTO validation_results
SELECT
    'transactions: negative payment_plan_days',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM staging.transactions
WHERE payment_plan_days < 0;


INSERT INTO validation_results
SELECT
    'transactions: negative plan_list_price',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM staging.transactions
WHERE plan_list_price < 0;


INSERT INTO validation_results
SELECT
    'transactions: negative actual_amount_paid',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM staging.transactions
WHERE actual_amount_paid < 0;


INSERT INTO validation_results
SELECT
    'user_logs: negative listening metrics',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM staging.user_logs
WHERE
    num_25 < 0
    OR num_50 < 0
    OR num_75 < 0
    OR num_985 < 0
    OR num_100 < 0
    OR num_unq < 0
    OR total_secs < 0;


-- ============================================================
-- 6. BOOLEAN / FLAG VALUES
-- ============================================================

INSERT INTO validation_results
SELECT
    'transactions: invalid auto-renew values',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.transactions
WHERE is_auto_renew NOT IN (0, 1);


INSERT INTO validation_results
SELECT
    'transactions: invalid cancel values',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.transactions
WHERE is_cancel NOT IN (0, 1);


-- ============================================================
-- 7. BROKEN RELATIONSHIPS
--
-- members is the customer/master table.
-- Transactions and logs may legitimately contain users that
-- are not in the labelled churn population, so we validate
-- against members rather than churn.
-- ============================================================

INSERT INTO validation_results
SELECT
    'transactions: msno missing from members',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'WARN' END
FROM (
    SELECT DISTINCT t.msno
    FROM staging.transactions t
    LEFT JOIN staging.members m
        ON t.msno = m.msno
    WHERE m.msno IS NULL
) missing;


INSERT INTO validation_results
SELECT
    'user_logs: msno missing from members',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'WARN' END
FROM (
    SELECT DISTINCT l.msno
    FROM staging.user_logs l
    LEFT JOIN staging.members m
        ON l.msno = m.msno
    WHERE m.msno IS NULL
) missing;


INSERT INTO validation_results
SELECT
    'churn: msno missing from members',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'WARN' END
FROM (
    SELECT DISTINCT c.msno
    FROM staging.churn c
    LEFT JOIN staging.members m
        ON c.msno = m.msno
    WHERE m.msno IS NULL
) missing;


-- ============================================================
-- FINAL RESULT
-- ============================================================

SELECT
    check_name,
    failed_rows,
    status
FROM validation_results
ORDER BY
    CASE WHEN status = 'FAIL' THEN 0 ELSE 1 END,
    check_name;


-- Overall result
SELECT
    CASE
        WHEN COUNT(*) FILTER (WHERE status = 'FAIL') > 0
            THEN 'FAIL — one or more critical validation checks failed'
        WHEN COUNT(*) FILTER (WHERE status = 'WARN') > 0
            THEN 'PASS WITH WARNINGS — review relationship checks'
        ELSE 'PASS — all validation checks passed'
    END as overall_status
FROM validation_results;