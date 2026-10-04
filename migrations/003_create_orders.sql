CREATE TABLE IF NOT EXISTS orders (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id CHAR(36) NOT NULL,
    project_id CHAR(36) NULL,
    order_date TIMESTAMP NULL,
    status VARCHAR(20) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_orders_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_orders_project
        FOREIGN KEY (project_id) REFERENCES projects(id)
        ON DELETE SET NULL
) ENGINE=InnoDB;
