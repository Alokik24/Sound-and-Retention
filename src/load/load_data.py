from io import StringIO

import pandas as pd
import psycopg


DB_NAME = "sound_retention"


STAGING_COLUMNS = {
    "churn": [
        "msno",
        "is_churn",
    ],
    "members": [
        "msno",
        "city",
        "bd",
        "gender",
        "registered_via",
        "registration_date",
    ],
    "transactions": [
        "msno",
        "payment_method_id",
        "payment_plan_days",
        "plan_list_price",
        "actual_amount_paid",
        "is_auto_renew",
        "transaction_date",
        "membership_expire_date",
        "is_cancel",
    ],
    "user_logs": [
        "msno",
        "date",
        "num_25",
        "num_50",
        "num_75",
        "num_985",
        "num_100",
        "num_unq",
        "total_secs",
    ],
}


def _copy_dataframe(
    conn,
    df: pd.DataFrame,
    table_name: str,
):
    if df.empty:
        return

    columns = STAGING_COLUMNS[table_name]

    output = StringIO()

    export_df = df[columns].copy()

    export_df.to_csv(
        output,
        index=False,
        header=False,
        na_rep="\\N",
    )

    output.seek(0)

    column_list = ", ".join(columns)

    with conn.cursor() as cur:
        with cur.copy(
            f"""
            COPY staging.{table_name}
            ({column_list})
            FROM STDIN
            WITH (
                FORMAT csv,
                NULL '\\N'
            )
            """
        ) as copy:
            copy.write(output.getvalue())


def load_small_tables(
    conn,
    churn,
    members,
    transactions,
):
    with conn.cursor() as cur:
        cur.execute(
            "TRUNCATE staging.churn, "
            "staging.members, "
            "staging.transactions, "
            "staging.user_logs"
        )

    _copy_dataframe(
        conn,
        churn,
        "churn",
    )

    _copy_dataframe(
        conn,
        members,
        "members",
    )

    _copy_dataframe(
        conn,
        transactions,
        "transactions",
    )


def load_user_log_chunk(
    conn,
    chunk,
):
    _copy_dataframe(
        conn,
        chunk,
        "user_logs",
    )