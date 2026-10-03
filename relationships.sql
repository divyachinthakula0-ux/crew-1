-- =====================================================
-- RELATIONSHIPS & CONSTRAINTS (Member 6) - DRAFT v1
-- Covers: users, projects, orders, payments
-- Pending: plans, subscriptions, gigs (files not reviewed yet)
--
-- NOTE: This assumes the type fixes below are made in the
-- original files first (user_id / project_id must be UUID,
-- and must reference users(id), projects(id)).
-- =====================================================

-- 1. users (1) -> projects (many)
ALTER TABLE projects
    ALTER COLUMN user_id SET NOT NULL,
    ADD CONSTRAINT fk_projects_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE;          -- delete user -> delete their projects

-- 2. users (1) -> orders (many)
ALTER TABLE orders
    ALTER COLUMN user_id SET NOT NULL,
    ADD CONSTRAINT fk_orders_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE RESTRICT;         -- keep order history; block user delete

-- 3. projects (1) -> orders (many)
ALTER TABLE orders
    ADD CONSTRAINT fk_orders_project
    FOREIGN KEY (project_id) REFERENCES projects(id)
    ON DELETE SET NULL;         -- project removed, order record stays

-- 4. orders (1) -> payments (many)
ALTER TABLE payments
    ALTER COLUMN order_id SET NOT NULL,
    ADD CONSTRAINT fk_payments_order
    FOREIGN KEY (order_id) REFERENCES orders(id)
    ON DELETE RESTRICT;         -- never lose payment records

-- Indexes on foreign keys (faster joins)
CREATE INDEX idx_projects_user_id  ON projects(user_id);
CREATE INDEX idx_orders_user_id    ON orders(user_id);
CREATE INDEX idx_orders_project_id ON orders(project_id);
CREATE INDEX idx_payments_order_id ON payments(order_id);
