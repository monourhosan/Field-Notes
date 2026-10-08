ALTER TABLE customers ADD COLUMN version BIGINT NOT NULL DEFAULT 0;
ALTER TABLE sites ADD COLUMN version BIGINT NOT NULL DEFAULT 0;
ALTER TABLE field_notes ADD COLUMN version BIGINT NOT NULL DEFAULT 0;
CREATE INDEX idx_customer_user_updated ON customers(user_id, updated_at);
