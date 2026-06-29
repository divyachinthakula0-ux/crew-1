-- =====================================================
-- USER MANAGEMENT SYSTEM - SUPABASE (PostgreSQL)
-- =====================================================

-- NOTE: DROP/CREATE DATABASE and USE are removed
-- Supabase manages the database for you


-- =====================================================
-- USERS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS users (

    user_id BIGSERIAL PRIMARY KEY,

    first_name VARCHAR(50) NOT NULL,

    last_name VARCHAR(50) NOT NULL,

    username VARCHAR(50) UNIQUE NOT NULL,

    email VARCHAR(120) UNIQUE NOT NULL,

    phone VARCHAR(15) UNIQUE,

    password_hash VARCHAR(255) NOT NULL,

    profile_photo TEXT,

    gender VARCHAR(10) CHECK (gender IN ('MALE','FEMALE','OTHER')),

    date_of_birth DATE,

    bio TEXT,

    role VARCHAR(20) DEFAULT 'USER'
        CHECK (role IN ('USER','ADMIN','MODERATOR')),

    is_verified BOOLEAN DEFAULT FALSE,

    account_status VARCHAR(20) DEFAULT 'ACTIVE'
        CHECK (account_status IN ('ACTIVE','BLOCKED','SUSPENDED','DELETED')),

    last_login TIMESTAMP NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- =====================================================
-- USER SETTINGS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS user_settings (

    setting_id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL,

    email_notifications BOOLEAN DEFAULT TRUE,

    sms_notifications BOOLEAN DEFAULT FALSE,

    dark_mode BOOLEAN DEFAULT FALSE,

    language VARCHAR(30) DEFAULT 'English',

    timezone VARCHAR(50) DEFAULT 'Asia/Kolkata',

    privacy_mode BOOLEAN DEFAULT FALSE,

    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);


-- =====================================================
-- LOGIN HISTORY TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS login_history (

    login_id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL,

    login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    logout_time TIMESTAMP NULL,

    ip_address VARCHAR(50),

    device_name VARCHAR(255),

    browser VARCHAR(100),

    os VARCHAR(100),

    login_status VARCHAR(10)
        CHECK (login_status IN ('SUCCESS','FAILED')),

    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);


-- =====================================================
-- PASSWORD RESETS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS password_resets (

    reset_id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL,

    reset_token VARCHAR(255) NOT NULL,

    expires_at TIMESTAMP NOT NULL,

    is_used BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);


-- =====================================================
-- EMAIL VERIFICATIONS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS email_verifications (

    verification_id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL,

    verification_token VARCHAR(255) NOT NULL,

    expires_at TIMESTAMP NOT NULL,

    verified BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);


-- =====================================================
-- USER SESSIONS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS user_sessions (

    session_id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL,

    session_token TEXT NOT NULL,

    login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    expires_at TIMESTAMP NOT NULL,

    is_active BOOLEAN DEFAULT TRUE,

    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);


-- =====================================================
-- PREMIUM PLANS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS premium_plans (

    plan_id BIGSERIAL PRIMARY KEY,

    plan_name VARCHAR(100) NOT NULL,

    description TEXT,

    price DECIMAL(10,2) NOT NULL,

    duration_days INT NOT NULL,

    features TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- =====================================================
-- USER SUBSCRIPTIONS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS user_subscriptions (

    subscription_id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL,

    plan_id BIGINT NOT NULL,

    start_date DATE NOT NULL,

    end_date DATE NOT NULL,

    payment_status VARCHAR(10) DEFAULT 'PENDING'
        CHECK (payment_status IN ('PENDING','PAID','FAILED')),

    subscription_status VARCHAR(20) DEFAULT 'ACTIVE'
        CHECK (subscription_status IN ('ACTIVE','EXPIRED','CANCELLED')),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    FOREIGN KEY (plan_id)
        REFERENCES premium_plans(plan_id)
);


-- =====================================================
-- PAYMENTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS payments (

    payment_id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL,

    subscription_id BIGINT NOT NULL,

    amount DECIMAL(10,2) NOT NULL,

    payment_method VARCHAR(20)
        CHECK (payment_method IN ('UPI','CARD','NETBANKING','WALLET')),

    transaction_id VARCHAR(255) UNIQUE NOT NULL,

    payment_status VARCHAR(10) DEFAULT 'PENDING'
        CHECK (payment_status IN ('SUCCESS','FAILED','PENDING','REFUNDED')),

    paid_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    FOREIGN KEY (subscription_id)
        REFERENCES user_subscriptions(subscription_id)
        ON DELETE CASCADE
);


-- =====================================================
-- SECURITY LOGS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS security_logs (

    log_id BIGSERIAL PRIMARY KEY,

    user_id BIGINT,

    activity TEXT,

    ip_address VARCHAR(50),

    user_agent TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE SET NULL
);


-- =====================================================
-- ANALYTICS REPORTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS analytics_reports (

    report_id BIGSERIAL PRIMARY KEY,

    total_users INT DEFAULT 0,

    active_users INT DEFAULT 0,

    premium_users INT DEFAULT 0,

    total_revenue DECIMAL(15,2) DEFAULT 0,

    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_status ON users(account_status);
CREATE INDEX idx_login_history_user ON login_history(user_id);
CREATE INDEX idx_payments_user ON payments(user_id);
CREATE INDEX idx_subscription_user ON user_subscriptions(user_id);


-- =====================================================
-- SAMPLE DATA: PREMIUM PLANS
-- =====================================================

INSERT INTO premium_plans
(plan_name, description, price, duration_days, features)
VALUES
(
    'Basic Plan',
    'Access to standard premium features',
    199.00, 30,
    'No Ads, Faster Support'
),
(
    'Pro Plan',
    'Advanced premium access',
    499.00, 90,
    'Priority Support, Analytics, Unlimited Access'
),
(
    'Enterprise Plan',
    'Complete enterprise package',
    1999.00, 365,
    'Dedicated Manager, Advanced Security'
);


-- =====================================================
-- VIEW: ACTIVE USERS
-- =====================================================

CREATE OR REPLACE VIEW active_users AS
SELECT
    user_id,
    username,
    email,
    role,
    created_at
FROM users
WHERE account_status = 'ACTIVE';


-- =====================================================
-- FUNCTION: GET USER PROFILE (replaces MySQL procedure)
-- =====================================================

CREATE OR REPLACE FUNCTION get_user_profile(uid BIGINT)
RETURNS TABLE (
    user_id BIGINT,
    first_name VARCHAR,
    last_name VARCHAR,
    username VARCHAR,
    email VARCHAR,
    phone VARCHAR,
    role VARCHAR,
    account_status VARCHAR,
    created_at TIMESTAMP
)
LANGUAGE sql AS $$
    SELECT
        user_id, first_name, last_name,
        username, email, phone,
        role, account_status, created_at
    FROM users
    WHERE user_id = uid;
$$;


-- =====================================================
-- TRIGGER: AUTO CREATE USER SETTINGS ON NEW USER
-- =====================================================

CREATE OR REPLACE FUNCTION create_default_settings()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO user_settings(user_id) VALUES (NEW.user_id);
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_create_default_settings
AFTER INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION create_default_settings();


-- =====================================================
-- BACKUP TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS users_backup AS
SELECT * FROM users;


-- =====================================================
-- SAMPLE USER INSERT
-- =====================================================

INSERT INTO users
(first_name, last_name, username, email, phone, password_hash)
VALUES
(
    'Divya',
    'Chinthakula',
    'divya_01',
    'divya@gmail.com',
    '9876543210',
    '$2b$10$encryptedpassword'
);


-- =====================================================
-- SAMPLE SUBSCRIPTION INSERT
-- =====================================================

INSERT INTO user_subscriptions
(user_id, plan_id, start_date, end_date, payment_status, subscription_status)
VALUES
(1, 1, '2026-05-15', '2026-06-15', 'PAID', 'ACTIVE');


-- =====================================================
-- QUERIES
-- =====================================================

-- Fetch active user by email
SELECT * FROM users
WHERE email = 'divya@gmail.com'
AND account_status = 'ACTIVE';

-- Update user profile
UPDATE users
SET bio = 'Software Developer',
    profile_photo = 'profile.jpg'
WHERE user_id = 1;

-- Total users count
SELECT COUNT(*) AS total_users FROM users;

-- Total revenue
SELECT SUM(amount) AS total_revenue
FROM payments
WHERE payment_status = 'SUCCESS';

-- Active subscriptions with plan details
SELECT
    u.username,
    p.plan_name,
    us.end_date
FROM users u
JOIN user_subscriptions us ON u.user_id = us.user_id
JOIN premium_plans p ON us.plan_id = p.plan_id
WHERE us.subscription_status = 'ACTIVE';
