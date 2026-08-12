DROP TABLE IF EXISTS staging.members;
DROP TABLE IF EXISTS staging.transactions;
DROP TABLE IF EXISTS staging.user_logs;
DROP TABLE IF EXISTS staging.churn;

CREATE TABLE staging.members (
    msno TEXT NOT NULL,
    city INTEGER,
    bd INTEGER,
    gender TEXT,
    registered_via INTEGER,
    registration_date DATE
);

CREATE TABLE staging.transactions (
    msno TEXT NOT NULL,
    payment_method_id INTEGER,
    payment_plan_days INTEGER,
    plan_list_price INTEGER,
    actual_amount_paid INTEGER,
    is_auto_renew BOOLEAN,
    transaction_date DATE,
    membership_expire_date DATE,
    is_cancel BOOLEAN
);

CREATE TABLE staging.user_logs (
    msno TEXT NOT NULL,
    date DATE NOT NULL,
    num_25 INTEGER,
    num_50 INTEGER,
    num_75 INTEGER,
    num_985 INTEGER,
    num_100 INTEGER,
    num_unq INTEGER,
    total_secs DOUBLE PRECISION
);

CREATE TABLE staging.churn (
    msno TEXT NOT NULL,
    is_churn BOOLEAN
);