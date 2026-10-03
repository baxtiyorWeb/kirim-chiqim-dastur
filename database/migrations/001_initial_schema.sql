-- Migration: 001_initial_schema.sql
-- Description: Create users, categories, and core transactions

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE,
    phone_number VARCHAR(32) UNIQUE,
    full_name VARCHAR(128) NOT NULL,
    avatar_url TEXT,
    currency VARCHAR(8) NOT NULL DEFAULT 'UZS',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS categories (
    id VARCHAR(64) PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(64) NOT NULL,
    type VARCHAR(16) NOT NULL CHECK (type IN ('expense', 'income')),
    icon_name VARCHAR(64) NOT NULL,
    color_hex VARCHAR(16) NOT NULL,
    bg_color_hex VARCHAR(16) NOT NULL,
    is_custom BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id VARCHAR(64) NOT NULL REFERENCES categories(id),
    title VARCHAR(255) NOT NULL,
    amount NUMERIC(18, 0) NOT NULL CHECK (amount >= 0),
    transaction_type VARCHAR(16) NOT NULL CHECK (transaction_type IN ('expense', 'income', 'transfer')),
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    note TEXT,
    payment_method VARCHAR(32) NOT NULL DEFAULT 'cash',
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON transactions(user_id, transaction_date DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category_id) WHERE deleted_at IS NULL;
