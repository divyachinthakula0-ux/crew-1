

-- =====================================================
-- AUTHENTICATION MODULE - SUPABASE (PostgreSQL)
-- =====================================================

-- NOTE: "USE scalable_app" removed — not needed in Supabase

-- =====================================================
-- LOGIN: FETCH USER BY EMAIL
-- =====================================================

SELECT
    user_id,
    username,
    email,
    password_hash,
    account_status
FROM users
WHERE email = 'divya@gmail.com';


-- =====================================================
-- UPDATE LAST LOGIN
-- =====================================================

UPDATE users
SET last_login = CURRENT_TIMESTAMP
WHERE user_id = 1;


-- =====================================================
-- INSERT SESSION
-- =====================================================

INSERT INTO user_sessions
(user_id, session_token, expires_at)
VALUES
(
    1,
    'jwt_token_generated_here',
    NOW() + INTERVAL '1 day'
);


-- =====================================================
-- VALIDATE SESSION
-- =====================================================

SELECT *
FROM user_sessions
WHERE session_token = 'jwt_token_generated_here'
AND is_active = TRUE
AND expires_at > NOW();


-- =====================================================
-- LOGOUT: DEACTIVATE SESSION
-- =====================================================

UPDATE user_sessions
SET is_active = FALSE
WHERE session_token = 'jwt_token_generated_here';


-- =====================================================
-- LOGIN HISTORY: SUCCESS
-- =====================================================

INSERT INTO login_history
(user_id, ip_address, device_name, browser, os, login_status)
VALUES
(
    1,
    '192.168.1.1',
    'Windows Laptop',
    'Chrome',
    'Windows 11',
    'SUCCESS'
);


-- =====================================================
-- LOGIN HISTORY: FAILED
-- =====================================================

INSERT INTO login_history
(user_id, ip_address, device_name, browser, os, login_status)
VALUES
(
    1,
    '192.168.1.1',
    'Android Mobile',
    'Chrome',
    'Android',
    'FAILED'
);


-- =====================================================
-- EMAIL VERIFICATION: INSERT TOKEN
-- =====================================================

INSERT INTO email_verifications
(user_id, verification_token, expires_at)
VALUES
(
    1,
    'email_verification_token_123',
    NOW() + INTERVAL '10 minutes'
);


-- =====================================================
-- EMAIL VERIFICATION: VALIDATE TOKEN
-- =====================================================

SELECT *
FROM email_verifications
WHERE verification_token = 'email_verification_token_123'
AND verified = FALSE
AND expires_at > NOW();


-- =====================================================
-- EMAIL VERIFICATION: MARK VERIFIED
-- =====================================================

UPDATE users
SET is_verified = TRUE
WHERE user_id = 1;

UPDATE email_verifications
SET verified = TRUE
WHERE verification_token = 'email_verification_token_123';


-- =====================================================
-- PASSWORD RESET: INSERT TOKEN
-- =====================================================

INSERT INTO password_resets
(user_id, reset_token, expires_at)
VALUES
(
    1,
    'reset_token_12345',
    NOW() + INTERVAL '15 minutes'
);


-- =====================================================
-- PASSWORD RESET: VALIDATE TOKEN
-- =====================================================

SELECT *
FROM password_resets
WHERE reset_token = 'reset_token_12345'
AND is_used = FALSE
AND expires_at > NOW();


-- =====================================================
-- PASSWORD RESET: UPDATE PASSWORD
-- =====================================================

UPDATE users
SET password_hash = '$2b$10$newencryptedpassword'
WHERE user_id = 1;

UPDATE password_resets
SET is_used = TRUE
WHERE reset_token = 'reset_token_12345';


-- =====================================================
-- FETCH ACTIVE USER
-- =====================================================

SELECT *
FROM users
WHERE user_id = 1
AND account_status = 'ACTIVE';

SELECT *
FROM users
WHERE email = 'divya@gmail.com'
AND is_verified = TRUE
AND account_status = 'ACTIVE';


-- =====================================================
-- CLEANUP EXPIRED RECORDS
-- =====================================================

DELETE FROM user_sessions
WHERE expires_at < NOW();

DELETE FROM password_resets
WHERE expires_at < NOW();

DELETE FROM email_verifications
WHERE expires_at < NOW();


-- =====================================================
-- DETECT SUSPICIOUS LOGIN ATTEMPTS
-- =====================================================

SELECT
    user_id,
    COUNT(*) AS failed_attempts
FROM login_history
WHERE login_status = 'FAILED'
AND login_time >= NOW() - INTERVAL '1 hour'
GROUP BY user_id
HAVING COUNT(*) >= 5;


-- =====================================================
-- AUTO SUSPEND SUSPICIOUS USERS
-- =====================================================

UPDATE users
SET account_status = 'SUSPENDED'
WHERE user_id IN (
    SELECT user_id
    FROM login_history
    WHERE login_status = 'FAILED'
    AND login_time >= NOW() - INTERVAL '1 hour'
    GROUP BY user_id
    HAVING COUNT(*) >= 5
);


-- =====================================================
-- ACTIVE SESSIONS WITH USER INFO
-- =====================================================

SELECT
    u.username,
    us.login_time,
    us.expires_at
FROM users u
JOIN user_sessions us ON u.user_id = us.user_id
WHERE us.is_active = TRUE;


-- =====================================================
-- COUNT ACTIVE SESSIONS
-- =====================================================

SELECT COUNT(*) AS active_sessions
FROM user_sessions
WHERE is_active = TRUE;


-- =====================================================
-- TRIGGER: AUTO UPDATE LAST LOGIN
-- =====================================================

CREATE OR REPLACE FUNCTION update_last_login()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.login_status = 'SUCCESS' THEN
        UPDATE users
        SET last_login = CURRENT_TIMESTAMP
        WHERE user_id = NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_update_last_login
AFTER INSERT ON login_history
FOR EACH ROW
EXECUTE FUNCTION update_last_login();


-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_session_token
ON user_sessions(session_token);

CREATE INDEX IF NOT EXISTS idx_reset_token
ON password_resets(reset_token);

CREATE INDEX IF NOT EXISTS idx_verification_token
ON email_verifications(verification_token);

CREATE INDEX IF NOT EXISTS idx_login_status
ON login_history(login_status);


-- =====================================================
-- VIEW: VERIFIED USERS
-- =====================================================

CREATE OR REPLACE VIEW verified_users AS
SELECT
    user_id,
    username,
    email,
    created_at
FROM users
WHERE is_verified = TRUE
AND account_status = 'ACTIVE';
