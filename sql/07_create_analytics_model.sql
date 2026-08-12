CREATE SCHEMA IF NOT EXISTS analytics;

DROP TABLE IF EXISTS analytics.fact_listening CASCADE;
DROP TABLE IF EXISTS analytics.fact_subscription CASCADE;
DROP TABLE IF EXISTS analytics.fact_churn CASCADE;
DROP TABLE IF EXISTS analytics.dim_user CASCADE;
DROP TABLE IF EXISTS analytics.dim_date CASCADE;


-- ============================================================
-- DATE DIMENSION
-- ============================================================

CREATE TABLE analytics.dim_date (
    date_key INTEGER PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    month_name TEXT NOT NULL,
    quarter INTEGER NOT NULL
);


-- ============================================================
-- USER DIMENSION
--
-- Union of users appearing in the analytical sources.
-- Member attributes are optional because members_v3 does not
-- contain every user found in the other sources.
-- ============================================================

CREATE TABLE analytics.dim_user (
    user_key BIGSERIAL PRIMARY KEY,
    msno TEXT NOT NULL UNIQUE,
    city INTEGER,
    bd INTEGER,
    gender TEXT,
    registered_via INTEGER,
    registration_date DATE
);


-- ============================================================
-- CHURN FACT
-- Grain: one row per labelled user
-- ============================================================

CREATE TABLE analytics.fact_churn (
    user_key BIGINT PRIMARY KEY,
    is_churn BOOLEAN NOT NULL,
    CONSTRAINT fk_churn_user
        FOREIGN KEY (user_key)
        REFERENCES analytics.dim_user(user_key)
);


-- ============================================================
-- SUBSCRIPTION FACT
-- Grain: one row per transaction
-- ============================================================

CREATE TABLE analytics.fact_subscription (
    transaction_key BIGSERIAL PRIMARY KEY,
    user_key BIGINT NOT NULL,
    transaction_date_key INTEGER NOT NULL,
    membership_expire_date_key INTEGER NOT NULL,
    payment_method_id INTEGER,
    payment_plan_days INTEGER,
    plan_list_price INTEGER,
    actual_amount_paid INTEGER,
    is_auto_renew BOOLEAN,
    is_cancel BOOLEAN,

    CONSTRAINT fk_subscription_user
        FOREIGN KEY (user_key)
        REFERENCES analytics.dim_user(user_key),

    CONSTRAINT fk_subscription_transaction_date
        FOREIGN KEY (transaction_date_key)
        REFERENCES analytics.dim_date(date_key),

    CONSTRAINT fk_subscription_expire_date
        FOREIGN KEY (membership_expire_date_key)
        REFERENCES analytics.dim_date(date_key)
);


-- ============================================================
-- LISTENING FACT
-- Grain: one row per user per day
-- ============================================================

CREATE TABLE analytics.fact_listening (
    user_key BIGINT NOT NULL,
    date_key INTEGER NOT NULL,
    num_25 INTEGER,
    num_50 INTEGER,
    num_75 INTEGER,
    num_985 INTEGER,
    num_100 INTEGER,
    num_unq INTEGER,
    total_secs DOUBLE PRECISION,

    PRIMARY KEY (user_key, date_key),

    CONSTRAINT fk_listening_user
        FOREIGN KEY (user_key)
        REFERENCES analytics.dim_user(user_key),

    CONSTRAINT fk_listening_date
        FOREIGN KEY (date_key)
        REFERENCES analytics.dim_date(date_key)
);
