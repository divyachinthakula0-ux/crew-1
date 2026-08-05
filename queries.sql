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
-- Checked query performance with EXPLAIN ANALYZE (see below). Tables are
-- currently small, so all queries run in under 1ms with sequential scans,
-- which Postgres correctly prefers at this size.
--
-- Verified via: SELECT indexname, tablename FROM pg_indexes WHERE schemaname = 'public';
-- The indexes below already exist on the database (created earlier by the
-- team), covering every column used in our JOIN and WHERE clauses:
--
--   idx_gigs_freelancer_id   ON gigs(freelancer_id)
--   idx_gigs_status          ON gigs(gig_status)
--   idx_orders_client_id     ON orders(client_id)
--   idx_orders_gig_id        ON orders(gig_id)
--   idx_order_status         ON orders(order_status)
--
-- IF NOT EXISTS is used below so this script is safe to re-run without
-- errors, and to document the recommended indexes for this query set.

CREATE INDEX IF NOT EXISTS idx_gigs_freelancer_id ON gigs(freelancer_id);
CREATE INDEX IF NOT EXISTS idx_gigs_status ON gigs(gig_status);
CREATE INDEX IF NOT EXISTS idx_orders_client_id ON orders(client_id);
CREATE INDEX IF NOT EXISTS idx_orders_gig_id ON orders(gig_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(order_status);


-- Sample EXPLAIN ANALYZE check (run against query 1.5 above):
--
-- EXPLAIN ANALYZE
-- SELECT orders.order_id, gigs.gig_title, users.first_name AS client_name,
--        orders.total_amount, orders.order_status
-- FROM orders
-- JOIN gigs ON orders.gig_id = gigs.gig_id
-- JOIN users ON orders.client_id = users.user_id;
--
-- Result: Planning Time: 3.176 ms | Execution Time: 0.289 ms
-- (Seq Scans used since tables are small; indexes above are in place for
-- when data volume grows.)


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
-- Tested result: 5000.00 (correct — matches Lohitha's one order)


-- 3.2 Mark an order as completed
CREATE OR REPLACE FUNCTION complete_order(order_id_input INT)
RETURNS VOID AS $$
BEGIN
  UPDATE orders SET order_status = 'COMPLETED' WHERE order_id = order_id_input;
END;
$$ LANGUAGE plpgsql;

-- Usage: SELECT complete_order(1);
