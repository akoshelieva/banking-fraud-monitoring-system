# Banking Fraud Monitoring System

## Overview

This project implements a PostgreSQL database solution for a banking fraud monitoring system.

The system stores customers, accounts, cards, transactions, fraud rules, fraud alerts, transaction status history, and audit logs. It also includes simple fraud detection logic, stored procedures, triggers, views, and a materialized view for analytical reporting.

The project was created for the **Advanced PostgreSQL Assignment: Banking Fraud Monitoring System**.

---

## Project Structure

```text
banking-fraud-monitoring-system/
│
├── sql/
│   ├── create_database.sql
│   ├── schema_and_domains.sql
│   ├── tables.sql
│   ├── indexes.sql
│   ├── functions.sql
│   ├── procedures.sql
│   ├── triggers.sql
│   ├── views.sql
│   ├── materialized_views.sql
│   ├── data_insertion.sql
│   ├── queries.sql
│   └── pg_cron.sql
│
├── diagrams/
│   └── er_diagram.md
│
├── README.md
├── run_all.sql
└── .gitignore
```

---

## Setup Instructions

### 1. Create the database

Run:

```sql
CREATE DATABASE banking_fraud_monitoring;
```

Or execute the script:

```bash
psql -d postgres -f sql/create_database.sql
```

### 2. Connect to the database

Connect to:

```text
banking_fraud_monitoring
```

### 3. Run scripts in order

Run the SQL files in this exact order:

```text
schema_and_domains.sql
tables.sql
indexes.sql
functions.sql
procedures.sql
triggers.sql
views.sql
materialized_views.sql
data_insertion.sql
queries.sql
```

The file:

```text
pg_cron.sql
```

is optional and should be run only for the bonus task if `pg_cron` is installed.

---

## Database Schema

The project uses a separate PostgreSQL schema:

```sql
fraud_monitoring
```

Most scripts begin with:

```sql
SET search_path TO fraud_monitoring;
```

This makes sure that all project objects are created inside the `fraud_monitoring` schema.

---

## Main Tables

The project implements the required tables:

* `customers`
* `accounts`
* `cards`
* `transactions`
* `transaction_status_history`
* `fraud_rules`
* `fraud_alerts`
* `audit_log`

---

## Data Integrity and Constraints

The project uses:

* primary keys;
* foreign keys;
* unique constraints;
* check constraints;
* PostgreSQL domains.

### Domains

The project defines the following PostgreSQL domains:

* `secure_email_address`
* `currency_code`
* `transaction_status`
* `positive_amount`

These domains help validate commonly reused values.

### Constraint Examples

* customer email must be unique;
* account number must be unique;
* card number hash must be unique;
* transaction amount must be greater than zero;
* account balance cannot be negative;
* currency must be one of `UAH`, `USD`, or `EUR`;
* transaction status must be one of `PENDING`, `APPROVED`, `DECLINED`, or `FLAGGED`;
* risk score must be between `0` and `100`.

---

## Fraud Detection Logic

Each transaction receives a risk score from `0` to `100`.

The implemented fraud logic is simple and rule-based:

| Rule                                                        | Points |
| ----------------------------------------------------------- | -----: |
| Transaction amount is greater than the configured threshold |    +50 |
| Merchant country is high-risk                               |    +40 |
| Card status is `BLOCKED`                                    |    +20 |

The transaction amount threshold is stored in the `fraud_rules` table. In the sample data, the threshold is:

```text
5000
```

High-risk countries are defined in the function:

```sql
is_high_risk_country(country_code)
```

The current high-risk countries are:

```text
IR, KP, SY, CU
```

If the final risk score is greater than or equal to:

```text
70
```

the transaction is automatically marked as:

```text
FLAGGED
```

and a fraud alert is created.

---

## Functions

The project implements reusable PL/pgSQL functions:

* `calculate_customer_daily_volume(customer_id, target_date)`
* `is_high_risk_country(country_code)`
* `calculate_transaction_risk_score(transaction_id)`
* `mask_card_number(card_number)`
* `get_customer_age(customer_id)`

These functions are used for fraud scoring, reporting, and helper operations.

---

## Stored Procedures

The project implements stored procedures for business logic:

* `process_transaction(transaction_id)`
* `create_fraud_alert(transaction_id, rule_id, reason, risk_score)`
* `freeze_account(account_id)`
* `approve_pending_transactions()`
* `refresh_fraud_dashboard()`

These procedures are used to process transactions, create fraud alerts, freeze accounts, approve safe pending transactions, and refresh the materialized view.

---

## Triggers

The project implements trigger logic for automatic database behavior.

### Transaction Risk Evaluation

After a transaction is inserted, the system calculates its risk score.

If the score is high enough, the transaction status becomes `FLAGGED`.

### Fraud Alert Creation

If a transaction is flagged, a fraud alert is created automatically.

### Balance Update

When a transaction status becomes `APPROVED`, the transaction amount is subtracted from the related account balance.

In this simplified version, all approved transactions are treated as outgoing card payments.

### Transaction Status History

Every inserted transaction and every transaction status change is recorded in:

```text
transaction_status_history
```

### Audit Logging

Insert, update, and delete operations are logged for the main business tables:

* `customers`
* `accounts`
* `transactions`

Audit records are stored in:

```text
audit_log
```

### Customer Deletion Protection

A customer cannot be deleted if the customer still has active accounts.

---

## Views

The project implements operational and analytical views:

* `vw_customer_accounts`
* `vw_recent_transactions`
* `vw_flagged_transactions`
* `vw_customer_risk_profile`

These views simplify reporting and make it easier to inspect customer accounts, recent transactions, flagged transactions, and customer risk profiles.

---

## Materialized View

The project implements the required materialized view:

```text
mv_daily_fraud_summary
```

It contains:

* transaction date;
* total transactions;
* total transaction amount;
* number of flagged transactions;
* suspicious transaction amount;
* average risk score;
* top risky customers;
* total fraud alerts.

Manual refresh:

```sql
REFRESH MATERIALIZED VIEW fraud_monitoring.mv_daily_fraud_summary;
```

Refresh using the stored procedure:

```sql
CALL fraud_monitoring.refresh_fraud_dashboard();
```

---

## Bonus: Scheduled Materialized View Refresh

The bonus task is implemented in:

```text
sql/pg_cron.sql
```

The purpose of this file is to automatically refresh the materialized view on a schedule.

The script uses `pg_cron` to run:

```sql
REFRESH MATERIALIZED VIEW fraud_monitoring.mv_daily_fraud_summary;
```

automatically.

This file is optional because `pg_cron` may not be installed on every PostgreSQL server.

---

## Sample Data

The project uses manually created synthetic sample data.

No external datasets are required.

The sample data includes:

* customers;
* accounts;
* cards;
* fraud rules;
* normal transactions;
* suspicious transactions;
* approved transactions;
* flagged transactions;
* fraud alerts;
* status history records;
* audit log records;
* daily fraud summary data.

---

## Demo Queries

Demo queries are located in:

```text
sql/queries.sql
```

They demonstrate:

* customer accounts;
* recent transactions;
* flagged transactions;
* customer risk profiles;
* daily fraud summary;
* helper functions;
* transaction status history;
* audit log records.

Example queries:

```sql
SELECT * FROM fraud_monitoring.vw_customer_accounts;
```

```sql
SELECT * FROM fraud_monitoring.vw_flagged_transactions;
```

```sql
SELECT * FROM fraud_monitoring.mv_daily_fraud_summary;
```

```sql
SELECT fraud_monitoring.mask_card_number('4111111111111111');
```

---

## Assumptions

* Only `UAH`, `USD`, and `EUR` currencies are supported.
* Transaction statuses are limited to `PENDING`, `APPROVED`, `DECLINED`, and `FLAGGED`.
* Risk scoring is simplified for educational purposes.
* All approved transactions decrease account balance.
* Card numbers are not stored directly. Only a card number hash is stored.
* The project uses synthetic data and does not require external datasets.
* The materialized view is refreshed after sample data insertion.

---

## Evaluation Mapping

| Assignment Category          | Implemented In                         |
| ---------------------------- | -------------------------------------- |
| Constraints & Data Integrity | `schema_and_domains.sql`, `tables.sql` |
| Functions                    | `functions.sql`                        |
| Stored Procedures            | `procedures.sql`                       |
| Trigger Logic                | `triggers.sql`                         |
| Views                        | `views.sql`                            |
| Materialized Views           | `materialized_views.sql`               |
| Sample Data                  | `data_insertion.sql`                   |
| Demo Queries                 | `queries.sql`                          |
| Bonus Scheduled Refresh      | `pg_cron.sql`                          |
| Documentation                | `README.md`                            |

---

## Notes

This implementation is intentionally minimal and focused on the assignment requirements. The fraud detection logic is simplified, but it demonstrates how PostgreSQL tables, constraints, functions, procedures, triggers, views, and materialized views can work together in a banking fraud monitoring system.
