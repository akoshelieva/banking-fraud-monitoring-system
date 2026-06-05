SET search_path TO fraud_monitoring;

CREATE OR REPLACE VIEW vw_customer_accounts AS
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    a.account_id,
    a.account_number,
    a.currency,
    a.balance,
    a.status
FROM customers c
JOIN accounts a ON a.customer_id = c.customer_id;

CREATE OR REPLACE VIEW vw_recent_transactions AS
SELECT
    t.transaction_id,
    c.first_name,
    c.last_name,
    a.account_number,
    t.amount,
    t.currency,
    t.merchant_category,
    t.merchant_country,
    t.status,
    t.risk_score,
    t.transaction_at
FROM transactions t
JOIN accounts a ON a.account_id = t.account_id
JOIN customers c ON c.customer_id = a.customer_id
WHERE t.transaction_at >= CURRENT_TIMESTAMP - INTERVAL '30 days';

CREATE OR REPLACE VIEW vw_flagged_transactions AS
SELECT
    t.transaction_id,
    c.first_name,
    c.last_name,
    t.amount,
    t.currency,
    t.merchant_country,
    t.risk_score,
    fa.reason,
    fa.alert_status
FROM transactions t
JOIN accounts a ON a.account_id = t.account_id
JOIN customers c ON c.customer_id = a.customer_id
LEFT JOIN fraud_alerts fa ON fa.transaction_id = t.transaction_id
WHERE t.status = 'FLAGGED';

CREATE OR REPLACE VIEW vw_customer_risk_profile AS
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(t.transaction_id) AS total_transactions,
    COUNT(t.transaction_id) FILTER (WHERE t.status = 'FLAGGED') AS flagged_transactions,
    COALESCE(ROUND(AVG(t.risk_score), 2), 0) AS average_risk_score
FROM customers c
LEFT JOIN accounts a ON a.customer_id = c.customer_id
LEFT JOIN transactions t ON t.account_id = a.account_id
GROUP BY c.customer_id, c.first_name, c.last_name;