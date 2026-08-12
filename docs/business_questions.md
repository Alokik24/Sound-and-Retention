# Ticket 5.5 — SQL → Result → Interpretation

## Q1 — Are highly engaged users less likely to churn?

### SQL

`sql/13_business_questions.sql` — Q1 section.

The analysis groups labelled users by number of listening days:

* 0 = No listening
* 1–7 = Low
* 8–30 = Medium
* 31+ = High

### Result

| Engagement   |   Users | Churned | Churn rate |
| ------------ | ------: | ------: | ---------: |
| No listening | 216,409 |  19,690 |      9.10% |
| Low          | 153,219 |  18,953 | **12.37%** |
| Medium       | 540,415 |  44,227 |      8.18% |
| High         |  60,917 |   4,460 |  **7.32%** |

### Interpretation

Yes, **higher listening engagement is associated with lower churn in this dataset**.

The strongest contrast is between low and high engagement:

> Low engagement: **12.37% churn**
> High engagement: **7.32% churn**

That's a roughly **5 percentage-point difference**.

However, the "No listening" group has 9.10% churn, so the relationship isn't simply "more listening = monotonically lower churn." The particularly high churn rate appears among the **low-engagement group**.

**What we can say:** engagement level is associated with churn.

**What we cannot say:** increasing someone's listening activity will necessarily cause them to stay.

---

# Q2 — Does subscription behaviour differ between churned and retained users?

### Result

| Status   |   Users | Avg transactions | Avg total paid | Avg transaction | Auto-renew | Cancellation |
| -------- | ------: | ---------------: | -------------: | --------------: | ---------: | -----------: |
| Churned  |  87,330 |             1.30 |        ₹349.67 |         ₹367.03 |     69.91% |       17.25% |
| Retained | 883,630 |             1.15 |        ₹151.24 |         ₹129.00 |     94.05% |        1.31% |

### Interpretation

There is a **substantial difference in subscription behaviour** between churned and retained users.

Churned users have:

* slightly more transactions on average: **1.30 vs 1.15**
* considerably higher average total payment: **₹349.67 vs ₹151.24**
* much lower auto-renewal activity: **69.91% vs 94.05%**
* substantially higher cancellation activity: **17.25% vs 1.31%**

The strongest signal is therefore not transaction volume. It is the difference in **auto-renewal and cancellation behaviour**.

**What we can say:** these subscription behaviours are strongly associated with churn.

**What we cannot say:** cancellation or lack of auto-renewal necessarily caused the churn. They may be part of the churn process itself.

---

# Q3 — Which customer segments have the highest churn?

We have two segmentation views.

### Registration method

| Registration method |   Users | Churn rate |
| ------------------: | ------: | ---------: |
|                   4 |  52,744 | **23.10%** |
|                   3 | 106,459 | **17.23%** |
|                   9 | 235,689 | **12.68%** |
|                  13 |   3,391 |      9.88% |
|             Unknown | 109,993 |      5.35% |
|                   7 | 462,684 |  **4.47%** |

### Interpretation

Registration method shows a large difference in observed churn.

Method **4 has the highest churn rate at 23.10%**, while method **7 has 4.47%**.

That's a very large descriptive difference.

But there's an important caveat: we **shouldn't interpret `Unknown` as a genuine low-churn customer segment**. Those users are largely explained by the relationship problem we already discovered: some churn-labelled users have no corresponding `members` record.

So the useful finding is:

> **Registration method 4 has substantially higher observed churn than the other well-populated registration groups.**

### City

The highest observed city-level churn rates among cities with at least 1,000 labelled users were:

* City 21 — **14.71%**
* City 12 — **13.92%**
* City 8 — **13.45%**
* City 3 — **13.29%**
* City 10 — **13.26%**

But I would treat this as a **secondary segmentation finding**, not the strongest conclusion. Geographic differences could reflect underlying differences in customer composition, acquisition channels, or other factors we haven't controlled for.

---

# Q4 — Is recent listening activity associated with churn?

### Result

| Recency      |   Users | Churned | Churn rate |
| ------------ | ------: | ------: | ---------: |
| 0–7 days     | 667,498 |  44,633 |  **6.69%** |
| 8–14 days    |  44,300 |   8,362 | **18.88%** |
| 15–30 days   |  42,753 |  14,645 | **34.25%** |
| No listening | 216,409 |  19,690 |  **9.10%** |

There is no `31+ days` group in the result. That's not necessarily an error: given the observation period represented by the listening data, there may simply be no labelled users whose last observed listening activity falls beyond that interval.

### Interpretation

This is probably the **strongest finding in the project**.

Users whose last listening activity was:

* within 7 days → **6.69% churn**
* 8–14 days ago → **18.88% churn**
* 15–30 days ago → **34.25% churn**

That's a very clear relationship between **recency of listening and observed churn**.

The jump from 0–7 days to 15–30 days is particularly large:

> **6.69% → 34.25%**

So declining listening recency could be a useful **retention warning signal**.

But again:

> This is an association, not evidence that reduced listening causes churn.

Also, the "No listening" group being at 9.10% means we shouldn't blindly interpret "no activity" as the highest-risk category. The **15–30 day inactive group** is the striking one here.
