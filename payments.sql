-- =====================================================
-- PAYMENTS MODULE - SUPABASE (PostgreSQL)
-- =====================================================

-- NOTE: "USE scalable_app" removed — not needed in Supabase


-- =====================================================
-- DROP OLD TABLE IF EXISTS
-- =====================================================

DROP TABLE IF EXISTS payments;


-- =====================================================
-- CREATE PAYMENTS TABLE
-- =====================================================

CREATE TABLE payments (

    payment_id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL,

    amount DECIMAL(10,2) NOT NULL,

    payment_method VARCHAR(50) NOT NULL,

    transaction_id VARCHAR(255) UNIQUE NOT NULL,

    payment_status VARCHAR(20) DEFAULT 'PENDING',

    paid_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);


-- =====================================================
-- INSERT SAMPLE DATA
-- =====================================================

INSERT INTO payments
(user_id, amount, payment_method, transaction_id, payment_status)
VALUES
(
    1, 500.00, 'UPI', 'TXN1001', 'SUCCESS'
),
(
    1, 1200.50, 'CARD', 'TXN1002', 'PENDING'
);


-- =====================================================
-- VIEW ALL PAYMENTS
-- =====================================================

SELECT * FROM payments;