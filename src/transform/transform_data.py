import pandas as pd


def _clean_msno(df):
    df = df.copy()
    df["msno"] = df["msno"].astype("string").str.strip()
    return df


def _parse_yyyymmdd(series):
    values = series.astype("string").str.strip()

    valid_format = values.str.fullmatch(r"\d{8}")

    return pd.to_datetime(
        values.where(valid_format),
        format="%Y%m%d",
        errors="coerce",
    )


def transform_churn(df):
    df = _clean_msno(df)

    df["is_churn"] = pd.to_numeric(
        df["is_churn"],
        errors="coerce",
    ).map({
        0: False,
        1: True,
    })

    return df[["msno", "is_churn"]]


def transform_members(df):
    df = _clean_msno(df)

    df["gender"] = (
        df["gender"]
        .astype("string")
        .str.strip()
        .replace("", pd.NA)
    )

    df["registration_date"] = _parse_yyyymmdd(
        df["registration_init_time"]
    )

    return df[
        [
            "msno",
            "city",
            "bd",
            "gender",
            "registered_via",
            "registration_date",
        ]
    ]


def transform_transactions(df):
    df = _clean_msno(df)

    numeric_columns = [
        "payment_method_id",
        "payment_plan_days",
        "plan_list_price",
        "actual_amount_paid",
        "is_auto_renew",
        "is_cancel",
    ]

    for column in numeric_columns:
        df[column] = pd.to_numeric(
            df[column],
            errors="coerce",
        )

    df["is_auto_renew"] = df["is_auto_renew"].map({
        0: False,
        1: True,
    })

    df["is_cancel"] = df["is_cancel"].map({
        0: False,
        1: True,
    })

    df["transaction_date"] = _parse_yyyymmdd(
        df["transaction_date"]
    )

    df["membership_expire_date"] = _parse_yyyymmdd(
        df["membership_expire_date"]
    )

    return df[
        [
            "msno",
            "payment_method_id",
            "payment_plan_days",
            "plan_list_price",
            "actual_amount_paid",
            "is_auto_renew",
            "transaction_date",
            "membership_expire_date",
            "is_cancel",
        ]
    ]


def transform_user_logs(df):
    df = _clean_msno(df)

    numeric_columns = [
        "num_25",
        "num_50",
        "num_75",
        "num_985",
        "num_100",
        "num_unq",
        "total_secs",
    ]

    for column in numeric_columns:
        df[column] = pd.to_numeric(
            df[column],
            errors="coerce",
        )

    df["date"] = _parse_yyyymmdd(df["date"])

    return df[
        [
            "msno",
            "date",
            "num_25",
            "num_50",
            "num_75",
            "num_985",
            "num_100",
            "num_unq",
            "total_secs",
        ]
    ]