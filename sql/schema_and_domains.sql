DROP SCHEMA IF EXISTS fraud_monitoring CASCADE;
CREATE SCHEMA fraud_monitoring;

SET search_path TO fraud_monitoring;

CREATE DOMAIN secure_email_address AS VARCHAR(255)
    CHECK (VALUE ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$');

CREATE DOMAIN currency_code AS CHAR(3)
    CHECK (VALUE IN ('UAH', 'USD', 'EUR'));

CREATE DOMAIN transaction_status AS VARCHAR(20)
    CHECK (VALUE IN ('PENDING', 'APPROVED', 'DECLINED', 'FLAGGED'));

CREATE DOMAIN positive_amount AS NUMERIC(14, 2)
    CHECK (VALUE > 0);