-- =====================================================
-- PLANS MODULE - SUPABASE (PostgreSQL)
-- =====================================================

-- NOTE: "USE scalable_app" removed — not needed in Supabase


-- =====================================================
-- PLANS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS plans (

    plan_id SERIAL PRIMARY KEY,

    plan_name VARCHAR(50) NOT NULL,

    price DECIMAL(10,2) NOT NULL,

    duration_months INT NOT NULL,

    features TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- =====================================================
-- SUBSCRIPTIONS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS subscriptions (

    subscription_id SERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL,

    plan_id INT NOT NULL,

    start_date DATE NOT NULL,

    end_date DATE NOT NULL,

    status VARCHAR(20) DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE','EXPIRED','CANCELLED','PENDING')),

    payment_status VARCHAR(10) DEFAULT 'UNPAID'
        CHECK (payment_status IN ('PAID','UNPAID','FAILED')),

    auto_renew BOOLEAN DEFAULT FALSE,

    cancelled_at TIMESTAMP NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_subscription_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_subscription_plan
        FOREIGN KEY (plan_id)
        REFERENCES plans(plan_id)
        ON DELETE CASCADE
);


-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_subscriptions_user
ON subscriptions(user_id);

CREATE INDEX IF NOT EXISTS idx_subscriptions_status
ON subscriptions(status);


-- =====================================================
-- SAMPLE DATA: PLANS
-- =====================================================

INSERT INTO plans
(plan_name, price, duration_months, features)
VALUES
(
    'Basic',
    199.00, 1,
    'Ad Free Access'
),
(
    'Premium',
    499.00, 3,
    'Priority Support + Analytics'
),
(
    'Enterprise',
    1999.00, 12,
    'Full Business Features'
);


-- =====================================================
-- SAMPLE DATA: SUBSCRIPTION
-- =====================================================

INSERT INTO subscriptions
(user_id, plan_id, start_date, end_date, status, payment_status)
VALUES
(
    1, 2,
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '3 months',
    'ACTIVE',
    'PAID'
);


-- =====================================================
-- UPGRADE SUBSCRIPTION TO ENTERPRISE
-- =====================================================

UPDATE subscriptions
SET
    plan_id = 3,
    start_date = CURRENT_DATE,
    end_date = CURRENT_DATE + INTERVAL '12 months',
    payment_status = 'PAID'
WHERE user_id = 1
AND status = 'ACTIVE';


-- =====================================================
-- DOWNGRADE SUBSCRIPTION TO BASIC
-- =====================================================

UPDATE subscriptions
SET
    plan_id = 1,
    start_date = CURRENT_DATE,
    end_date = CURRENT_DATE + INTERVAL '1 month'
WHERE user_id = 1
AND status = 'ACTIVE';


-- =====================================================
-- VIEW ALL SUBSCRIPTIONS WITH USER & PLAN DETAILS
-- =====================================================

SELECT
    s.subscription_id,
    u.username,
    u.email,
    p.plan_name,
    p.price,
    s.start_date,
    s.end_date,
    s.status
FROM subscriptions s
JOIN users u ON s.user_id = u.user_id
JOIN plans p ON s.plan_id = p.plan_id;


-- =====================================================
-- CANCEL SUBSCRIPTION
-- =====================================================

UPDATE subscriptions
SET
    status = 'CANCELLED',
    cancelled_at = CURRENT_TIMESTAMP
WHERE subscription_id = 1;

