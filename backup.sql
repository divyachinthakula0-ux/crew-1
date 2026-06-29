-- =====================================================
-- BACKUP & DOCUMENTATION MODULE - SUPABASE (PostgreSQL)
-- =====================================================

-- NOTE: "USE freelancer_app" removed — not needed in Supabase


-- =====================================================
-- 1. DATABASE BACKUP TABLES
-- =====================================================

CREATE TABLE IF NOT EXISTS users_backup AS
SELECT * FROM users;

CREATE TABLE IF NOT EXISTS gigs_backup AS
SELECT * FROM gigs;

CREATE TABLE IF NOT EXISTS orders_backup AS
SELECT * FROM orders;

CREATE TABLE IF NOT EXISTS payments_backup AS
SELECT * FROM payments;

CREATE TABLE IF NOT EXISTS subscriptions_backup AS
SELECT * FROM subscriptions;


-- =====================================================
-- 2. VERIFY BACKUP TABLES
-- =====================================================

SELECT * FROM users_backup;
SELECT * FROM gigs_backup;
SELECT * FROM orders_backup;
SELECT * FROM payments_backup;
SELECT * FROM subscriptions_backup;


-- =====================================================
-- 3. EXPORT BACKUP COMMAND (run in Terminal, not here)
-- =====================================================

-- pg_dump -U postgres -d postgres > supabase_backup.sql


-- =====================================================
-- 4. RESTORE BACKUP COMMAND (run in Terminal, not here)
-- =====================================================

-- psql -U postgres -d postgres < supabase_backup.sql


-- =====================================================
-- 5. SHOW ALL TABLES (replaces SHOW TABLES)
-- =====================================================

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;


-- =====================================================
-- 6-10. DOCUMENT ALL TABLES (replaces DESCRIBE)
-- =====================================================

SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'users';

SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'gigs';

SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'orders';

SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'payments';

SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'subscriptions';


-- =====================================================
-- 11. FULL DOCUMENTATION QUERY
-- =====================================================

SELECT
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;


-- =====================================================
-- 12. BACKUP CREATION TIME
-- =====================================================

SELECT NOW() AS backup_created_time;


-- =====================================================
-- 13. TOTAL NUMBER OF TABLES
-- =====================================================

SELECT COUNT(*) AS total_tables
FROM information_schema.tables
WHERE table_schema = 'public';


-- =====================================================
-- 14. TABLE STORAGE INFORMATION
-- =====================================================

SELECT
    relname AS table_name,
    ROUND(pg_total_relation_size(relid) / 1024.0, 2) AS table_size_kb
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;


-- =====================================================
-- 15. VIEW TABLE STATUS (replaces SHOW TABLE STATUS)
-- =====================================================

SELECT
    relname AS table_name,
    n_live_tup AS live_rows,
    n_dead_tup AS dead_rows,
    last_vacuum,
    last_analyze
FROM pg_stat_user_tables
ORDER BY relname;


-- =====================================================
-- 16. DATABASE DOCUMENTATION VIEW
-- =====================================================

CREATE OR REPLACE VIEW database_documentation AS
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;


-- =====================================================
-- 17. DISPLAY DOCUMENTATION VIEW
-- =====================================================

SELECT * FROM database_documentation;