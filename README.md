# dbt Full Demo — Setup Walkthrough

This repo demonstrates a full dbt + Snowflake pattern: synthetic source data in a raw database, zero-copy clones for dev/test isolation, incremental dbt models, a Snowflake Dynamic Table, and a daily task pipeline that keeps clones fresh.

---

## Prerequisites

- ACCOUNTADMIN (or a role with equivalent privileges) on a Snowflake account
- Access to Snowsight

---

## Step 1 — Bootstrap the account from a SQL Worksheet

Before importing the repo, you need to run a one-time bootstrap that creates the PROD source database and seeds it with synthetic data. This must be done directly in a SQL Worksheet because the objects the remaining scripts depend on don't exist yet.

1. In Snowsight, open **Projects → Worksheets** and create a new SQL Worksheet.
2. Copy the full contents of `01_historical_data_generation.sql` into the worksheet.
3. Run the entire script as **SYSADMIN** (or ACCOUNTADMIN — the script sets the role at the top).
   - The script creates `PROD_RAW_DB.ORACLE` and calls a stored procedure that generates synthetic provider and vendor data.
   - `PRV_XREF` and `PRV_XREF1` are ~3.7 M rows each — allow a few minutes for those inserts to complete.

---

## Step 2 — Import the repo into a Snowflake Git-backed Workspace

1. In Snowsight, open **Projects → Workspaces** and choose **New Workspace → From Git Repository**.
2. Paste the repo URL: `https://github.com/sfc-gh-timjones/dbt_full_demo`
3. Choose the `dev` branch.
4. Snowflake will clone the repo into your workspace. You can now open and run the remaining SQL scripts directly from the workspace file browser.

---

## Step 3 — Run the setup scripts in order

Open each script in a Snowsight SQL Worksheet and run it top to bottom. The scripts must be run in numbered order — each one depends on objects created by the previous.

### `02_clone_prod_raw.sql`

Clones the `ORACLE` schema from `PROD_RAW_DB` into `DEV_RAW_DB` and `TEST_RAW_DB`.

- Creates empty `DEV_RAW_DB` and `TEST_RAW_DB` databases.
- Clones only the `ORACLE` schema from PROD — `PUBLIC` is left untouched so PROD's tasks and procedures are never copied into dev/test.
- Run as **SYSADMIN**.

### `03_analytics_env_setup.sql`

Creates all roles, analytics databases, warehouses, and grants for all three environments (dev, test, prod).

Key objects created:
- Roles: `DEV_ANALYTICS_RL`, `TEST_ANALYTICS_RL`, `PROD_ANALYTICS_RL`
- Databases: `DEV_ANALYTICS_DB`, `TEST_ANALYTICS_DB`, `PROD_ANALYTICS_DB`
- Warehouses: `DEV_ANALYTICS_WH`, `TEST_ANALYTICS_WH`, `PROD_ANALYTICS_WH`

> **Note:** `TEST_ANALYTICS_DB` and `PROD_ANALYTICS_DB` ownership is transferred to their respective roles. Only CI/CD (running as those roles) can write to those databases. Developers interact with `DEV_ANALYTICS_DB` directly.

The script uses multiple roles (`USERADMIN`, `SYSADMIN`, `SECURITYADMIN`, `ACCOUNTADMIN`) — it switches roles automatically. Run from an **ACCOUNTADMIN** session so all role switches succeed.

At the end of this script your current user is granted all three analytics roles.

### `04_incremental_data.sql`

Sets up the daily pipeline: a stored procedure that inserts ~200 new records per day into PROD, and a task graph that re-clones DEV/TEST after each insert.

What it creates:
- `CHANGE_TRACKING` enabled on `PROV` and `VENDOR` in all three raw databases (required for the downstream Dynamic Table).
- `INSERT_INCREMENTAL_DATA()` — inserts ~75 providers, 50 vendors, and 100 vendor-provider links per call.
- `DAILY_DATA_INSERT` task — runs at **8am MT** daily; calls the insert procedure.
- `REFRESH_DEV_TEST_CLONES()` — re-clones `DEV_RAW_DB.ORACLE` and `TEST_RAW_DB.ORACLE` from PROD and re-applies grants.
- `DAILY_CLONE_REFRESH` task — child task that fires automatically after `DAILY_DATA_INSERT` succeeds.

> **Resume order matters.** The script resumes the child task (`DAILY_CLONE_REFRESH`) before the root task (`DAILY_DATA_INSERT`). Do not change this order.

> To trigger the pipeline immediately for testing (without waiting for 8am):
> ```sql
> EXECUTE TASK PROD_RAW_DB.PUBLIC.DAILY_DATA_INSERT;
> ```

Run as **SYSADMIN** (the script sets the role at the top).

---

## Step 4 — Run dbt

The dbt project lives in `dbt_template_example/`. It reads from the raw databases and writes to the analytics databases.

### Configure your connection

Copy `dbt_template_example/profiles.yml` to `~/.dbt/profiles.yml` (or keep it in the project root and pass `--profiles-dir .`). The profile reads all connection details from environment variables — set these before running:

| Variable | Description |
|---|---|
| `DBT_CURRENT_ROLE` | Snowflake role to use |
| `DBT_DATABASE` | Target analytics database |
| `DBT_WAREHOUSE` | Warehouse to run dbt on |
| `DBT_SOURCE_DB` | Raw database to read from |

### Dev environment

```bash
export DBT_CURRENT_ROLE=DEV_ANALYTICS_RL
export DBT_DATABASE=DEV_ANALYTICS_DB
export DBT_WAREHOUSE=DEV_ANALYTICS_WH
export DBT_SOURCE_DB=DEV_RAW_DB

cd dbt_template_example
dbt run --full-refresh
```

Use `--full-refresh` on first run and after every re-clone. This rebuilds the incremental model from scratch and recreates the Dynamic Table's change stream (which breaks when the source schema is replaced).

### Test environment

```bash
export DBT_CURRENT_ROLE=TEST_ANALYTICS_RL
export DBT_DATABASE=TEST_ANALYTICS_DB
export DBT_WAREHOUSE=TEST_ANALYTICS_WH
export DBT_SOURCE_DB=TEST_RAW_DB

dbt run --full-refresh
```

`TEST_ANALYTICS_DB` is owned by `TEST_ANALYTICS_RL` — only that role can write to it. Developers can query the test database but cannot alter it.

### Prod environment

```bash
export DBT_CURRENT_ROLE=PROD_ANALYTICS_RL
export DBT_DATABASE=PROD_ANALYTICS_DB
export DBT_WAREHOUSE=PROD_ANALYTICS_WH
export DBT_SOURCE_DB=PROD_RAW_DB

dbt run
```

Prod uses incremental mode (no `--full-refresh`). The `dim_provider` model picks up any records with a `LAST_MODIFIED_DATE` on or after the current watermark — this means same-day re-runs safely merge without duplicating rows.

> **Warning:** Running `dbt run` without `--full-refresh` in dev/test after a re-clone will not error, but the mart will not be fully rebuilt and `fct_provider_county_summary` (the Dynamic Table) will be broken until `--full-refresh` is run.

---

## Models at a glance

```
staging/     stg_oracle__providers, stg_oracle__vendors, stg_oracle__vendor_provider_ref
             (light cleaning + type casting from raw)

intermediate/ int_provider_addresses, int_provider_taxonomy, int_provider_communication,
              int_provider_xref
             (joins and business logic)

marts/       dim_provider          — incremental model; unique_key = provider_id
             fct_provider_county_summary — Snowflake Dynamic Table; 1-hour target lag
```

---

## CI/CD (Future Phase)

Automating promotion from dev → test → prod via a CI/CD pipeline is the next phase of this pattern. The intended flow is:

- Pull request merged to `main` triggers a pipeline.
- Pipeline authenticates to Snowflake via OIDC (no stored passwords).
- `dbt run --full-refresh` executes against `TEST_ANALYTICS_DB` as `TEST_ANALYTICS_RL`.
- On success, `dbt run` promotes to `PROD_ANALYTICS_DB` as `PROD_ANALYTICS_RL`.

Because `TEST_ANALYTICS_DB` and `PROD_ANALYTICS_DB` are owned by their respective roles (set in `03_analytics_env_setup.sql`), only the CI/CD pipeline — not individual developers — can write to those databases.
