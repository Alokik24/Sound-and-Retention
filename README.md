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

### Raw Data Layer

The source data is loaded into PostgreSQL without analytical transformations.

```text
PostgreSQL
└── sound_retention
    └── raw
        ├── churn
        ├── members
        ├── transactions
        └── user_logs
```

The raw layer preserves the source-level structure and values. A reproducible Python loader is provided under `src/load/load_raw.py`.

## Business Questions

* Are highly engaged users less likely to churn?
* Does subscription behavior differ between churned and retained users?
* Which customer segments have the highest churn?
* Is recent listening activity associated with churn?

## Pipeline

### Phase 1 — Raw Data Exploration

* Documented source tables and fields.
* Profiled row counts, dates, churn distribution, missing values, duplicates, grain, and invalid values.
* Identified data-quality issues before transformation.

### Phase 2 — Data Preparation

* Raw source data loaded into PostgreSQL.
* Staging and analytical transformations will be added next.

## Data Model

*To be documented as the staging and analytical layers are built.*

## Analysis

*To be completed.*

## Dashboard

*To be completed.*

## Findings

*To be completed.*

## Limitations

*To be documented after analysis.*

