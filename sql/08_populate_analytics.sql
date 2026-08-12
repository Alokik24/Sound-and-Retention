-- ============================================================
-- TICKET 3.4 — POPULATE ANALYTICS LAYER
-- ============================================================

BEGIN;

-- ============================================================
-- 1. DIM_DATE
-- ============================================================

INSERT INTO analytics.dim_date (
    date_key,
    date,
    year,
    month,
    month_name,
    quarter
)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INTEGER AS date_key,
    d::DATE AS date,
    EXTRACT(YEAR FROM d)::INTEGER,
    EXTRACT(MONTH FROM d)::INTEGER,
    TO_CHAR(d, 'Month'),
    EXTRACT(QUARTER FROM d)::INTEGER
FROM generate_series(
    (SELECT MIN(transaction_date) FROM staging.transactions),
    GREATEST(
        (SELECT MAX(transaction_date) FROM staging.transactions),
        (SELECT MAX(membership_expire_date) FROM staging.transactions),
        (SELECT MAX(date) FROM staging.user_logs)
    ),
    INTERVAL '1 day'
) AS d
ON CONFLICT (date_key) DO NOTHING;


-- ============================================================
-- 2. DIM_USER
--
-- Build the user population from all relevant sources.
-- Member attributes are attached where a member record exists.
-- ============================================================

INSERT INTO analytics.dim_user (
    msno,
    city,
    bd,
    gender,
    registered_via,
    registration_date
)
SELECT
    u.msno,
    m.city,
    m.bd,
    m.gender,
    m.registered_via,
    m.registration_date
FROM (
    SELECT msno FROM staging.churn
    UNION
    SELECT msno FROM staging.members
    UNION
    SELECT DISTINCT msno FROM staging.transactions
    UNION
    SELECT DISTINCT msno FROM staging.user_logs
) u
LEFT JOIN staging.members m
    ON u.msno = m.msno
ON CONFLICT (msno) DO NOTHING;


-- ============================================================
-- 3. FACT_CHURN
-- ============================================================

INSERT INTO analytics.fact_churn (
    user_key,
    is_churn
)
SELECT
    u.user_key,
    c.is_churn
FROM staging.churn c
JOIN analytics.dim_user u
    ON c.msno = u.msno
ON CONFLICT (user_key) DO NOTHING;


-- ============================================================
-- 4. FACT_SUBSCRIPTION
-- ============================================================

INSERT INTO analytics.fact_subscription (
    user_key,
    transaction_date_key,
    membership_expire_date_key,
    payment_method_id,
    payment_plan_days,
    plan_list_price,
    actual_amount_paid,
    is_auto_renew,
    is_cancel
)
SELECT
    u.user_key,
    TO_CHAR(t.transaction_date, 'YYYYMMDD')::INTEGER,
    TO_CHAR(t.membership_expire_date, 'YYYYMMDD')::INTEGER,
    t.payment_method_id,
    t.payment_plan_days,
    t.plan_list_price,
    t.actual_amount_paid,
    t.is_auto_renew,
    t.is_cancel
FROM staging.transactions t
JOIN analytics.dim_user u
    ON t.msno = u.msno;


-- ============================================================
-- 5. FACT_LISTENING
-- ============================================================

INSERT INTO analytics.fact_listening (
    user_key,
    date_key,
    num_25,
    num_50,
    num_75,
    num_985,
    num_100,
    num_unq,
    total_secs
)
SELECT
    u.user_key,
    TO_CHAR(l.date, 'YYYYMMDD')::INTEGER,
    l.num_25,
    l.num_50,
    l.num_75,
    l.num_985,
    l.num_100,
    l.num_unq,
    l.total_secs
FROM staging.user_logs l
JOIN analytics.dim_user u
    ON l.msno = u.msno;


COMMIT;