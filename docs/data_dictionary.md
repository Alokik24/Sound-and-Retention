# Data Dictionary

This document defines the source fields used in the Sound & Retention analysis.

The project uses four KKBox source tables:

- `train_v2.csv` — churn labels
- `members_v3.csv` — member/customer attributes
- `transactions_v2.csv` — subscription and payment behavior
- `user_logs_v2.csv` — listening activity

Raw source files are preserved unchanged in `data/raw/`.

---

## `train_v2`

| Column | Meaning | Type | Role |
|---|---|---|---|
| `msno` | Anonymized unique user identifier | String | Join key |
| `is_churn` | Whether the user churned (`1`) or did not churn (`0`) | Binary integer | Target |

---

## `members_v3`

| Column | Meaning | Type | Role |
|---|---|---|---|
| `msno` | Anonymized unique user identifier | String | Join key |
| `city` | Encoded city/location category | Integer / categorical | Customer attribute |
| `bd` | Birth-date/age-related field provided by the dataset | Integer | To be evaluated |
| `gender` | Gender category | Categorical | To be evaluated |
| `registered_via` | Encoded registration method/channel | Integer / categorical | Customer attribute |
| `registration_init_time` | Date on which the membership registration was initiated | Integer → Date | Used for derived tenure features |

> `bd` and `gender` are not automatically included in the final analysis. Their data quality and usefulness will be evaluated during data exploration.

---

## `transactions_v2`

| Column | Meaning | Type | Role |
|---|---|---|---|
| `msno` | Anonymized unique user identifier | String | Join key |
| `payment_method_id` | Encoded payment/billing method | Integer / categorical | Subscription attribute |
| `payment_plan_days` | Length of the purchased membership plan in days | Integer | Subscription behavior |
| `plan_list_price` | Listed price of the membership plan | Numeric | Subscription behavior |
| `actual_amount_paid` | Actual amount paid for the transaction | Numeric | Subscription behavior |
| `is_auto_renew` | Whether automatic renewal is enabled (`1`/`0`) | Binary integer | Subscription behavior |
| `transaction_date` | Date of the transaction | Integer → Date | Used for derived features |
| `membership_expire_date` | Membership expiration date | Integer → Date | Used for derived features |
| `is_cancel` | Whether the transaction records a cancellation (`1`/`0`) | Binary integer | Subscription behavior |

---

## `user_logs_v2`

| Column | Meaning | Type | Role |
|---|---|---|---|
| `msno` | Anonymized unique user identifier | String | Join key |
| `date` | Date of listening activity | Integer → Date | Activity timeline |
| `num_25` | Number of songs played for up to 25% of their duration | Integer | Listening behavior |
| `num_50` | Number of songs played for 25–50% of their duration | Integer | Listening behavior |
| `num_75` | Number of songs played for 50–75% of their duration | Integer | Listening behavior |
| `num_985` | Number of songs played for 75–98.5% of their duration | Integer | Listening behavior |
| `num_100` | Number of songs played for 98.5–100% of their duration | Integer | Listening behavior |
| `num_unq` | Number of unique songs played | Integer | Listening behavior |
| `total_secs` | Total listening time in seconds | Numeric | Listening behavior |

---

## Join Key

All four source tables use:

`msno`

This anonymized identifier allows customer-level information, subscription activity, listening activity, and churn labels to be related.

---

## Derived Analytical Features

The raw fields above are transformed and/or aggregated into user-level
features used in the SQL analysis.

Examples include:

- `listening_days`
- `total_unique_songs`
- `total_listening_secs`
- `transaction_count`
- `total_amount_paid`
- `avg_amount_paid`
- `total_plan_days`
- `auto_renew_transactions`
- `cancelled_transactions`

These are not source columns. They are derived during the analytical
transformation and SQL analysis stages.

---

## Data Quality Notes

Initial inspection shows potential quality issues that will be investigated during data exploration:

- `gender` contains substantial missing values.
- `bd` contains unusual and potentially invalid values.
- Some member records do not necessarily correspond to users in the churn-labelled population.
- The listening log contains substantially more records than the number of unique labelled users.

These observations are not yet treated as cleaning decisions. They will be investigated in Ticket 1.3.