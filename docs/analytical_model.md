# Analytical Model

## Grain Definitions

The analytical model uses explicit row-level grains to prevent
double-counting during joins and aggregations.

### User Grain

> One row represents one user (`msno`).

The user-level table is the primary analytical population. It contains
one record per user and is used for customer-level churn and segmentation
analysis.

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
```

Transaction and listening records must be aggregated to the user grain
before being joined into a user-level analytical dataset. This prevents
one-to-many joins from multiplying rows and causing incorrect aggregates.

### Population Note

The members table does not contain every user found in the other
source tables. Relationship validation identified missing member
records for approximately 11.33% of churn-labelled users and 9.99% of
transaction users, while only 40 listening users were absent.

Therefore, the final analytical population and join strategy must be
defined explicitly rather than assuming that members is a complete
master user table.