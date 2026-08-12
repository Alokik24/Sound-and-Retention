from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = PROJECT_ROOT / "data" / "raw"

SOURCE_FILES = {
    "churn": "train_v2.csv",
    "members": "members_v3.csv",
    "transactions": "transactions_v2.csv",
    "user_logs": "user_logs_v2.csv",
}

USER_LOG_CHUNK_SIZE = 100_000


def extract_small_table(table_name: str) -> pd.DataFrame:
    path = DATA_DIR / SOURCE_FILES[table_name]

    if not path.exists():
        raise FileNotFoundError(f"Source file not found: {path}")

    return pd.read_csv(path)


def extract_user_logs():
    path = DATA_DIR / SOURCE_FILES["user_logs"]

    if not path.exists():
        raise FileNotFoundError(f"Source file not found: {path}")

    return pd.read_csv(
        path,
        chunksize=USER_LOG_CHUNK_SIZE,
    )


def extract_all():
    return {
        "churn": extract_small_table("churn"),
        "members": extract_small_table("members"),
        "transactions": extract_small_table("transactions"),
        "user_logs": extract_user_logs(),
    }