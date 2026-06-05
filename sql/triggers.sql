SET search_path TO fraud_monitoring;

CREATE OR REPLACE FUNCTION trg_status_history()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO transaction_status_history(transaction_id, old_status, new_status)
        VALUES (NEW.transaction_id, NULL, NEW.status);
    ELSIF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO transaction_status_history(transaction_id, old_status, new_status)
        VALUES (NEW.transaction_id, OLD.status, NEW.status);
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_transaction_status_history
AFTER INSERT OR UPDATE OF status ON transactions
FOR EACH ROW
EXECUTE FUNCTION trg_status_history();

CREATE OR REPLACE FUNCTION trg_evaluate_risk()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_score INTEGER;
    v_rule_id BIGINT;
BEGIN
    v_score := calculate_transaction_risk_score(NEW.transaction_id);

    UPDATE transactions
    SET risk_score = v_score,
        status = CASE WHEN v_score >= 70 THEN 'FLAGGED' ELSE status END
    WHERE transaction_id = NEW.transaction_id;

    IF v_score >= 70 THEN
        SELECT rule_id
        INTO v_rule_id
        FROM fraud_rules
        WHERE is_active = TRUE
        ORDER BY rule_id
        LIMIT 1;

        CALL create_fraud_alert(
            NEW.transaction_id,
            v_rule_id,
            'Suspicious transaction detected',
            v_score
        );
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_transaction_risk
AFTER INSERT ON transactions
FOR EACH ROW
EXECUTE FUNCTION trg_evaluate_risk();

CREATE OR REPLACE FUNCTION trg_update_balance()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE accounts
    SET balance = balance - NEW.amount
    WHERE account_id = NEW.account_id
      AND balance >= NEW.amount;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Insufficient balance';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_balance_update
AFTER UPDATE OF status ON transactions
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'APPROVED')
EXECUTE FUNCTION trg_update_balance();

CREATE OR REPLACE FUNCTION trg_prevent_customer_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM accounts
        WHERE customer_id = OLD.customer_id
          AND status = 'ACTIVE'
    ) THEN
        RAISE EXCEPTION 'Cannot delete customer with active accounts';
    END IF;

    RETURN OLD;
END;
$$;

CREATE TRIGGER trg_no_delete_customer_with_accounts
BEFORE DELETE ON customers
FOR EACH ROW
EXECUTE FUNCTION trg_prevent_customer_delete();

CREATE OR REPLACE FUNCTION trg_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_customer_id BIGINT;
BEGIN
    IF TG_TABLE_NAME = 'customers' THEN
        IF TG_OP = 'DELETE' THEN
            v_customer_id := NULL;
        ELSE
            v_customer_id := NEW.customer_id;
        END IF;
    ELSIF TG_TABLE_NAME = 'accounts' THEN
        v_customer_id := COALESCE(NEW.customer_id, OLD.customer_id);
    ELSIF TG_TABLE_NAME = 'transactions' THEN
        SELECT a.customer_id
        INTO v_customer_id
        FROM accounts a
        WHERE a.account_id = COALESCE(NEW.account_id, OLD.account_id);
    END IF;

    INSERT INTO audit_log(table_name, customer_id, operation, old_value, new_value)
    VALUES (
        TG_TABLE_NAME,
        v_customer_id,
        TG_OP,
        CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) ELSE NULL END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) ELSE NULL END
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_audit_customers
AFTER INSERT OR UPDATE OR DELETE ON customers
FOR EACH ROW
EXECUTE FUNCTION trg_audit();

CREATE TRIGGER trg_audit_accounts
AFTER INSERT OR UPDATE OR DELETE ON accounts
FOR EACH ROW
EXECUTE FUNCTION trg_audit();

CREATE TRIGGER trg_audit_transactions
AFTER INSERT OR UPDATE OR DELETE ON transactions
FOR EACH ROW
EXECUTE FUNCTION trg_audit();