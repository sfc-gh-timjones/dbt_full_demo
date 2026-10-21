# dbt Full Demo

A working demo of a Snowflake + dbt pipeline: synthetic provider data, zero-copy schema clones for dev/test isolation, incremental models, a Snowflake Dynamic Table, and a daily task pipeline that keeps clones in sync with PROD.

---

- [Architecture](ARCHITECTURE.md) — data flow, environments, dbt layers, task pipeline, RBAC
- [Setup Guide](IMPLEMENT.md) — step-by-step instructions to build and run the demo
