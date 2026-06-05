SET search_path TO fraud_monitoring;

SELECT * FROM vw_customer_accounts;

SELECT * FROM vw_recent_transactions
ORDER BY transaction_at DESC;

SELECT * FROM vw_flagged_transactions
ORDER BY risk_score DESC;

SELECT * FROM vw_customer_risk_profile
ORDER BY average_risk_score DESC;

SELECT * FROM mv_daily_fraud_summary
ORDER BY transaction_date DESC;

SELECT calculate_customer_daily_volume(1, CURRENT_DATE) AS customer_daily_volume;

SELECT is_high_risk_country('IR') AS is_high_risk;

SELECT mask_card_number('4111111111111111') AS masked_card_number;

SELECT get_customer_age(1) AS customer_age;

SELECT * FROM transaction_status_history
ORDER BY changed_at;

SELECT * FROM audit_log
ORDER BY changed_at;