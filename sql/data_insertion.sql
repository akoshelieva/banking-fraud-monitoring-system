SET search_path TO fraud_monitoring;

INSERT INTO fraud_rules(rule_name, rule_type, threshold_value)
VALUES
('Large transaction amount', 'AMOUNT', 5000),
('High risk country', 'COUNTRY', 0),
('Blocked card usage', 'CARD', 0);

INSERT INTO customers(first_name, last_name, email, birth_date, country_code)
VALUES
('Ivan', 'Petrenko', 'ivan.petrenko@example.com', '1995-04-12', 'UA'),
('Olena', 'Shevchenko', 'olena.shevchenko@example.com', '1988-09-25', 'UA'),
('John', 'Smith', 'john.smith@example.com', '1979-01-08', 'US'),
('Maria', 'Rossi', 'maria.rossi@example.com', '1990-11-03', 'IT'),
('Petro', 'Bondarenko', 'petro.bondarenko@example.com', '2001-06-18', 'UA');

INSERT INTO accounts(customer_id, account_number, currency, balance, status)
VALUES
(1, 'UA111111111111111111111111111', 'UAH', 12000.00, 'ACTIVE'),
(2, 'UA222222222222222222222222222', 'UAH', 8000.00, 'ACTIVE'),
(3, 'US333333333333333333333333333', 'USD', 3000.00, 'ACTIVE'),
(4, 'EU444444444444444444444444444', 'EUR', 7000.00, 'ACTIVE'),
(5, 'UA555555555555555555555555555', 'UAH', 500.00, 'ACTIVE');

INSERT INTO cards(account_id, card_number_hash, card_type, status, expiration_date)
VALUES
(1, 'hash-card-1111', 'DEBIT', 'ACTIVE', '2028-12-31'),
(2, 'hash-card-2222', 'DEBIT', 'ACTIVE', '2028-12-31'),
(3, 'hash-card-3333', 'DEBIT', 'ACTIVE', '2028-12-31'),
(4, 'hash-card-4444', 'DEBIT', 'BLOCKED', '2028-12-31'),
(5, 'hash-card-5555', 'DEBIT', 'ACTIVE', '2028-12-31');

INSERT INTO transactions(account_id, card_id, amount, currency, merchant_category, merchant_country)
VALUES
(1, 1, 120.00, 'UAH', 'Grocery', 'UA'),
(1, 1, 8500.00, 'UAH', 'Electronics', 'IR'),
(2, 2, 500.00, 'UAH', 'Restaurant', 'UA'),
(3, 3, 1000.00, 'USD', 'Hotel', 'DE'),
(4, 4, 200.00, 'EUR', 'Online shop', 'IT'),
(5, 5, 1000.00, 'UAH', 'Car rental', 'UA');

CALL approve_pending_transactions();

CALL refresh_fraud_dashboard();