SET search_path TO fraud_monitoring;

CREATE MATERIALIZED VIEW mv_daily_fraud_summary AS
SELECT
    DATE(t.transaction_at) AS transaction_date,
    COUNT(t.transaction_id) AS total_transactions,
    COALESCE(SUM(t.amount), 0) AS total_transaction_amount,
    COUNT(t.transaction_id) FILTER (WHERE t.status = 'FLAGGED') AS flagged_transactions,
    COALESCE(SUM(t.amount) FILTER (WHERE t.status = 'FLAGGED'), 0) AS suspicious_transaction_amount,
    COALESCE(ROUND(AVG(t.risk_score), 2), 0) AS average_risk_score,
    COALESCE(
        STRING_AGG(DISTINCT c.first_name || ' ' || c.last_name, ', ')
            FILTER (WHERE t.status = 'FLAGGED'),
        ''
    ) AS top_risky_customers,
    COUNT(fa.alert_id) AS total_fraud_alerts
FROM transactions t
JOIN accounts a ON a.account_id = t.account_id
JOIN customers c ON c.customer_id = a.customer_id
LEFT JOIN fraud_alerts fa ON fa.transaction_id = t.transaction_id
GROUP BY DATE(t.transaction_at);