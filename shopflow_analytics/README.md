# Shopflow dbt + Snowflake E-Commerce Project [2026]

End-to-end data pipeline for an e-commerce analytics layer: **orders**, **customers**, **products**, and **order line items**. Built with dbt Core on Snowflake so you can run it locally or deploy via CI/CD.

## What you get

**Medallion architecture** (no prefix/postfix on schema names):

- **Bronze** (`bronze` schema): Raw data from seed CSVs (customers, orders, order_items, products) loaded into Snowflake.
- **Silver** (`silver` schema): Staging views for orders, order_items, products (1:1 with raw) + intermediate views. Customers have no staging—only `scd_customers` (snapshot from raw) in gold.
- **Gold** (`gold` schema): Marts — `fct_orders`, `fct_order_items`, `dim_products`; **`scd_customers`** (Type 2 SCD — the only customer table, attributes only, no order-derived fields); and **exposures** (who uses the data).

**Concepts included (beginner-friendly):**
- **Incremental models**: `fct_orders` and `fct_order_items` use `merge` so only new/changed data is processed each run.
- **Slowly changing dimension (Type 2)**: `scd_customers` snapshot tracks customer history; use `dbt_valid_from` / `dbt_valid_to` for point-in-time queries.
- **Exposures**: Link gold models to dashboards and consumers (CEO dashboard, product analytics).
- **Hooks**: `on-run-start` / `on-run-end` in `dbt_project.yml` for run logging.
- **Tests**: Generic (unique, not_null, relationships, accepted_values) plus singular tests (revenue non-negative, no future dates, positive quantities, valid email, positive product price).

Database: **ANALYTICS**. Warehouse: **COMPUTE_WH** (or your preferred warehouse).

## Prerequisites

- **Python 3.12** (recommended; 3.10–3.11 also work; 3.14 is not yet supported by dbt's dependencies)
- A Snowflake account with appropriate role and warehouse access
- Snowflake **account**, **user**, **password** (or key-pair authentication), **role**, **warehouse**, and **database** details

## Quick start

### 1. Clone and install

```bash
git clone <your-repo-url>
cd job-ready-dbt-snowflake-data-engineering-project
python3.12 -m pip install -r requirements.txt
```

### 2. Connect to Snowflake

**Option A — project profile (recommended):** Create `profiles.yml` in the project (or copy from `profiles.yml.example`) and set:

- `account`: Your Snowflake account identifier (e.g., `xy12345.us-east-1`)
- `user`: Your Snowflake username
- `password`: Your Snowflake password (or use key-pair authentication)
- `role`: Your Snowflake role (e.g., `ANALYTICS_ROLE`)
- `warehouse`: Your Snowflake warehouse (e.g., `COMPUTE_WH`)
- `database`: Target database (e.g., `ANALYTICS`)

Then run with:

```bash
export SNOWFLAKE_ACCOUNT="xy12345.us-east-1"
export SNOWFLAKE_USER="your_username"
export SNOWFLAKE_PASSWORD="your_password"
export SNOWFLAKE_ROLE="ANALYTICS_ROLE"
export SNOWFLAKE_WAREHOUSE="COMPUTE_WH"
export SNOWFLAKE_DATABASE="ANALYTICS"
DBT_PROFILES_DIR=. dbt seed && dbt run && dbt test
```

**Option B — user profile:** Copy `profiles.yml.example` to `~/.dbt/profiles.yml` and fill in connection details. Database is `ANALYTICS`; schema names are `bronze`, `silver`, `gold` (no prefix/postfix).

**Option C — Key-pair authentication (recommended for production):**

```yaml
snowflake_shopflow:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
      user: "{{ env_var('SNOWFLAKE_USER') }}"
      private_key_path: /path/to/rsa_key.p8
      role: "{{ env_var('SNOWFLAKE_ROLE') }}"
      warehouse: "{{ env_var('SNOWFLAKE_WAREHOUSE') }}"
      database: "{{ env_var('SNOWFLAKE_DATABASE') }}"
      schema: bronze
      threads: 4
```

### 3. Install packages, load seeds, run models and snapshots

```bash
dbt deps
dbt seed
dbt snapshot   # scd_customers from raw (must run before run, as models depend on it)
dbt run
dbt test
```

### 4. Build and test (full run)

```bash
# If using project profile (profiles.yml in repo with env vars):
export SNOWFLAKE_ACCOUNT="xy12345.us-east-1"
export SNOWFLAKE_USER="your_username"
export SNOWFLAKE_PASSWORD="your_password"
export SNOWFLAKE_ROLE="ANALYTICS_ROLE"
export SNOWFLAKE_WAREHOUSE="COMPUTE_WH"
export SNOWFLAKE_DATABASE="ANALYTICS"
DBT_PROFILES_DIR=. dbt seed
DBT_PROFILES_DIR=. dbt run
DBT_PROFILES_DIR=. dbt snapshot
DBT_PROFILES_DIR=. dbt test
```

Or use the helper script (uses Python 3.12, runs seed + run + test):

```bash
export SNOWFLAKE_ACCOUNT="xy12345.us-east-1"
export SNOWFLAKE_USER="your_username"
export SNOWFLAKE_PASSWORD="your_password"
export SNOWFLAKE_ROLE="ANALYTICS_ROLE"
export SNOWFLAKE_WAREHOUSE="COMPUTE_WH"
export SNOWFLAKE_DATABASE="ANALYTICS"
./run.sh
```

### 5. Docs (optional)

```bash
dbt docs generate
dbt docs serve
```

## Project layout (medallion)

```
seeds/              # raw_*.csv → bronze schema
models/
  staging/          # silver: stg_* (views)
  intermediate/     # silver: int_* (views)
  marts/core/       # gold: fct_orders, fct_order_items (incremental), dim_products, exposures
snapshots/          # gold: scd_customers (Type 2 SCD — only customer table, attributes only)
tests/              # singular tests (assert_*.sql) + schema tests in yml
macros/             # generate_schema_name (schema as-is, no prefix/postfix)
```

## CI/CD (GitHub Actions)

### dbt CI workflow

The project includes GitHub Actions workflows for automated testing and deployment:

**Required GitHub secrets:**

| Secret                | Description                           |
|-----------------------|---------------------------------------|
| `SNOWFLAKE_ACCOUNT`   | Snowflake account identifier          |
| `SNOWFLAKE_USER`      | Snowflake username                    |
| `SNOWFLAKE_PASSWORD`  | Snowflake password                    |
| `SNOWFLAKE_ROLE`      | Snowflake role                        |
| `SNOWFLAKE_WAREHOUSE` | Snowflake warehouse                   |
| `SNOWFLAKE_DATABASE`  | Snowflake database                    |
| `DBT_SCHEMA`          | Schema for CI runs (optional)         |

Configure in **Settings → Secrets and variables → Actions**.

### Deploy environments (dev and prod)

Two workflows deploy by branch:

| Branch   | Workflow                              | Target | GitHub environment |
|----------|---------------------------------------|--------|---------------------|
| **dev**  | `.github/workflows/dbt-dev.yml`       | `dev`  | `dev`               |
| **main** | `.github/workflows/dbt-prod.yml`      | `prod` | `prod`              |

- **Push to `dev`** → runs `dbt seed`, `dbt snapshot`, `dbt run`, `dbt test` against dev environment
- **Push to `main`** → runs full pipeline against prod environment

**Local deploy:**

```bash
export SNOWFLAKE_ACCOUNT="xy12345.us-east-1"
export SNOWFLAKE_USER="your_username"
export SNOWFLAKE_PASSWORD="your_password"
export SNOWFLAKE_ROLE="ANALYTICS_ROLE"
export SNOWFLAKE_WAREHOUSE="COMPUTE_WH"
export SNOWFLAKE_DATABASE="ANALYTICS"
dbt run --target prod
```

## Snowflake-specific features

### Virtual warehouses
The project is configured to use Snowflake's warehouse system for compute:
- **Development**: `COMPUTE_WH` (X-Small recommended)
- **Production**: `ANALYTICS_WH` (Small or Medium for larger datasets)

### Zero-copy cloning (optional)
For testing or dev environments, you can leverage Snowflake's zero-copy cloning:

```sql
-- Create a dev database clone
CREATE DATABASE ANALYTICS_DEV CLONE ANALYTICS;
```

### Query tags
The project uses dbt's query tags feature to track dbt-generated queries in Snowflake's query history:

```yaml
# In dbt_project.yml
query-comment:
  comment: "dbt run by {{ target.user }} in {{ target.name }}"
  append: true
```

### Snowflake-specific macros
- Custom schema generation (no prefix/postfix)
- Snowflake-optimized incremental strategies (merge)
- Clustering keys for large fact tables (optional, add in model configs)

## Interview talking points

When asked *"Walk me through a data project you've built"* or *"What's in your dbt project?"*, you can say:

- **Architecture:** "I built a medallion pipeline on Snowflake: bronze for raw data, silver for staging and intermediate models, gold for fact and dimension tables. Schema names are clean—no prefix or postfix."
- **Facts & dimensions:** "Gold has two fact tables—`fct_orders` (order grain) and `fct_order_items` (line grain)—and one dimension, `dim_products`. Customers are in `scd_customers` only (Type 2 SCD, attributes only, no order aggregates)."
- **Scale & history:** "The fact tables are incremental with merge so we only process new data. Customer changes are tracked in `scd_customers` for point-in-time reporting."
- **Quality & impact:** "I added generic tests (unique, not_null, relationships, accepted_values) and singular tests for business rules. Exposures link gold models to dashboards so we can see downstream impact."
- **Deployment:** "The pipeline runs in CI on every push via GitHub Actions against Snowflake, and can be scheduled with dbt Cloud or orchestration tools like Airflow for production."
- **Snowflake optimization:** "I leveraged Snowflake's virtual warehouses for compute isolation, and the project is ready for clustering keys on large fact tables when needed."

See **[docs/GOLD_LAYER_QUESTIONS.md](docs/GOLD_LAYER_QUESTIONS.md)** for the dimensional model and 30+ business questions answerable from the gold layer.

**Production tip:** When raw data comes from external stages (S3, Azure Blob, GCS) instead of seeds, define **sources** in YAML and set **source freshness** so dbt can alert when data stops landing.

## Snowflake setup (first-time)

If you're setting up a new Snowflake account, run these commands to create the necessary objects:

```sql
-- Create database and schemas
CREATE DATABASE IF NOT EXISTS ANALYTICS_DB;
USE DATABASE ANALYTICS_DB;
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

-- Create warehouse
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH
  WITH WAREHOUSE_SIZE = 'X-SMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

-- Create role and grant permissions
CREATE ROLE IF NOT EXISTS ANALYTICS_ROLE;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ANALYTICS_ROLE;
GRANT ALL ON DATABASE ANALYTICS TO ROLE ANALYTICS_ROLE;
GRANT ALL ON ALL SCHEMAS IN DATABASE ANALYTICS TO ROLE ANALYTICS_ROLE;
GRANT ALL ON FUTURE SCHEMAS IN DATABASE ANALYTICS TO ROLE ANALYTICS_ROLE;
GRANT ALL ON ALL TABLES IN DATABASE ANALYTICS TO ROLE ANALYTICS_ROLE;
GRANT ALL ON FUTURE TABLES IN DATABASE ANALYTICS TO ROLE ANALYTICS_ROLE;

-- Grant role to user
GRANT ROLE ANALYTICS_ROLE TO USER <your_username>;
```

## Orchestration options

### dbt Cloud (recommended)
- Native Snowflake integration
- Built-in scheduler and job monitoring
- IDE for development
- Easy CI/CD setup

### Apache Airflow
```python
from airflow.providers.dbt.cloud.operators.dbt import DbtCloudRunJobOperator
# or
from airflow.operators.bash import BashOperator

dbt_run = BashOperator(
    task_id='dbt_run',
    bash_command='cd /path/to/project && dbt run --profiles-dir .',
    env={
        'SNOWFLAKE_ACCOUNT': '{{ var.value.snowflake_account }}',
        'SNOWFLAKE_USER': '{{ var.value.snowflake_user }}',
        'SNOWFLAKE_PASSWORD': '{{ var.value.snowflake_password }}',
    }
)
```

### Prefect / Dagster
Both support dbt Core integration with native operators.

## Cost optimization tips

1. **Warehouse auto-suspend**: Set to 60 seconds for dev, 5 minutes for prod
2. **Warehouse sizing**: Start with X-Small, scale up only if needed
3. **Incremental models**: Use for large fact tables to reduce compute
4. **Query result caching**: Snowflake automatically caches results for 24 hours
5. **Clustering keys**: Add to very large tables (millions+ rows) for query performance

## Troubleshooting

### Connection issues
```bash
# Test Snowflake connection
dbt debug

# Common issues:
# - Account identifier format: use "xy12345.us-east-1" not "xy12345.snowflakecomputing.com"
# - Role permissions: ensure role has access to database, schemas, and warehouse
# - Warehouse state: verify warehouse is not suspended
```

### Performance optimization
```sql
-- Check query performance in Snowflake
SELECT *
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
WHERE QUERY_TEXT ILIKE '%dbt%'
ORDER BY START_TIME DESC
LIMIT 10;
```

## License

See [LICENSE](LICENSE).
