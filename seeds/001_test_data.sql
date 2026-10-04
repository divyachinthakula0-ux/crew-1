-- 1. Test users
INSERT INTO users
    (id, name, email, password_hash)
VALUES
    ('11111111-1111-4111-8111-111111111111',
     'Test User One',
     'user1@example.com',
     'TEST_ONLY_NOT_A_REAL_HASH'),

    ('22222222-2222-4222-8222-222222222222',
     'Test User Two',
     'user2@example.com',
     'TEST_ONLY_NOT_A_REAL_HASH');

-- 2. Test project
INSERT INTO projects
    (id, user_id, title, description, status)
VALUES
    ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
     '11111111-1111-4111-8111-111111111111',
     'Sample Project',
     'Dummy project for database testing',
     'open');

-- 3. Test order
INSERT INTO orders
    (user_id, project_id, order_date, status, total_amount)
VALUES
    ('11111111-1111-4111-8111-111111111111',
     'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
     CURRENT_TIMESTAMP,
     'pending',
     1499.00);

-- 4. Test payment
INSERT INTO payments
    (order_id, amount, payment_method,
     payment_status, transaction_reference)
SELECT
    id, 1499.00, 'test', 'pending', 'TEST-TXN-001'
FROM orders
WHERE user_id = '11111111-1111-4111-8111-111111111111'
ORDER BY id DESC
LIMIT 1;
