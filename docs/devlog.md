## Data

**What did you clean?**

I standardized source representations in Python before loading staging data. That includes column representations, dates, numeric types, and boolean/flag fields. I also applied the documented handling for relevant missing/invalid values while preserving the source grain.

**What did you deliberately not clean?**

I did not invent corrections for ambiguous fields. In particular, I did not try to "fix" `bd`, because the exploration showed values ranging from `-7168` to `2016` and a very large number of zeros, but we did not establish a defensible rule for determining the correct age. I also did not impute missing gender.

**How did you handle missing values?**

Required keys such as `msno` are validated. Missing optional attributes such as gender are retained rather than artificially imputed. Missing member relationships are treated separately as relationship/coverage issues.

**How did you handle suspicious values?**

Clearly invalid values are caught by validation. For example, negative payment amounts, plan durations, and listening metrics are checked. No negative values were found in those validated metrics. Suspicious `bd` values were documented rather than arbitrarily corrected.

**How did you handle duplicates?**

Duplicates are interpreted according to table grain. A repeated `msno` in transactions is **not automatically a duplicate**, because one user can have many transactions. Churn is expected to be one row per user. Listening is expected to be one row per user per date, so the relevant key is `msno + date`.

**What happened to users missing from `members`?**

They weren't automatically deleted. We found 109,993 churn users, 119,616 transaction users, and 40 listening users without a corresponding member record. They remain in the broader analytical population, while unavailable member attributes remain unavailable.

---

## Analysis

**What is the grain of each source?**

```text
train_v2       → one row per labelled user
members_v3     → one row per member
transactions   → one row per transaction
user_logs      → one row per user per calendar day
```

**What is the analytical population?**

The analytical user population is not restricted to `members`. `dim_user` contains the combined relevant user population, while `fact_churn` contains the labelled churn population.

For the four churn questions, the labelled population is the important analytical population: **970,960 labelled users**.

**Which transformations happen in Python?**

Source extraction, type/representation standardization, date conversion, boolean conversion, relevant source-level cleaning, and source-level validation happen in Python/Pandas. Large `user_logs` data is processed in chunks.

**Which checks happen in PostgreSQL?**

Checks that require the complete relational dataset, particularly complete-dataset grain and cross-table relationship checks, happen in PostgreSQL. PostgreSQL then provides the relational storage, analytical model, and SQL analysis.

**Why weren't raw records simply deleted when they had missing relationships?**

Because a missing relationship does not necessarily mean the record itself is invalid.

For example, a churn-labelled user absent from `members` still has a valid churn label. Deleting that user would change the population being analyzed and could introduce selection bias. We therefore preserve the record and treat the missing member relationship as a data-coverage limitation.

---

## The sequence you should remember

> **"I started by profiling the four source tables and establishing their grains. I then identified missing values, suspicious fields, invalid dates and numeric values, duplicates, and cross-table relationship issues. In the Python/Pandas ETL, I standardized the source representations and types, converted dates and flags, and validated required keys and value ranges before loading the data into PostgreSQL staging. I deliberately didn't impute missing gender or invent corrections for the suspicious `bd` field because there wasn't a defensible rule for doing so. Users missing from the members table were retained rather than dropped, because those records can still contain valid churn, transaction, or listening information. PostgreSQL then handled the complete-dataset relationship and grain checks before the data was loaded into the analytical model."**

### Evidence chain

And these four artifacts should now tell the same story:

```text
docs/cleaning_decisions.md
        ↕
notebooks/02_eda_cleaning.ipynb
        ↕
src/transform/
src/validate/
        ↕
PostgreSQL staging
```
