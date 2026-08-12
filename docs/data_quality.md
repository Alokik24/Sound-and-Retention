## Relationship Coverage

The `members` table does not contain every user present in the other
source tables.

- 11.33% of churn-labelled users are absent from `members`.
- 9.99% of users with transactions are absent from `members`.
- Only 40 listening users are absent from `members`.

These are treated as relationship warnings rather than automatically
discarding the affected records.

The analytical model uses a combined user population, with member
attributes populated where available. Customer-level churn analysis is
anchored on labelled users and uses left joins for optional listening and
subscription behaviour.