# dbt_template_example

Provider data transformation project built on Snowflake. Transforms raw provider and vendor data through staging, intermediate, and marts layers following [dbt best practices](https://docs.getdbt.com/best-practices/how-we-structure/1-guide-overview).

## Environments

| Environment | Source DB | Analytics DB | Warehouse | Role |
|---|---|---|---|---|
| dev | DEV_RAW_DB | DEV_ANALYTICS_DB | DEV_ANALYTICS_WH | DEV_ANALYTICS_RL |
| test | TEST_RAW_DB | TEST_ANALYTICS_DB | TEST_ANALYTICS_WH | TEST_ANALYTICS_RL |
| prod | PROD_RAW_DB | PROD_ANALYTICS_DB | PROD_ANALYTICS_WH | PROD_ANALYTICS_RL |

Source data lives in the `ORACLE` schema of the respective raw database.

## Project Structure

```
models/
  staging/
    oracle/         # Views — 1:1 with ORACLE source tables, named stg_oracle__<entity>
  intermediate/     # Views — joining/enriching staging models
  marts/
    provider/       # Tables — provider dims and facts
    vendor/         # Tables — vendor facts
```

### Staging (11 models — `staging/oracle/`)
Light transformations directly on `ORACLE` source tables. Named `stg_oracle__<entity>`.

| Model | Source Table |
|---|---|
| stg_providers | PROV |
| stg_provider_addresses | PROV_ADDR |
| stg_provider_associates | PROV_ASSOCIATE |
| stg_provider_communications | PROV_COMMUNICATION |
| stg_provider_languages | PROV_LANGUAGE |
| stg_provider_taxonomies | PROV_TAXONOMY |
| stg_provider_xrefs | PRV_XREF1 |
| stg_vendors | VENDOR |
| stg_vendor_addresses | VENDOR_ADDRESS |
| stg_vendor_provider_refs | VENDOR_PROVIDER_REF |
| stg_vendor_taxonomies | VENDOR_TAXONOMY |

### Intermediate (4 models)
Join and enrich staging models into reusable building blocks. Named `int_<concept>`.

| Model | Description |
|---|---|
| int_providers_enriched | Provider + primary address + primary taxonomy |
| int_provider_associations_resolved | Active provider associations with both sides resolved |
| int_providers_contact_pivoted | Provider phone, email, fax, and languages spoken |
| int_vendor_providers_joined | Vendor × provider relationships enriched |

### Marts (4 models)
Final business-facing models materialized as tables, split into domain schemas (`provider`, `vendor`).

| Model | Schema | Type | Description |
|---|---|---|---|
| dim_provider | `provider` | Dimension | Full provider directory with NPI, address, taxonomy |
| fct_provider_network_summary | `provider` | Fact | Association counts per provider by type |
| fct_credentialing_overview | `provider` | Fact | Credentialing breakdown by county, area, and type |
| fct_vendor_roster | `vendor` | Fact | Vendors with contract status and provider counts |

## Setup

Run the setup scripts in order before executing dbt:

```
01_data_generation.sql   # Creates PROD_RAW_DB and loads synthetic source data
02_clone_prod_raw.sql    # Creates DEV_RAW_DB and TEST_RAW_DB as zero-copy clones
03_remaining_setup.sql   # Creates analytics DBs, warehouses, and roles
```

## Running dbt

```bash
dbt deps
dbt run --target dev
dbt test --target dev
```
