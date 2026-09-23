-- =====================================================
-- ORDERS & PAYMENTS MODULE - SUPABASE (PostgreSQL)
-- =====================================================

-- =====================================================
-- DROP OLD TABLES IF EXISTS
-- =====================================================
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS orders;

-- =====================================================
-- CREATE ORDERS TABLE
-- =====================================================
CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    project_id BIGINT,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    total_amount DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);

-- =====================================================
-- CREATE PAYMENTS TABLE
-- =====================================================
CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'PENDING',
    transaction_reference VARCHAR(255) UNIQUE,
    paid_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON DELETE CASCADE
);

-- =====================================================
-- INSERT SAMPLE DATA
-- =====================================================
INSERT INTO orders
(user_id, project_id, status, total_amount)
VALUES
(1, 1, 'COMPLETED', 1700.50),
(1, 2, 'PENDING', 500.00);

INSERT INTO payments
(order_id, amount, payment_method, payment_status, transaction_reference)
VALUES
(1, 1700.50, 'UPI', 'SUCCESS', 'TXN1001'),
(2, 500.00, 'CARD', 'PENDING', 'TXN1002');

-- =====================================================
-- VIEW ALL DATA
-- =====================================================
SELECT * FROM orders;
SELECT * FROM payments;

