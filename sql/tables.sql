SET search_path TO fraud_monitoring;

CREATE TABLE customers (
    customer_id BIGSERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email secure_email_address NOT NULL UNIQUE,
    birth_date DATE NOT NULL CHECK (birth_date <= CURRENT_DATE),
    country_code CHAR(2) NOT NULL CHECK (country_code ~ '^[A-Z]{2}$'),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE accounts (
    account_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(customer_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    account_number VARCHAR(34) NOT NULL UNIQUE,
    currency currency_code NOT NULL,
    balance NUMERIC(14, 2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'FROZEN', 'CLOSED')),
    opened_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cards (
    card_id BIGSERIAL PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES accounts(account_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    card_number_hash VARCHAR(255) NOT NULL UNIQUE,
    card_type VARCHAR(20) NOT NULL
        CHECK (card_type IN ('DEBIT', 'CREDIT')),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'BLOCKED', 'EXPIRED')),
    expiration_date DATE NOT NULL
);

CREATE TABLE fraud_rules (
    rule_id BIGSERIAL PRIMARY KEY,
    rule_name VARCHAR(100) NOT NULL UNIQUE,
    rule_type VARCHAR(50) NOT NULL,
    threshold_value INTEGER NOT NULL CHECK (threshold_value >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES accounts(account_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    card_id BIGINT REFERENCES cards(card_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    amount positive_amount NOT NULL,
    currency currency_code NOT NULL,
    merchant_category VARCHAR(100) NOT NULL,
    merchant_country CHAR(2) NOT NULL CHECK (merchant_country ~ '^[A-Z]{2}$'),
    status transaction_status NOT NULL DEFAULT 'PENDING',
    risk_score INTEGER NOT NULL DEFAULT 0 CHECK (risk_score BETWEEN 0 AND 100),
    transaction_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE transaction_status_history (
    history_id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT NOT NULL REFERENCES transactions(transaction_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    old_status transaction_status,
    new_status transaction_status NOT NULL,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by TEXT NOT NULL DEFAULT CURRENT_USER
);

CREATE TABLE fraud_alerts (
    alert_id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT NOT NULL REFERENCES transactions(transaction_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    rule_id BIGINT REFERENCES fraud_rules(rule_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    reason TEXT NOT NULL,
    risk_score INTEGER NOT NULL CHECK (risk_score BETWEEN 0 AND 100),
    alert_status VARCHAR(20) NOT NULL DEFAULT 'OPEN'
        CHECK (alert_status IN ('OPEN', 'INVESTIGATING', 'RESOLVED', 'FALSE_POSITIVE')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (transaction_id, reason)
);

CREATE TABLE audit_log (
    audit_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT REFERENCES customers(customer_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    table_name TEXT NOT NULL,
    operation TEXT NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    old_value JSONB,
    new_value JSONB,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);