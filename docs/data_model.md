# Data Model

## Overview

The analytical layer uses a small dimensional model designed for
customer churn analysis.

The model separates descriptive user and date information into
dimensions and measurable business events into fact tables.

## ERD

```text
                    dim_user
                       │
          ┌────────────┼────────────┐
          │            │            │
          ▼            ▼            ▼
 fact_listening  fact_subscription  fact_churn
       │                 │
       │                 │
       └────────┬────────┘
                │
                ▼
             dim_date
````

The relationships are:

```text
dim_user 1 ────< fact_listening >──── 1 dim_date

dim_user 1 ────< fact_subscription >─ 1 dim_date

dim_user 1 ──── 1 fact_churn
```

## Fact Tables vs Dimensions

### Dimensions

Dimensions provide descriptive context for analysis.

### `dim_user`

Contains descriptive attributes associated with a user, such as city,
gender, registration method, and registration date.

It represents the user-level analytical entity.

### `dim_date`

Contains calendar information used to analyze activity and subscription
behaviour over time.

### Fact Tables

Facts represent measurable events or outcomes.

### `fact_listening`

Contains daily listening activity for users.

### `fact_subscription`

Contains individual subscription and payment transactions.

### `fact_churn`

Contains the churn outcome for each labelled user.

## Table Grain

| Table | Grain |
|---|---|
| `dim_user` | One row per user |
| `dim_date` | One row per calendar date |
| `fact_listening` | One row per user per calendar day |
| `fact_subscription` | One row per subscription/payment transaction |
| `fact_churn` | One row per labelled user |

Defining the grain explicitly prevents accidental duplication when
tables are joined or aggregated.

## Primary Keys

### `dim_user`

`user_key`

Surrogate primary key for the analytical user dimension.

`msno` is also unique and represents the source-system user identifier.

### `dim_date`

`date_key`

Unique key for each calendar date.

### `fact_listening`

`(user_key, date_key)`

A user should have at most one listening record for a given day.

### `fact_subscription`

`transaction_key`

Each source transaction receives a unique analytical key.

### `fact_churn`

`user_key`

There is one churn outcome per labelled user.

## Foreign Keys

### `fact_listening`

- `user_key` → `dim_user.user_key`
- `date_key` → `dim_date.date_key`

### `fact_subscription`

- `user_key` → `dim_user.user_key`
- `transaction_date_key` → `dim_date.date_key`
- `membership_expire_date_key` → `dim_date.date_key`

### `fact_churn`

- `user_key` → `dim_user.user_key`

These relationships allow facts to be analysed using consistent user
and date attributes.

## Why the Model Is Structured This Way

The source data has different grains.

A user can have many subscription transactions and many listening
records, while the churn outcome exists at the user level.

Joining these sources directly can create a many-to-many multiplication.

For example, if a user has:

- 5 transactions
- 30 listening days

a direct join between the two sources can produce up to 150 rows for
that user. Aggregating those rows could therefore double-count
transactions or listening activity.

The analytical model keeps each fact at its natural grain:

- transactions → transaction grain
- listening → user-day grain
- churn → user grain

When customer-level analysis is required, transaction and listening
facts are first aggregated to the user grain and then combined with the
user and churn information.

This makes aggregations predictable and reduces the risk of
double-counting.

## Population Consideration

The `members` source does not contain every user present in the other
source tables.

Validation found:

- 11.33% of churn-labelled users were absent from `members`.
- 9.99% of transaction users were absent from `members`.
- Only 40 listening users were absent from `members`.

Therefore, `members` is not treated as a complete master population.
The analytical user dimension is designed around the relevant user
population, with member attributes populated where available.

## Model Summary

The model can be explained simply:

> `dim_user` describes who the customer is, `dim_date` describes when
> an event happened, and the fact tables record what happened — their
> listening activity, subscription transactions, and churn outcome.
> Each fact keeps its natural grain, and user-level features are created
> only after the lower-grain facts have been aggregated. This prevents
> one-to-many joins from producing incorrect aggregates.