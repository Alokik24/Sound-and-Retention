DROP TABLE IF EXISTS staging.members;
DROP TABLE IF EXISTS staging.transactions;
DROP TABLE IF EXISTS staging.user_logs;

CREATE TABLE staging.members AS
SELECT
    TRIM(msno) AS msno,
    city,
    bd,
    NULLIF(TRIM(gender), '') AS gender,
    registered_via,
    TO_DATE(registration_init_time::TEXT, 'YYYYMMDD') AS registration_date
FROM raw.members;

CREATE TABLE staging.transactions AS
SELECT
    TRIM(msno) AS msno,
    payment_method_id,
    payment_plan_days,
    plan_list_price,
    actual_amount_paid,
    CASE
        WHEN is_auto_renew = 1 THEN TRUE
        WHEN is_auto_renew = 0 THEN FALSE
        ELSE NULL
    END AS is_auto_renew,
    TO_DATE(transaction_date::TEXT, 'YYYYMMDD') AS transaction_date,
    TO_DATE(membership_expire_date::TEXT, 'YYYYMMDD') AS membership_expire_date,
    CASE
        WHEN is_cancel = 1 THEN TRUE
        WHEN is_cancel = 0 THEN FALSE
        ELSE NULL
    END AS is_cancel
FROM raw.transactions;

CREATE TABLE staging.user_logs AS
SELECT
    TRIM(msno) AS msno,
    TO_DATE(date::TEXT, 'YYYYMMDD') AS date,
    num_25,
    num_50,
    num_75,
    num_985,
    num_100,
    num_unq,
    total_secs
FROM raw.user_logs;
