import pandas as pd


def _record(
    results,
    check_name,
    failed_rows,
):
    results.append(
        {
            "check_name": check_name,
            "failed_rows": int(failed_rows),
            "status": (
                "PASS"
                if failed_rows == 0
                else "FAIL"
            ),
        }
    )


def validate_churn(df):
    results = []

    _record(
        results,
        "churn: null msno",
        df["msno"].isna().sum(),
    )

    _record(
        results,
        "churn: duplicate msno",
        df["msno"].duplicated().sum(),
    )

    _record(
        results,
        "churn: invalid is_churn",
        df["is_churn"].isna().sum(),
    )

    return results


def validate_members(df):
    results = []

    _record(
        results,
        "members: null msno",
        df["msno"].isna().sum(),
    )

    _record(
        results,
        "members: duplicate msno",
        df["msno"].duplicated().sum(),
    )

    _record(
        results,
        "members: invalid registration_date",
        df["registration_date"].isna().sum(),
    )

    return results


def validate_transactions(df):
    results = []

    _record(
        results,
        "transactions: null msno",
        df["msno"].isna().sum(),
    )

    _record(
        results,
        "transactions: invalid transaction_date",
        df["transaction_date"].isna().sum(),
    )

    _record(
        results,
        "transactions: invalid membership_expire_date",
        df["membership_expire_date"].isna().sum(),
    )

    _record(
        results,
        "transactions: invalid auto_renew",
        df["is_auto_renew"].isna().sum(),
    )

    _record(
        results,
        "transactions: invalid cancel",
        df["is_cancel"].isna().sum(),
    )

    _record(
        results,
        "transactions: negative payment_plan_days",
        (df["payment_plan_days"] < 0).sum(),
    )

    _record(
        results,
        "transactions: negative plan_list_price",
        (df["plan_list_price"] < 0).sum(),
    )

    _record(
        results,
        "transactions: negative actual_amount_paid",
        (df["actual_amount_paid"] < 0).sum(),
    )

    return results


def validate_user_logs(df):
    results = []

    _record(
        results,
        "user_logs: null msno",
        df["msno"].isna().sum(),
    )

    _record(
        results,
        "user_logs: invalid date",
        df["date"].isna().sum(),
    )

    duplicate_count = df.duplicated(
        subset=["msno", "date"]
    ).sum()

    _record(
        results,
        "user_logs: duplicate msno + date",
        duplicate_count,
    )

    numeric_columns = [
        "num_25",
        "num_50",
        "num_75",
        "num_985",
        "num_100",
        "num_unq",
        "total_secs",
    ]

    negative_rows = (
        df[numeric_columns]
        .lt(0)
        .any(axis=1)
        .sum()
    )

    _record(
        results,
        "user_logs: negative listening metrics",
        negative_rows,
    )

    return results


def merge_chunk_results(
    aggregate,
    chunk_results,
):
    """
    Add validation results from one user_logs chunk
    into the accumulated validation results.
    """
    if not aggregate:
        return chunk_results.copy()

    for existing, current in zip(
        aggregate,
        chunk_results,
    ):
        existing["failed_rows"] += current["failed_rows"]

        if current["status"] == "FAIL":
            existing["status"] = "FAIL"

    return aggregate


def print_results(results):
    print("\nETL VALIDATION RESULTS")
    print("=" * 70)

    for result in results:
        print(
            f"{result['status']:4} | "
            f"{result['check_name']:<50} | "
            f"{result['failed_rows']}"
        )