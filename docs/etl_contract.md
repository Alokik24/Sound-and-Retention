# ETL Contract

## Purpose

The ETL pipeline converts the original KKBox source files into
validated, consistently typed data that can be stored and analyzed in
PostgreSQL.

The pipeline separates source preservation, transformation, validation,
storage, and analytical modelling so that each responsibility is clear
and reproducible.

---

## Layer Responsibilities

### 1. Source Layer

Location:

```text
data/raw/
````

Contains the original KKBox source files.

```text
data/raw/
├── members_v3.csv
├── transactions_v2.csv
├── user_logs_v2.csv
└── train_v2.csv
```

The source files are treated as immutable inputs.

No business transformations are applied to the source files themselves.

---

### 2. Python ETL

Location:

```text
src/
├── extract/
├── transform/
├── validate/
└── load/
```

Python/Pandas is responsible for the reproducible data-processing
pipeline.

#### Extract

Read the source files from `data/raw/`.

Large sources such as user_logs_v2.csv are processed in chunks where necessary to avoid excessive memory usage.

#### Transform

Perform source-level preparation required for the staging layer:

* standardize column names
* standardize date representations
* convert data types
* standardize boolean/flag representations
* handle relevant missing values
* handle identified invalid values
* handle duplicates according to the documented table grain

The transformations must preserve the intended grain of each source.

#### Validate

Run data-quality checks before the data is considered ready for
downstream use.

Python checks include:

* required columns
* null required keys
* duplicate keys where uniqueness is expected within the processed data
* invalid dates
* invalid flag/churn values
* impossible numeric values

Large sources are processed in chunks where necessary. Complete-dataset
grain and cross-table relationship checks that depend on the full
PostgreSQL dataset are handled in PostgreSQL.

Validation produces a clear pass/fail result and reports failed checks.

#### Load

Load the prepared data into PostgreSQL.

The loading process should be reproducible rather than requiring manual
data preparation.

---

### 3. PostgreSQL

Database:

```text
sound_retention
```

Schemas:

```text
raw.*
staging.*
analytics.*
```

#### Raw layer

The raw layer preserves the source-level data with minimal
transformation.

Its purpose is to provide a database copy of the original source data
that can be traced back to the files in `data/raw/`.

#### Staging layer

The staging layer contains consistently typed and cleaned versions of
the source tables.

It preserves the source-level grain while providing controlled inputs
for analytical modelling.

#### Analytics layer

The analytics layer contains the intentional analytical model:

```text
analytics.dim_user
analytics.dim_date
analytics.fact_churn
analytics.fact_subscription
analytics.fact_listening
```
It defines keys, relationships, and analytical grains.

PostgreSQL is also responsible for complete-dataset grain checks,
cross-table relationship checks, relational operations, and SQL-based
analysis.

---

### 4. Processed Data

Location:

```text
data/processed/
```

This directory is reserved for useful intermediate ETL outputs.

It should not contain unnecessary duplicate copies of the raw data.

For large sources, an intermediate output should only be persisted when
it provides a practical benefit for reproducibility, debugging, or
pipeline execution.

---

## End-to-End Flow

```text
data/raw/
    │
    ▼
Python Extract
    │
    ▼
Python Transform
    │
    ▼
Python Validate
    │
    ▼
PostgreSQL
    │
    ├── raw.*
    │
    ├── staging.*
    │
    └── analytics.*
             │
             ▼
        SQL Analysis
             │
             ▼
          Findings
             │
             ▼
          Power BI
```

---

## Design Principle

Python is responsible for reproducible source-data processing.

PostgreSQL is responsible for durable relational storage, analytical
modelling, relationships, and SQL analysis.

The pipeline should avoid performing the same transformation in both
Python and SQL without a clear reason.

The goal is not to move every SQL operation into Python. The goal is to
give each layer a clear responsibility and maintain one reproducible
path from source data to analysis.