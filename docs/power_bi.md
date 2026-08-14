## Power Query

Power Query is used as the data preparation layer between the
PostgreSQL analytical model and the Power BI semantic model.

The project does not duplicate the source-data cleaning performed
by the Python/Pandas ETL.

Power Query transformations are limited to BI-layer preparation,
including:

- verifying appropriate Power BI data types
- representing missing gender values as `Unknown` for reporting
- making selected fields more readable for dashboard users

The analytical data model and source-level cleaning remain in
Python/PostgreSQL.
