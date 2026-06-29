-- =====================================================
-- SECURITY MODULE - FIXED v3
-- =====================================================

-- =====================================================
-- SAMPLE USERS (no skills column)
-- =====================================================

INSERT INTO users
(first_name, last_name, username, email, password_hash)
VALUES
(
    'Lohitha', 'Designer',
    'lohitha_designs',
    'lohitha@gmail.com',
    'hashed_password_123'
),
(
    'Rahul', 'Client',
    'rahul_client',
    'rahul@gmail.com',
    'hashed_password_456'
);


-- =====================================================
-- GIGS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS gigs (

    gig_id SERIAL PRIMARY KEY,

    freelancer_id BIGINT NOT NULL,

    gig_title VARCHAR(150) NOT NULL,

    gig_description TEXT NOT NULL,

    category VARCHAR(100),

    price DECIMAL(10,2) NOT NULL,

    delivery_days INT NOT NULL,

    gig_status VARCHAR(20) DEFAULT 'ACTIVE'
        CHECK (gig_status IN ('ACTIVE','PAUSED','DELETED')),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (freelancer_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);


-- =====================================================
-- ORDERS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS orders (

    order_id SERIAL PRIMARY KEY,

    client_id BIGINT NOT NULL,

    gig_id INT NOT NULL,

    quantity INT DEFAULT 1,

    total_amount DECIMAL(10,2) NOT NULL,

    order_status VARCHAR(20) DEFAULT 'PENDING'
        CHECK (order_status IN ('PENDING','IN_PROGRESS','COMPLETED','CANCELLED')),

    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (client_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE,

    FOREIGN KEY (gig_id)
        REFERENCES gigs(gig_id)
        ON DELETE CASCADE
);


-- =====================================================
-- REVIEWS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS reviews (

    review_id SERIAL PRIMARY KEY,

    order_id INT NOT NULL,

    reviewer_id BIGINT NOT NULL,

    rating INT NOT NULL,

    review_text TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE,

    FOREIGN KEY (reviewer_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
);


-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_gig_title ON gigs(gig_title);
CREATE INDEX IF NOT EXISTS idx_gig_category ON gigs(category);
CREATE INDEX IF NOT EXISTS idx_order_status ON orders(order_status);


-- =====================================================
-- SAMPLE GIGS
-- =====================================================

INSERT INTO gigs
(freelancer_id, gig_title, gig_description, category, price, delivery_days)
VALUES
(
    2, 'Professional UI Design',
    'Modern mobile and website UI designs',
    'Design', 5000, 5
),
(
    2, 'Logo Design',
    'Creative logo designs for startups',
    'Graphics', 2000, 2
);


-- =====================================================
-- SAMPLE ORDERS
-- =====================================================

INSERT INTO orders
(client_id, gig_id, total_amount)
VALUES
(3, 1, 5000);


-- =====================================================
-- SAMPLE REVIEWS
-- =====================================================

INSERT INTO reviews
(order_id, reviewer_id, rating, review_text)
VALUES
(1, 3, 5, 'Amazing work and fast delivery');


-- =====================================================
-- VIEW ALL GIGS
-- =====================================================

SELECT
    g.gig_title,
    g.category,
    g.price,
    g.delivery_days,
    u.first_name || ' ' || u.last_name AS freelancer
FROM gigs g
JOIN users u ON g.freelancer_id = u.user_id;


-- =====================================================
-- VIEW ORDER DETAILS
-- =====================================================

SELECT
    o.order_id,
    c.first_name || ' ' || c.last_name AS client_name,
    g.gig_title,
    o.total_amount,
    o.order_status
FROM orders o
JOIN users c ON o.client_id = c.user_id
JOIN gigs g ON o.gig_id = g.gig_id;


-- =====================================================
-- TOTAL PLATFORM REVENUE
-- =====================================================

SELECT SUM(amount) AS total_revenue
FROM payments
WHERE payment_status = 'SUCCESS';


-- =====================================================
-- ACTIVE FREELANCERS VIEW
-- =====================================================

CREATE OR REPLACE VIEW active_freelancers AS
SELECT
    user_id,
    first_name || ' ' || last_name AS full_name,
    username
FROM users
WHERE account_status = 'ACTIVE';

SELECT * FROM active_freelancers;