from pathlib import Path

import psycopg


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = PROJECT_ROOT / "data" / "raw"

DB_NAME = "sound_retention"

TABLES = {
    "churn": "train_v2.csv",
    "members": "members_v3.csv",
    "transactions": "transactions_v2.csv",
    "user_logs": "user_logs_v2.csv",
}


def load_table(conn, table_name, filename):
    path = DATA_DIR / filename

    print(f"Loading {filename} -> raw.{table_name}")

    with conn.cursor() as cur:
        with cur.copy(
            f"COPY raw.{table_name} FROM STDIN WITH (FORMAT csv, HEADER true)"
        ) as copy:
            with path.open("rb") as f:
                while chunk := f.read(1024 * 1024):
                    copy.write(chunk)

    print(f"Loaded {table_name}")


def main():
    with psycopg.connect(f"dbname={DB_NAME}") as conn:
        for table_name, filename in TABLES.items():
            load_table(conn, table_name, filename)

        conn.commit()

    print("Raw load complete.")


if __name__ == "__main__":
    main()