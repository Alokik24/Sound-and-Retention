# Cleaning Decisions

## Purpose

This document records the data-quality issues identified during source
exploration and the treatment applied before analytical use.

The objective is to distinguish between:

- values that were transformed,
- values that were retained intentionally,
- values that were validated but required no correction, and
- data-quality limitations that were documented rather than silently
  removed.

Raw source files remain unchanged.

---

## 1. Missing Gender

### Issue

`members_v3.gender` contains substantial missing values.

### Impact

- Rows in `members_v3`: 6,769,473
- Missing gender: 4,429,505
- Missing percentage: 65.43%

No other source field was found to contain missing values during the
source-level missing-value profiling.

### Decision

Missing gender values are retained as missing.

No gender value is imputed or inferred.

### Reason

The source does not provide enough information to reliably infer a
user's gender. Imputation would introduce information that is not
present in the source data.

The field is therefore treated as optional demographic information
rather than a required customer attribute.

### Verification

The missing-value profile confirmed that the missing values are
contained in `gender` and that no required `msno` values are missing.

---

## 2. Suspicious / Impossible `bd` Values

### Issue

The `members_v3.bd` field contains values that are clearly suspicious
when interpreted as age.

The source exploration found:

- minimum: `-7168`
- maximum: `2016`
- negative values: `274`
- zero values: `4,540,215`

The field contains no SQL/Pandas nulls, but absence of nulls does not
mean that the values are valid.

### Impact

- Negative values: 274 rows
- Zero values: 4,540,215 rows

### Decision

No additional `bd` cleaning or imputation is performed at this stage.

The field is not used as a primary analytical variable in the current
churn analysis.

### Reason

The exploration established that the field contains suspicious values,
but it did not establish a defensible valid-age range or a reliable rule
for correcting the values.

Replacing the values using an assumed age range would introduce an
unsupported business rule.

The safer analytical decision is to avoid relying on this field until
its semantics and valid range can be established.

### Verification

The exploration notebook records the observed range and counts of
negative and zero values. The Python ETL does not invent corrected age
values.

---

## 3. Users Missing from `members`

### Issue

Not every user appearing in the other source tables has a corresponding
record in `members_v3`.

Relationship validation found:

- Churn-labelled users missing from members: 109,993
- Transaction users missing from members: 119,616
- Listening users missing from members: 40

### Impact

These users do not have the member attributes supplied by
`members_v3`, such as city, gender, or registration method.

### Decision

Affected users are not discarded solely because they are absent from
`members`.

The analytical population retains relevant users, while member
attributes remain unavailable where no corresponding member record
exists.

### Reason

Removing these users would change the population being analysed and
could bias churn or behavioural analysis.

The missing relationship is therefore treated as a data-coverage issue,
not automatically as an invalid customer record.

### Verification

PostgreSQL relationship validation explicitly measures the affected
population.

The analytical model was rebuilt successfully while retaining the
broader user population.

---

## 4. Invalid Dates

### Issue

The source date fields are stored as `YYYYMMDD` integer representations.

The exploration checked the transaction and listening date formats.

### Impact

No invalid date-format values were found.

- Invalid transaction dates: 0
- Invalid listening dates: 0

The observed ranges were:

- Transactions: `2015-01-01` to `2017-03-31`
- Listening activity: `2017-03-01` to `2017-03-31`

### Decision

Dates are converted from the source `YYYYMMDD` representation into
proper date values during the Python transformation stage.

No rows are removed because of invalid dates.

### Reason

The source representation is inconvenient for analysis but is not
itself a data-quality failure.

Converting the representation preserves the underlying date while
making it suitable for PostgreSQL and analytical operations.

### Verification

The source exploration found zero values with invalid 8-digit date
formats.

The Python validation also checks the resulting date fields before
loading them into the staging layer.

---

## 5. Invalid Numeric Values

### Issue

Numeric fields were checked for impossible negative values.

### Impact

No invalid negative values were found in the checked transaction or
listening measures.

Transaction checks found:

- Negative `payment_plan_days`: 0
- Negative `plan_list_price`: 0
- Negative `actual_amount_paid`: 0

Listening checks found zero negative values for:

- `num_25`
- `num_50`
- `num_75`
- `num_985`
- `num_100`
- `num_unq`
- `total_secs`

### Decision

No numeric rows are removed or altered based on these checks.

The values are retained after validation and converted to appropriate
numeric types during transformation.

### Reason

There is no evidence that these fields contain negative values requiring
correction.

Changing valid non-negative values would introduce unnecessary
transformation.

### Verification

Python source-level validation reports zero negative values for all
checked transaction and listening metrics.

---

## 6. Invalid Boolean / Churn Values

### Issue

The source contains binary fields that must contain valid 0/1 values.

The fields checked were:

- `train_v2.is_churn`
- `transactions_v2.is_auto_renew`
- `transactions_v2.is_cancel`

### Impact

No invalid values were found.

- Invalid `is_churn`: 0
- Invalid `is_auto_renew`: 0
- Invalid `is_cancel`: 0

### Decision

The values are retained and converted to boolean representations during
the Python transformation stage.

### Reason

All observed values conform to the expected binary domain.

The transformation changes representation rather than correcting
invalid business values.

### Verification

Python validation checks the allowed values before loading the staging
tables.

---

## 7. Duplicates and Table Grain

### Issue

The source tables have different expected grains.

- `train_v2`: one row per labelled user
- `members_v3`: one row per member
- `transactions_v2`: one row per transaction
- `user_logs_v2`: one row per user per calendar day

### Impact

`transactions_v2` contains:

- 1,431,009 rows
- 1,197,050 unique users

The difference is expected because users can have multiple transactions.
These records are therefore not treated as duplicates merely because
the same `msno` appears more than once.

`train_v2` was verified to contain:

- 970,960 rows
- 970,960 unique users
- 0 duplicate `msno` values

A complete source-level duplicate scan for `members_v3` and
`user_logs_v2` was not completed in the exploration notebook because
the memory-safe approaches were too slow for the available hardware.

### Decision

Transaction records are retained at transaction grain.

`train_v2` duplicate validation passed.

For `user_logs_v2`, the intended grain is enforced/checked as
`msno + date` in the PostgreSQL staging validation because the 18M-row
source is processed in chunks.

No blanket duplicate removal is performed.

### Reason

Repeated users in the transaction table represent legitimate multiple
transactions, not duplicate records.

For listening data, the intended analytical grain is one user per
calendar day. Duplicate detection therefore uses the composite key
`msno + date` rather than `msno` alone.

### Verification

Python validates the expected source-level keys where practical.

PostgreSQL performs the complete-dataset `msno + date` grain check for
the listening table.

---

## Summary

| Issue | Treatment | Verification |
|---|---|---|
| Missing gender | Retained as missing | Missing-value profiling |
| Suspicious `bd` | Not corrected; excluded from primary analysis | Range and frequency profiling |
| Users missing from members | Retained; treated as relationship warnings | PostgreSQL relationship checks |
| Invalid dates | Converted to proper dates; no invalid values found | Python validation |
| Invalid numeric values | No correction required | Python validation |
| Invalid boolean/churn values | Converted to boolean; no invalid values found | Python validation |
| Duplicates | Handled according to table grain; no blanket deduplication | Python + PostgreSQL grain checks |

## Overall Principle

Cleaning decisions are based on observed data quality and documented
table grain rather than assumptions about what the data "should" look
like.

Where a value is demonstrably invalid, the pipeline validates and
handles it according to the defined transformation rules.

Where the correct treatment is uncertain, the issue is documented and
the data is not silently altered.