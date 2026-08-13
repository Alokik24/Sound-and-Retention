# Processed Data Decision

## Decision

`data/processed/` is not used for persisted copies of the main
transformed datasets.

The directory is retained in the repository with `.gitkeep` so that its
intended purpose remains explicit.

## Reason

The Python/Pandas ETL currently performs:

```text
data/raw/
    ↓
Extract
    ↓
Transform
    ↓
Validate
    ↓
Load
    ↓
PostgreSQL staging.*
````

The transformed data is loaded directly into PostgreSQL after
validation.

Persisting another copy of the large transformed tables under
`data/processed/` would duplicate substantial amounts of data without
providing a meaningful reproducibility or analytical benefit.

The raw source files remain the reproducible input, while PostgreSQL
staging provides the persisted transformed representation.

## What May Be Stored Here

Small intermediate artifacts may be added in the future if they provide
a specific benefit for debugging, reproducibility, or analysis.

Large duplicate copies of the raw or staging datasets should not be
stored here.

## Current State

```text
data/
├── raw/
│   └── .gitkeep
└── processed/
    └── .gitkeep
```

No persisted processed dataset is currently required.