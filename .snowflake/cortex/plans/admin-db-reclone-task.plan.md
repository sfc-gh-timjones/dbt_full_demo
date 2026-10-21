# Plan: Admin DB + Daily Re-clone Task

## Overview

Prod is the only environment that accumulates new data via the daily insert task. DEV and TEST stay fresh by re-cloning PROD_RAW_DB each day, immediately after the insert completes, then having dbt run `--full-refresh` against the new snapshot.

The re-clone task lives in a new **ADMIN_DB** so it is never copied into the clones it manages.

---

## 1. `03_remaining_setup.sql` — add ADMIN_DB

In the SYSADMIN database-creation block, add:

```sql
-- Admin database: holds maintenance procedures/tasks that must never be cloned.
CREATE DATABASE IF NOT EXISTS ADMIN_DB;
```

No ownership transfer needed — SYSADMIN keeps it.

---

## 2. `04_incremental_data.sql` — re-clone procedure + chained task

### Procedure: `ADMIN_DB.PUBLIC.REFRESH_DEV_TEST_CLONES`

```sql
CREATE OR REPLACE PROCEDURE ADMIN_DB.PUBLIC.REFRESH_DEV_TEST_CLONES()
  RETURNS VARCHAR
  LANGUAGE SQL
  EXECUTE AS OWNER          -- runs as SYSADMIN, which owns all raw databases
AS
$$
BEGIN
    -- -----------------------------------------------------------------------
    -- Re-clone DEV_RAW_DB
    -- COPY GRANTS preserves the database-level USAGE grant for DEV_ANALYTICS_RL
    -- (from the object being replaced). Schema and table grants are on new
    -- objects that carry PROD's grants, so we re-apply them explicitly.
    -- -----------------------------------------------------------------------
    CREATE OR REPLACE DATABASE DEV_RAW_DB CLONE PROD_RAW_DB COPY GRANTS;

    -- Drop cloned task/procedure — both are hard-coded to write to PROD_RAW_DB
    DROP TASK      IF EXISTS DEV_RAW_DB.PUBLIC.DAILY_DATA_INSERT;
    DROP PROCEDURE IF EXISTS DEV_RAW_DB.PUBLIC.INSERT_INCREMENTAL_DATA();

    -- Re-apply schema and table grants (SYSADMIN owns these objects, so no
    -- MANAGE GRANTS needed; FUTURE TABLE grants require MANAGE GRANTS and are
    -- omitted — the schema is static post-clone so no new tables will appear)
    GRANT USAGE  ON SCHEMA   DEV_RAW_DB.ORACLE              TO ROLE DEV_ANALYTICS_RL;
    GRANT SELECT ON ALL TABLES IN DATABASE DEV_RAW_DB        TO ROLE DEV_ANALYTICS_RL;

    -- -----------------------------------------------------------------------
    -- Re-clone TEST_RAW_DB (same pattern)
    -- -----------------------------------------------------------------------
    CREATE OR REPLACE DATABASE TEST_RAW_DB CLONE PROD_RAW_DB COPY GRANTS;

    DROP TASK      IF EXISTS TEST_RAW_DB.PUBLIC.DAILY_DATA_INSERT;
    DROP PROCEDURE IF EXISTS TEST_RAW_DB.PUBLIC.INSERT_INCREMENTAL_DATA();

    GRANT USAGE  ON SCHEMA   TEST_RAW_DB.ORACLE             TO ROLE TEST_ANALYTICS_RL;
    GRANT SELECT ON ALL TABLES IN DATABASE TEST_RAW_DB       TO ROLE TEST_ANALYTICS_RL;

    RETURN 'DEV_RAW_DB and TEST_RAW_DB refreshed from PROD_RAW_DB.';
END;
$$;
```

**Grant notes:**
- `COPY GRANTS` on the database preserves the database-level `USAGE` grant for the analytics role (copied from the OLD DEV_RAW_DB that's being replaced)
- Schema `USAGE` and table `SELECT` are re-applied because those objects are new (cloned from PROD, which carries PROD's grants)
- `FUTURE TABLE` grants require `MANAGE GRANTS` (even for the owner) and are intentionally skipped — the cloned schema is static and no new tables are added post-clone
- CHANGE_TRACKING is a table property and is cloned from PROD automatically (already set by 04)

### Task: `ADMIN_DB.PUBLIC.DAILY_CLONE_REFRESH`

```sql
CREATE OR REPLACE TASK ADMIN_DB.PUBLIC.DAILY_CLONE_REFRESH
  WAREHOUSE = DEV_ANALYTICS_WH
  AFTER     PROD_RAW_DB.PUBLIC.DAILY_DATA_INSERT
  COMMENT   = 'Re-clones DEV_RAW_DB and TEST_RAW_DB from PROD after daily insert succeeds'
AS
  CALL ADMIN_DB.PUBLIC.REFRESH_DEV_TEST_CLONES();
```

This is a child task in the same graph as `DAILY_DATA_INSERT`. Snowflake runs it automatically when the root task completes successfully.

### Resume order (child before root — Snowflake requirement)

```sql
ALTER TASK ADMIN_DB.PUBLIC.DAILY_CLONE_REFRESH       RESUME;  -- child first
ALTER TASK PROD_RAW_DB.PUBLIC.DAILY_DATA_INSERT       RESUME;  -- root last
```

The existing `ALTER TASK PROD_RAW_DB.PUBLIC.DAILY_DATA_INSERT RESUME` moves to the bottom; the child resume is inserted before it.

Also update the 04 header comment to mention the re-clone procedure and update the "to switch to 2 hours" block note (only the root task's schedule needs changing; child follows automatically).

---

## 3. `99_cleanup.sql` — tear down ADMIN_DB

Tasks in ADMIN_DB must be suspended/dropped before ADMIN_DB is dropped. Add before the databases section:

```sql
ALTER TASK IF EXISTS ADMIN_DB.PUBLIC.DAILY_CLONE_REFRESH SUSPEND;
DROP TASK      IF EXISTS ADMIN_DB.PUBLIC.DAILY_CLONE_REFRESH;
DROP PROCEDURE IF EXISTS ADMIN_DB.PUBLIC.REFRESH_DEV_TEST_CLONES();
```

And add to the database drop block:
```sql
DROP DATABASE IF EXISTS ADMIN_DB;
```

---

## Grant mechanics summary

| What | How it survives the re-clone |
|---|---|
| `USAGE ON DATABASE DEV_RAW_DB` | Preserved by `COPY GRANTS` (copied from old DEV_RAW_DB) |
| `USAGE ON SCHEMA DEV_RAW_DB.ORACLE` | Re-applied in procedure (new schema object carries PROD's grants) |
| `SELECT ON ALL TABLES IN DATABASE DEV_RAW_DB` | Re-applied in procedure (same reason) |
| `SELECT ON FUTURE TABLES IN DATABASE DEV_RAW_DB` | **Not re-applied** — requires MANAGE GRANTS; static schema makes it unnecessary |
| CHANGE_TRACKING on tables | Cloned from PROD automatically (property on the table object) |

---

## Dev/test dbt contract

After this task runs, dev and test dbt pipelines must run with `--full-refresh`. A normal incremental run against a fresh clone would find no new watermark rows and produce no output. `--full-refresh` rebuilds everything cleanly, including recreating the dynamic table with a fresh change tracking reference.
