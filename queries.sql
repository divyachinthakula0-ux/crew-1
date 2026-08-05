-- ============================================================
-- SkillBridge Database — Shared Queries
-- Member 4: SQL Queries (Joins, Stored Procedures, Indexes, Optimization)
-- ============================================================
-- All queries below have been tested and verified in Supabase SQL Editor
-- against the live schema (users, gigs, orders tables).


-- ============================================================
-- SECTION 1: JOIN QUERIES
-- ============================================================

-- 1.1 Basic join: gig title + freelancer's first name
SELECT gigs.gig_title, users.first_name
FROM gigs
JOIN users ON gigs.freelancer_id = users.user_id;


-- 1.2 Gig details with freelancer's full name and username
SELECT gigs.gig_title, gigs.price, users.first_name, users.last_name, users.username
FROM gigs
JOIN users ON gigs.freelancer_id = users.user_id;


-- 1.3 Only active gigs, with price and freelancer name
SELECT gigs.gig_title, gigs.price, users.first_name
FROM gigs
JOIN users ON gigs.freelancer_id = users.user_id
WHERE gigs.gig_status = 'ACTIVE';


-- 1.4 Count of gigs posted per freelancer (includes freelancers with 0 gigs)
-- Uses LEFT JOIN so freelancers without any gigs still appear with count = 0
SELECT users.first_name, COUNT(gigs.gig_id) AS total_gigs
FROM users
LEFT JOIN gigs ON gigs.freelancer_id = users.user_id
GROUP BY users.first_name;


-- 1.5 Orders with gig title, client name, amount, status, and date
-- Core query for "My Orders" page / admin dashboard
SELECT 
    orders.order_id,
    gigs.gig_title,
    users.first_name AS client_name,
    orders.total_amount,
    orders.order_status,
    orders.order_date
FROM orders
JOIN gigs ON orders.gig_id = gigs.gig_id
JOIN users ON orders.client_id = users.user_id;


-- 1.6 Only pending orders (useful for notifications / admin review panel)
SELECT orders.order_id, gigs.gig_title, users.first_name AS client_name, orders.total_amount
FROM orders
JOIN gigs ON orders.gig_id = gigs.gig_id
JOIN users ON orders.client_id = users.user_id
WHERE orders.order_status = 'PENDING';


-- 1.7 Total revenue earned by each freelancer
-- Chains orders -> gigs -> users (via freelancer_id, not client_id)
SELECT users.first_name AS freelancer_name, SUM(orders.total_amount) AS total_earned
FROM orders
JOIN gigs ON orders.gig_id = gigs.gig_id
JOIN users ON gigs.freelancer_id = users.user_id
GROUP BY users.first_name;


-- ============================================================
-- SECTION 2: INDEXES
-- ============================================================
-- Added after checking EXPLAIN ANALYZE output on the queries above.
-- Indexes speed up JOIN and WHERE lookups on foreign key / filter columns.

CREATE INDEX IF NOT EXISTS idx_gigs_freelancer_id ON gigs(freelancer_id);
CREATE INDEX IF NOT EXISTS idx_gigs_status ON gigs(gig_status);
CREATE INDEX IF NOT EXISTS idx_orders_client_id ON orders(client_id);
CREATE INDEX IF NOT EXISTS idx_orders_gig_id ON orders(gig_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(order_status);


-- ============================================================
-- SECTION 3: STORED PROCEDURES / FUNCTIONS
-- ============================================================

-- 3.1 Get total amount earned by a specific freelancer (by user_id)
CREATE OR REPLACE FUNCTION get_freelancer_earnings(freelancer_id_input INT)
RETURNS NUMERIC AS $$
  SELECT COALESCE(SUM(orders.total_amount), 0)
  FROM orders
  JOIN gigs ON orders.gig_id = gigs.gig_id
  WHERE gigs.freelancer_id = freelancer_id_input;
$$ LANGUAGE sql;

-- Usage: SELECT get_freelancer_earnings(2);


-- 3.2 Mark an order as completed
CREATE OR REPLACE FUNCTION complete_order(order_id_input INT)
RETURNS VOID AS $$
BEGIN
  UPDATE orders SET order_status = 'COMPLETED' WHERE order_id = order_id_input;
END;
$$ LANGUAGE plpgsql;

-- Usage: SELECT complete_order(1);
