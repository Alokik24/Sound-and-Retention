DROP TABLE IF EXISTS staging.churn;

CREATE TABLE staging.churn AS
SELECT
    TRIM(msno) AS msno,
    CASE
        WHEN is_churn = 1 THEN TRUE
        WHEN is_churn = 0 THEN FALSE
        ELSE NULL
    END AS is_churn
FROM raw.churn;