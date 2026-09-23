# Member 4 — Orders & Payments Tables

## Orders Table

| Column Name | Data Type | Required/Optional | Key |
|---|---|---|---|
| id | BIGSERIAL | Required | Primary Key |
| user_id | BIGINT | Required | Foreign Key → Users.user_id |
| project_id | BIGINT | Optional | - |
| order_date | TIMESTAMP | Required | - |
| status | VARCHAR(20) | Required | - |
| total_amount | DECIMAL(10,2) | Required | - |
| created_at | TIMESTAMP | Required | - |
| updated_at | TIMESTAMP | Required | - |

## Payments Table

| Column Name | Data Type | Required/Optional | Key |
|---|---|---|---|
| id | BIGSERIAL | Required | Primary Key |
| order_id | BIGINT | Required | Foreign Key → Orders.id |
| amount | DECIMAL(10,2) | Required | - |
| payment_method | VARCHAR(50) | Required | - |
| payment_status | VARCHAR(20) | Optional (default PENDING) | - |
| transaction_reference | VARCHAR(255) | Optional | Unique |
| paid_at | TIMESTAMP | Optional | - |
| created_at | TIMESTAMP | Required | - |
| updated_at | TIMESTAMP | Required | - |
