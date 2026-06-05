CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT cron.schedule(
    'refresh-fraud-dashboard',
    '*/15 * * * *',
    $$REFRESH MATERIALIZED VIEW fraud_monitoring.mv_daily_fraud_summary;$$
);