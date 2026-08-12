# Sound-and-Retention

## Business Problem

A music-streaming company wants to understand which listening and subscription behaviors are associated with customer churn so that retention teams can identify higher-risk customer segments.

## Dataset

Source: KKBox customer churn dataset, obtained from Kaggle.

The project uses four source tables:

- `train_v2.csv` — churn labels
- `members_v3.csv` — member/customer information
- `transactions_v2.csv` — subscription and payment behavior
- `user_logs_v2.csv` — listening activity

The raw source files are stored locally under `data/raw/` and are not committed to the repository.

## Business Questions

- Are highly engaged users less likely to churn?
- Does subscription behavior differ between churned and retained users?
- Which customer segments have the highest churn?
- Is recent listening activity associated with churn?

## Pipeline

### Phase 1 — Data Exploration

- Documented the source tables, fields, and their grains.
- Profiled row counts, date ranges, churn distribution, missing values, duplicates, and invalid values.
- Identified data-quality issues before transformation.

### Phase 2 — Data Preparation

#### Raw Layer

Source data is preserved in PostgreSQL with minimal transformation:

```text
PostgreSQL
└── sound_retention
    └── raw
        ├── churn
        ├── members
        ├── transactions
        └── user_logs
````

A reproducible Python loader is provided at:

```text
src/load/load_raw.py
```

The full reproducible Python/Pandas ETL pipeline will be completed before
the Power BI layer.

#### Staging Layer

Source tables are converted into consistently typed staging tables:

```text
raw.*
   ↓
staging.*
```

The staging layer standardizes dates, boolean flags, column representations, and other source-level data types while preserving the source-level grain.

#### Validation

Automated SQL validation checks the staging data for:

* missing required keys
* unexpected duplicate keys
* invalid dates
* invalid churn/flag values
* impossible numeric values
* unexpected cross-table relationships

Relationship coverage warnings are retained rather than silently discarding affected users.

## Data Model

The analytical model uses explicit grains and separates descriptive
dimensions from measurable fact tables.

- `dim_user` — one row per user
- `dim_date` — one row per calendar date
- `fact_churn` — one row per labelled user
- `fact_subscription` — one row per subscription/payment transaction
- `fact_listening` — one row per user per calendar day

Transaction and listening data are aggregated to the user level before
being combined for customer-level churn analysis.

See [`docs/analytical_model.md`](docs/analytical_model.md) for the grain
definitions and modelling decisions.

See [`docs/data_model.md`](docs/data_model.md) for the ERD, keys,
relationships, and fact/dimension design.

## Analysis

The analysis uses SQL to investigate the four business questions:

- Engagement and churn
- Subscription behaviour and churn
- Customer segment differences
- Recent listening activity and churn

The SQL analysis uses multi-table joins, CTEs, CASE-based classifications,
and window functions while preserving the intended analytical grain.

The detailed business-question analysis is documented in
`docs/business_questions.md`.

## Dashboard

*To be completed.*

## Findings
*To be documented in Phase 6.*

## Limitations
*To be documented alongside the findings after the analysis.*