import psycopg

from src.extract.extract_data import (
    extract_small_table,
    extract_user_logs,
)

from src.transform.transform_data import (
    transform_churn,
    transform_members,
    transform_transactions,
    transform_user_logs,
)

from src.validate.validate_data import (
    validate_churn,
    validate_members,
    validate_transactions,
    validate_user_logs,
    merge_chunk_results,
    print_results,
)

from src.load.load_data import (
    load_small_tables,
    load_user_log_chunk,
)


DB_NAME = "sound_retention"


def main():
    print("=" * 70)
    print("SOUND & RETENTION — PYTHON/PANDAS ETL")
    print("=" * 70)

    # ---------------------------------------------------------
    # EXTRACT
    # ---------------------------------------------------------

    print("\n[1/4] Extracting source data...")

    churn = extract_small_table("churn")
    members = extract_small_table("members")
    transactions = extract_small_table("transactions")
    user_logs = extract_user_logs()

    print(f"churn:        {len(churn):,}")
    print(f"members:      {len(members):,}")
    print(f"transactions: {len(transactions):,}")
    print("user_logs:    chunked")

    # ---------------------------------------------------------
    # TRANSFORM
    # ---------------------------------------------------------

    print("\n[2/4] Transforming source data...")

    churn = transform_churn(churn)
    members = transform_members(members)
    transactions = transform_transactions(transactions)

    # ---------------------------------------------------------
    # VALIDATE SMALL TABLES
    # ---------------------------------------------------------

    print("\n[3/4] Validating source/staging data...")

    results = []

    results.extend(validate_churn(churn))
    results.extend(validate_members(members))
    results.extend(validate_transactions(transactions))

    # User-log validation is accumulated across chunks.
    user_log_validation = []

    # ---------------------------------------------------------
    # LOAD
    # ---------------------------------------------------------

    with psycopg.connect(
        f"dbname={DB_NAME}"
    ) as conn:

        load_small_tables(
            conn,
            churn,
            members,
            transactions,
        )

        # -----------------------------------------------------
        # USER LOGS:
        # CHUNK → TRANSFORM → VALIDATE → LOAD
        # -----------------------------------------------------

        total_log_rows = 0

        for chunk_number, chunk in enumerate(
            user_logs,
            start=1,
        ):
            transformed = transform_user_logs(chunk)

            chunk_results = validate_user_logs(
                transformed
            )

            # Accumulate validation results instead of
            # printing/repeating them for every chunk.
            user_log_validation = merge_chunk_results(
                user_log_validation,
                chunk_results,
            )

            # Stop immediately if this chunk contains
            # invalid data.
            if any(
                r["status"] == "FAIL"
                for r in chunk_results
            ):
                print_results(chunk_results)

                raise RuntimeError(
                    f"user_logs validation failed "
                    f"on chunk {chunk_number}."
                )

            load_user_log_chunk(
                conn,
                transformed,
            )

            total_log_rows += len(transformed)

            if chunk_number % 10 == 0:
                print(
                    f"  user_logs: "
                    f"{total_log_rows:,} rows processed"
                )

        # Add the aggregated user-log results once.
        results.extend(user_log_validation)

        # Only commit after all validation/loading succeeds.
        conn.commit()

    # ---------------------------------------------------------
    # FINAL VALIDATION REPORT
    # ---------------------------------------------------------

    print_results(results)

    failed = [
        r
        for r in results
        if r["status"] == "FAIL"
    ]

    if failed:
        raise RuntimeError(
            "ETL validation failed. "
            "Review the results above."
        )

    print("\nETL COMPLETE.")
    print("PostgreSQL staging tables loaded.")


if __name__ == "__main__":
    main()