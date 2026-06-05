# ER Diagram

```mermaid
erDiagram
    CUSTOMERS ||--o{ ACCOUNTS : owns
    ACCOUNTS ||--o{ CARDS : has
    ACCOUNTS ||--o{ TRANSACTIONS : contains
    CARDS ||--o{ TRANSACTIONS : used_for
    TRANSACTIONS ||--o{ TRANSACTION_STATUS_HISTORY : tracks
    TRANSACTIONS ||--o{ FRAUD_ALERTS : generates
    FRAUD_RULES ||--o{ FRAUD_ALERTS : applies_to
    CUSTOMERS ||--o{ AUDIT_LOG : related_to

    CUSTOMERS {
        bigserial customer_id PK
        varchar first_name
        varchar last_name
        secure_email_address email UK
        date birth_date
        char country_code
        timestamp created_at
        boolean is_active
    }

    ACCOUNTS {
        bigserial account_id PK
        bigint customer_id FK
        varchar account_number UK
        currency_code currency
        numeric balance
        varchar status
        timestamp opened_at
    }

    CARDS {
        bigserial card_id PK
        bigint account_id FK
        varchar card_number_hash UK
        varchar card_type
        varchar status
        date expiration_date
    }

    FRAUD_RULES {
        bigserial rule_id PK
        varchar rule_name UK
        varchar rule_type
        integer threshold_value
        boolean is_active
    }

    TRANSACTIONS {
        bigserial transaction_id PK
        bigint account_id FK
        bigint card_id FK
        positive_amount amount
        currency_code currency
        varchar merchant_category
        char merchant_country
        transaction_status status
        integer risk_score
        timestamp transaction_at
        timestamp created_at
    }

    TRANSACTION_STATUS_HISTORY {
        bigserial history_id PK
        bigint transaction_id FK
        transaction_status old_status
        transaction_status new_status
        timestamp changed_at
        text changed_by
    }

    FRAUD_ALERTS {
        bigserial alert_id PK
        bigint transaction_id FK
        bigint rule_id FK
        text reason
        integer risk_score
        varchar alert_status
        timestamp created_at
    }

    AUDIT_LOG {
        bigserial audit_id PK
        bigint customer_id FK
        text table_name
        text operation
        jsonb old_value
        jsonb new_value
        timestamp changed_at
    }