# Analytical Model

## Grain Definitions

The analytical model uses explicit row-level grains to prevent
double-counting during joins and aggregations.

### User Grain

> One row represents one user (`msno`).

The user grain is the primary analytical population for customer-level
churn and segmentation analysis.

### Transaction Grain

> One row represents one subscription/payment transaction for one user.

A user can have multiple transaction records. Therefore, `msno` is not
unique in the transaction table.

Transaction-level analysis can be aggregated to the user level using
metrics such as transaction count, payment amount, renewal behaviour,
and subscription duration.

### Listening / Activity Grain

> One row represents one user's listening activity for one calendar day.

The natural key is:

`msno + date`

A user can therefore have many listening records across different dates,
but should have at most one record for a given user and date.

### Churn Grain

> One row represents one user and their churn outcome.

The churn table contains one record per labelled user:

`msno → is_churn`

The churn outcome is the target variable for the analytical model.

## Source-to-Analytical Relationship

The source tables have different grains and should not be joined
without considering those grains:

```text
User / Churn
one row per user
       │
       ├───────────────┐
       │               │
       ▼               ▼
Transactions       Listening
many per user      many per user
       │               │
       └───────┬───────┘
               ▼
      User-level features
````

Transaction and listening records must be aggregated to the user grain
before being joined into a user-level analytical dataset. This prevents
one-to-many joins from multiplying rows and causing incorrect aggregates.

## Analytical Model

The analytical layer consists of a small dimensional model:

```text
                         dim_date
                            │
                    ┌───────┴────────┐
                    │                │
                    ▼                ▼
             fact_listening    fact_subscription
                    │                │
                    └───────┬────────┘
                            │
                            ▼
                         dim_user
                            │
                            ▼
                       fact_churn
```

### `dim_user`

**Grain:** one row per user.

**Primary key:** `user_key`

The dimension contains the user attributes available from the member
source, where available.

The `members` source does not contain every user found in the other
source tables, so `dim_user` is not treated as a direct copy of
`members`.

### `dim_date`

**Grain:** one row per calendar date.

**Primary key:** `date_key`

Used to provide consistent date attributes for time-based analysis.

### `fact_listening`

**Grain:** one row per user per calendar day.

**Primary key:** `(user_key, date_key)`

**Foreign keys:**

* `user_key` → `dim_user.user_key`
* `date_key` → `dim_date.date_key`

### `fact_subscription`

**Grain:** one row per subscription/payment transaction.

**Primary key:** `transaction_key`

**Foreign keys:**

* `user_key` → `dim_user.user_key`
* `transaction_date_key` → `dim_date.date_key`
* `membership_expire_date_key` → `dim_date.date_key`

### `fact_churn`

**Grain:** one row per labelled user.

**Primary key:** `user_key`

**Foreign key:**

* `user_key` → `dim_user.user_key`

The churn outcome is represented by `is_churn`.

## Analytical Join Strategy

Transaction and listening facts remain at their natural grains.

For customer-level churn analysis, they will first be aggregated to the
user grain and then combined with `dim_user` and `fact_churn`.

This prevents one-to-many joins between transactions and listening
records from multiplying rows and producing incorrect aggregates.

## Population Note

The `members` table does not contain every user found in the other
source tables. Relationship validation identified missing member
records for approximately 11.33% of churn-labelled users and 9.99% of
transaction users, while only 40 listening users were absent.

Therefore, the final analytical population and join strategy must be
defined explicitly rather than assuming that `members` is a complete
master user table.

```text
                         ┌──────────────┐
                         │   dim_date   │
                         │──────────────│
                         │ date_key PK  │
                         │ date         │
                         │ year/month   │
                         │ quarter      │
                         └──────┬───────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
                    │ date_key              │ date_key
                    ▼                       ▼
          ┌──────────────────┐    ┌────────────────────┐
          │ fact_listening   │    │ fact_subscription  │
          │──────────────────│    │────────────────────│
          │ user_key FK      │    │ transaction_key PK │
          │ date_key FK      │    │ user_key FK        │
          │ listening stats  │    │ transaction date   │
          └────────┬─────────┘    │ payment/subscript. │
                   │              └─────────┬──────────┘
                   │                        │
                   └──────────┬─────────────┘
                              │
                              ▼
                     ┌────────────────┐
                     │    dim_user    │
                     │────────────────│
                     │ user_key PK    │
                     │ msno UNIQUE    │
                     │ member attrs   │
                     └───────┬────────┘
                             │
                             ▼
                     ┌────────────────┐
                     │   fact_churn   │
                     │────────────────│
                     │ user_key PK/FK │
                     │ is_churn       │
                     └────────────────┘
```
