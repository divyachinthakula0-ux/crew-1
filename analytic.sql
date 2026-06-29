-- =====================================================
-- ANALYTICS - FIXED SUBSCRIPTIONS INSERT
-- =====================================================

-- subscriptions table already exists from plans.sql
-- it uses plan_id instead of plan_name
-- so we insert using plan_id

INSERT INTO subscriptions
(user_id, plan_id, start_date, end_date, status, payment_status)
VALUES
(
    1, 1,
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '1 month',
    'ACTIVE', 'PAID'
),
(
    2, 2,
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '1 month',
    'ACTIVE', 'PAID'
);


-- =====================================================
-- 1. TOTAL USERS
-- =====================================================
SELECT COUNT(*) AS total_users FROM users;

-- =====================================================
-- 2. TOTAL FREELANCERS
-- =====================================================
SELECT COUNT(*) AS total_freelancers FROM users
WHERE role = 'FREELANCER';

-- =====================================================
-- 3. TOTAL CLIENTS
-- =====================================================
SELECT COUNT(*) AS total_clients FROM users
WHERE role = 'CLIENT';

-- =====================================================
-- 4. ACTIVE USERS
-- =====================================================
SELECT COUNT(*) AS active_users FROM users
WHERE account_status = 'ACTIVE';

-- =====================================================
-- 5. TOTAL GIGS
-- =====================================================
SELECT COUNT(*) AS total_gigs FROM gigs;

-- =====================================================
-- 6. ACTIVE GIGS
-- =====================================================
SELECT COUNT(*) AS active_gigs FROM gigs
WHERE gig_status = 'ACTIVE';

-- =====================================================
-- 7. TOTAL ORDERS
-- =====================================================
SELECT COUNT(*) AS total_orders FROM orders;

-- =====================================================
-- 8. COMPLETED ORDERS
-- =====================================================
SELECT COUNT(*) AS completed_orders FROM orders
WHERE order_status = 'COMPLETED';

-- =====================================================
-- 9. PENDING ORDERS
-- =====================================================
SELECT COUNT(*) AS pending_orders FROM orders
WHERE order_status = 'PENDING';

-- =====================================================
-- 10. TOTAL REVENUE
-- =====================================================
SELECT SUM(amount) AS total_revenue FROM payments
WHERE payment_status = 'SUCCESS';

-- =====================================================
-- 11. MONTHLY REVENUE
-- =====================================================
SELECT
    EXTRACT(MONTH FROM paid_at) AS month,
    EXTRACT(YEAR FROM paid_at) AS year,
    SUM(amount) AS monthly_revenue
FROM payments
WHERE payment_status = 'SUCCESS'
GROUP BY
    EXTRACT(YEAR FROM paid_at),
    EXTRACT(MONTH FROM paid_at)
ORDER BY year, month;

-- =====================================================
-- 12. FAILED PAYMENTS
-- =====================================================
SELECT COUNT(*) AS failed_payments FROM payments
WHERE payment_status = 'FAILED';

-- =====================================================
-- 13. ACTIVE SUBSCRIPTIONS
-- =====================================================
SELECT COUNT(*) AS active_subscriptions FROM subscriptions
WHERE status = 'ACTIVE';

-- =====================================================
-- 14. EXPIRED SUBSCRIPTIONS
-- =====================================================
SELECT COUNT(*) AS expired_subscriptions FROM subscriptions
WHERE status = 'EXPIRED';

-- =====================================================
-- 15. TOP EARNING FREELANCERS
-- =====================================================
SELECT
    u.first_name || ' ' || u.last_name AS full_name,
    SUM(o.total_amount) AS total_earnings
FROM users u
JOIN gigs g ON u.user_id = g.freelancer_id
JOIN orders o ON g.gig_id = o.gig_id
WHERE o.order_status = 'COMPLETED'
GROUP BY u.first_name, u.last_name
ORDER BY total_earnings DESC;

-- =====================================================
-- 16. MOST ORDERED GIGS
-- =====================================================
SELECT
    g.gig_title,
    COUNT(o.order_id) AS total_orders
FROM gigs g
JOIN orders o ON g.gig_id = o.gig_id
GROUP BY g.gig_title
ORDER BY total_orders DESC;

-- =====================================================
-- 17. USER ORDER HISTORY
-- =====================================================
SELECT
    u.first_name || ' ' || u.last_name AS full_name,
    g.gig_title,
    o.total_amount,
    o.order_status,
    o.order_date
FROM orders o
JOIN users u ON o.client_id = u.user_id
JOIN gigs g ON o.gig_id = g.gig_id
ORDER BY o.order_date DESC;

-- =====================================================
-- 18. AVERAGE GIG PRICE
-- =====================================================
SELECT AVG(price) AS average_gig_price FROM gigs;

-- =====================================================
-- 19. HIGHEST PAYMENT
-- =====================================================
SELECT MAX(amount) AS highest_payment FROM payments;

-- =====================================================
-- 20. LOWEST PAYMENT
-- =====================================================
SELECT MIN(amount) AS lowest_payment FROM payments;

-- =====================================================
-- 21. DAILY USER REGISTRATIONS
-- =====================================================
SELECT
    DATE(created_at) AS registration_date,
    COUNT(*) AS total_registrations
FROM users
GROUP BY DATE(created_at)
ORDER BY registration_date DESC;

-- =====================================================
-- 22. PLATFORM SUMMARY REPORT
-- =====================================================
SELECT
    (SELECT COUNT(*) FROM users) AS total_users,
    (SELECT COUNT(*) FROM gigs) AS total_gigs,
    (SELECT COUNT(*) FROM orders) AS total_orders,
    (SELECT SUM(amount) FROM payments
        WHERE payment_status = 'SUCCESS') AS total_revenue;

-- =====================================================
-- 23. ACTIVE FREELANCERS REPORT VIEW
-- =====================================================
CREATE OR REPLACE VIEW active_freelancers_report AS
SELECT
    user_id,
    first_name || ' ' || last_name AS full_name,
    username
FROM users
WHERE account_status = 'ACTIVE';

-- =====================================================
-- 24. DISPLAY ACTIVE FREELANCERS REPORT
-- =====================================================
SELECT * FROM active_freelancers_report;