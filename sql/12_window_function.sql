-- ============================================================
-- TICKET 5.4 — WINDOW FUNCTION
--
-- Compare each transaction with the user's previous transaction.
--
-- LAG() allows us to access the previous transaction while
-- preserving the transaction-level grain.
-- ============================================================

WITH transaction_history AS (
    SELECT
        t.user_key,
        t.transaction_date_key,
        d.date AS transaction_date,

        t.actual_amount_paid,

        LAG(d.date) OVER (
            PARTITION BY t.user_key
            ORDER BY d.date
        ) AS previous_transaction_date,

        LAG(t.actual_amount_paid) OVER (
            PARTITION BY t.user_key
            ORDER BY d.date
        ) AS previous_amount_paid

    FROM analytics.fact_subscription t

    JOIN analytics.dim_date d
        ON t.transaction_date_key = d.date_key
)

SELECT
    user_key,
    transaction_date,
    actual_amount_paid,

    previous_transaction_date,
    previous_amount_paid,

    transaction_date - previous_transaction_date
        AS days_since_previous_transaction,

    actual_amount_paid - previous_amount_paid
        AS amount_change

FROM transaction_history

WHERE previous_transaction_date IS NOT NULL

ORDER BY
    user_key,
    transaction_date

LIMIT 100;