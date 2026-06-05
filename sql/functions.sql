SET search_path TO fraud_monitoring;

CREATE OR REPLACE FUNCTION calculate_customer_daily_volume(
    p_customer_id BIGINT,
    p_target_date DATE
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(t.amount), 0)
    INTO v_total
    FROM transactions t
    JOIN accounts a ON a.account_id = t.account_id
    WHERE a.customer_id = p_customer_id
      AND DATE(t.transaction_at) = p_target_date;

    RETURN v_total;
END;
$$;

CREATE OR REPLACE FUNCTION is_high_risk_country(p_country_code CHAR(2))
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN p_country_code IN ('IR', 'KP', 'SY', 'CU');
END;
$$;

CREATE OR REPLACE FUNCTION calculate_transaction_risk_score(p_transaction_id BIGINT)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_amount NUMERIC;
    v_country CHAR(2);
    v_card_status VARCHAR(20);
    v_threshold INTEGER;
    v_score INTEGER := 0;
BEGIN
    SELECT t.amount, t.merchant_country, c.status
    INTO v_amount, v_country, v_card_status
    FROM transactions t
    LEFT JOIN cards c ON c.card_id = t.card_id
    WHERE t.transaction_id = p_transaction_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Transaction % not found', p_transaction_id;
    END IF;

    SELECT COALESCE(MAX(threshold_value), 5000)
    INTO v_threshold
    FROM fraud_rules
    WHERE rule_type = 'AMOUNT'
      AND is_active = TRUE;

    IF v_amount > v_threshold THEN
        v_score := v_score + 50;
    END IF;

    IF is_high_risk_country(v_country) THEN
        v_score := v_score + 40;
    END IF;

    IF v_card_status = 'BLOCKED' THEN
        v_score := v_score + 20;
    END IF;

    RETURN LEAST(v_score, 100);
END;
$$;

CREATE OR REPLACE FUNCTION mask_card_number(p_card_number TEXT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN '**** **** **** ' || RIGHT(p_card_number, 4);
END;
$$;

CREATE OR REPLACE FUNCTION get_customer_age(p_customer_id BIGINT)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_age INTEGER;
BEGIN
    SELECT EXTRACT(YEAR FROM AGE(birth_date))::INTEGER
    INTO v_age
    FROM customers
    WHERE customer_id = p_customer_id;

    RETURN v_age;
END;
$$;