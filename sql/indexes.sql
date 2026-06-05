SET search_path TO fraud_monitoring;

CREATE INDEX idx_accounts_customer_id ON accounts(customer_id);
CREATE INDEX idx_cards_account_id ON cards(account_id);
CREATE INDEX idx_transactions_account_id ON transactions(account_id);
CREATE INDEX idx_transactions_card_id ON transactions(card_id);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_fraud_alerts_transaction_id ON fraud_alerts(transaction_id);