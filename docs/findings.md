# Findings

The analysis identifies several behavioural and subscription patterns
associated with customer churn. These findings are descriptive
associations within the labelled KKBox customer population and should
not be interpreted as causal effects.

---

## Finding 1 — Lower listening engagement is associated with higher churn

### Finding

Users with low listening engagement have a higher observed churn rate
than users with medium or high engagement.

### Evidence

The observed churn rates by listening engagement were:

| Engagement level | Users | Churn rate |
|---|---:|---:|
| No listening | 216,409 | 9.10% |
| Low | 153,219 | 12.37% |
| Medium | 540,415 | 8.18% |
| High | 60,917 | 7.32% |

The highest churn rate was observed among low-engagement users at
12.37%, compared with 7.32% among highly engaged users.

### Interpretation

Lower engagement appears to be associated with greater churn risk.
This suggests that declining engagement could be useful as a signal for
identifying customers who may require retention attention.

The relationship is not perfectly monotonic because the no-listening
group had a 9.10% churn rate, between the low and medium engagement
groups.

### Limitation

The analysis establishes an association, not causation. It does not
show that increasing listening activity would cause customers to remain
subscribed.

The engagement bands are also analytical groupings rather than
externally validated thresholds.

---

## Finding 2 — Subscription commitment differs substantially between churned and retained users

### Finding

Churned and retained users show substantially different auto-renewal
and cancellation behaviour.

### Evidence

| Customer status | Avg transactions | Avg total paid | Auto-renew transactions | Cancelled transactions |
|---|---:|---:|---:|---:|
| Churned | 1.30 | 349.67 | 69.91% | 17.25% |
| Retained | 1.15 | 151.24 | 94.05% | 1.31% |

Churned users had a much lower proportion of auto-renewing
transactions and a much higher proportion of cancelled transactions.

### Interpretation

Subscription commitment appears strongly associated with retention.
In particular, auto-renewal and cancellation behaviour may provide
useful signals for identifying customers at higher risk of churn.

The difference in transaction count itself is relatively small, so
transaction frequency does not appear to be as distinctive as
subscription-state behaviour.

### Limitation

The analysis cannot establish whether cancellation or reduced
auto-renewal causes churn. These behaviours may occur as part of the
churn process itself.

The payment differences also should not be interpreted as evidence that
higher spending causes retention.

---

## Finding 3 — Some customer segments have substantially different churn rates

### Finding

Observed churn varies considerably across registration methods and
cities.

### Evidence

For registration method, the observed churn rates were:

| Registration method | Users | Churn rate |
|---:|---:|---:|
| 4 | 52,744 | 23.10% |
| 3 | 106,459 | 17.23% |
| 9 | 235,689 | 12.68% |
| 13 | 3,391 | 9.88% |
| 7 | 462,684 | 4.47% |

Among cities with at least 1,000 labelled users, the highest observed
churn rates included:

- City 21 — 14.71%
- City 12 — 13.92%
- City 8 — 13.45%
- City 3 — 13.29%
- City 10 — 13.26%

### Interpretation

Registration method appears to be a stronger differentiator than the
individual city results examined here. In particular, users associated
with registration method 4 had an observed churn rate of 23.10%.

This suggests that acquisition or registration channels may be useful
dimensions for retention segmentation.

### Limitation

These are descriptive segment comparisons. The analysis does not
control for differences in customer composition between segments.

The `Unknown` registration group should also not be interpreted as a
genuine low-risk segment because the data-quality investigation found
that some churn-labelled users do not have corresponding member
records.

---

## Finding 4 — Recency of listening activity is strongly associated with churn

### Finding

Users whose most recent listening activity was further in the past had
substantially higher observed churn rates.

### Evidence

| Last listening activity | Users | Churn rate |
|---|---:|---:|
| 0–7 days | 667,498 | 6.69% |
| 8–14 days | 44,300 | 18.88% |
| 15–30 days | 42,753 | 34.25% |
| No listening | 216,409 | 9.10% |

Churn increased from 6.69% among users active within the previous
7 days to 34.25% among users whose last observed activity was
15–30 days earlier.

### Interpretation

Recent listening activity is one of the strongest behavioural signals
observed in the analysis.

A substantial increase in churn is visible as the user's last observed
listening activity becomes less recent. This suggests that declining
activity recency could be useful for a retention team as an early
warning indicator.

### Limitation

This is an observational association and does not establish that
reduced listening causes churn.

The recency measure is calculated relative to the final listening date
available in the dataset rather than a customer-specific intervention
or controlled observation period. Therefore, it should be treated as a
descriptive signal rather than a causal churn predictor.

---

## Overall Business Takeaway

The analysis suggests that churn is associated with a combination of
behavioural engagement and subscription commitment.

The strongest signals observed are:

1. Low listening engagement is associated with higher churn.
2. Less recent listening activity is associated with substantially
   higher churn.
3. Churned users show much lower auto-renewal activity and much higher
   cancellation activity.
4. Churn varies substantially across registration and geographic
   segments.

For a hypothetical retention team, these findings suggest that
monitoring changes in listening recency, engagement, and subscription
behaviour could help identify customer segments that warrant further
investigation.

These findings should be treated as associations rather than causal
effects.