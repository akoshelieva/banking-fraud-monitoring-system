SET search_path TO fraud_monitoring;

CREATE OR REPLACE PROCEDURE create_fraud_alert(
    p_transaction_id BIGINT,
    p_rule_id BIGINT,
    p_reason TEXT,
    p_risk_score INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO fraud_alerts (transaction_id, rule_id, reason, risk_score)
    VALUES (p_transaction_id, p_rule_id, p_reason, p_risk_score)
    ON CONFLICT (transaction_id, reason) DO NOTHING;
END;
$$;

CREATE OR REPLACE PROCEDURE process_transaction(p_transaction_id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_score INTEGER;
    v_account_id BIGINT;
    v_amount NUMERIC;
    v_balance NUMERIC;
BEGIN
    SELECT account_id, amount
    INTO v_account_id, v_amount
    FROM transactions
    WHERE transaction_id = p_transaction_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Transaction % not found', p_transaction_id;
    END IF;

    v_score := calculate_transaction_risk_score(p_transaction_id);

    UPDATE transactions
    SET risk_score = v_score
    WHERE transaction_id = p_transaction_id;

    IF v_score >= 70 THEN
        UPDATE transactions
        SET status = 'FLAGGED'
        WHERE transaction_id = p_transaction_id;
    ELSE
        SELECT balance INTO v_balance
        FROM accounts
        WHERE account_id = v_account_id;

        IF v_balance >= v_amount THEN
            UPDATE transactions
            SET status = 'APPROVED'
            WHERE transaction_id = p_transaction_id;
        ELSE
            UPDATE transactions
            SET status = 'DECLINED'
            WHERE transaction_id = p_transaction_id;
        END IF;
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE freeze_account(p_account_id BIGINT)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE accounts
    SET status = 'FROZEN'
    WHERE account_id = p_account_id;
END;
$$;

CREATE OR REPLACE PROCEDURE approve_pending_transactions()
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE transactions t
    SET status = 'APPROVED'
    WHERE t.status = 'PENDING'
      AND t.risk_score < 70
      AND EXISTS (
          SELECT 1
          FROM accounts a
          WHERE a.account_id = t.account_id
            AND a.balance >= t.amount
      );
END;
$$;

CREATE OR REPLACE PROCEDURE refresh_fraud_dashboard()
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW mv_daily_fraud_summary;
END;
$$;