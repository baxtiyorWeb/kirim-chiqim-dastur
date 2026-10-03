-- ============================================================
-- CANONICAL POSTGRESQL SCHEMA FOR KIRIM-CHIQIM DASTUR (MOLIYA)
-- Production Grade Schema for Neon / PostgreSQL
-- Monetary values stored as NUMERIC(18, 0) for safe integer Uzbek So'm
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. USERS TABLE
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

-- 2. ACCOUNTS / WALLETS TABLE
CREATE TABLE IF NOT EXISTS accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(64) NOT NULL,
    account_type VARCHAR(32) NOT NULL DEFAULT 'cash', -- 'cash', 'card_uzcard', 'card_humo', 'bank', 'savings'
    balance NUMERIC(18, 0) NOT NULL DEFAULT 0,
    currency VARCHAR(8) NOT NULL DEFAULT 'UZS',
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. CATEGORIES TABLE
CREATE TABLE IF NOT EXISTS categories (
    id VARCHAR(64) PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE, -- NULL indicates global standard category
    name VARCHAR(64) NOT NULL,
    type VARCHAR(16) NOT NULL CHECK (type IN ('expense', 'income')),
    icon_name VARCHAR(64) NOT NULL,
    color_hex VARCHAR(16) NOT NULL,
    bg_color_hex VARCHAR(16) NOT NULL,
    is_custom BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. TRANSACTIONS TABLE
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    account_id UUID REFERENCES accounts(id) ON DELETE SET NULL,
    category_id VARCHAR(64) NOT NULL REFERENCES categories(id),
    title VARCHAR(255) NOT NULL,
    amount NUMERIC(18, 0) NOT NULL CHECK (amount >= 0),
    transaction_type VARCHAR(16) NOT NULL CHECK (transaction_type IN ('expense', 'income', 'transfer')),
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    note TEXT,
    payment_method VARCHAR(32) NOT NULL DEFAULT 'cash',
    person_name VARCHAR(128),
    debt_id UUID,
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- 5. MONTHLY BUDGETS TABLE ("Smeta")
CREATE TABLE IF NOT EXISTS budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    year_month VARCHAR(7) NOT NULL, -- e.g. '2026-10'
    total_monthly_limit NUMERIC(18, 0) NOT NULL CHECK (total_monthly_limit >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_budget_month UNIQUE (user_id, year_month)
);

-- 6. BUDGET CATEGORY LIMITS TABLE
CREATE TABLE IF NOT EXISTS budget_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    budget_id UUID NOT NULL REFERENCES budgets(id) ON DELETE CASCADE,
    category_id VARCHAR(64) NOT NULL REFERENCES categories(id),
    limit_amount NUMERIC(18, 0) NOT NULL CHECK (limit_amount >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_budget_category UNIQUE (budget_id, category_id)
);

-- 7. DEBTS TABLE ("Qarz daftari")
-- Clearly distinguishes:
-- 1. 'borrowed' (Olingan qarz - I owe someone, status: active / partially_paid / returned)
-- 2. 'lent' (Berilgan qarz - Someone owes me, status: active / partially_paid / returned)
CREATE TABLE IF NOT EXISTS debts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    person_name VARCHAR(128) NOT NULL,
    phone_number VARCHAR(32),
    amount NUMERIC(18, 0) NOT NULL CHECK (amount > 0),
    paid_amount NUMERIC(18, 0) NOT NULL DEFAULT 0 CHECK (paid_amount >= 0),
    debt_type VARCHAR(16) NOT NULL CHECK (debt_type IN ('borrowed', 'lent')),
    status VARCHAR(24) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'partially_paid', 'returned')),
    due_date TIMESTAMPTZ,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- 8. DEBT PAYMENTS / REPAYMENT HISTORY TABLE
CREATE TABLE IF NOT EXISTS debt_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    debt_id UUID NOT NULL REFERENCES debts(id) ON DELETE CASCADE,
    amount NUMERIC(18, 0) NOT NULL CHECK (amount > 0),
    payment_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    note TEXT,
    account_id UUID REFERENCES accounts(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. SAVINGS GOALS TABLE ("Maqsadlar")
CREATE TABLE IF NOT EXISTS savings_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(128) NOT NULL,
    target_amount NUMERIC(18, 0) NOT NULL CHECK (target_amount > 0),
    current_amount NUMERIC(18, 0) NOT NULL DEFAULT 0 CHECK (current_amount >= 0),
    deadline TIMESTAMPTZ,
    emoji VARCHAR(16) NOT NULL DEFAULT '🎯',
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 10. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(128) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(32) NOT NULL, -- 'budget_warning', 'debt_reminder', 'goal_milestone'
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- PERFORMANCE INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON transactions(user_id, transaction_date DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_transactions_account ON transactions(account_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_debts_user_status ON debts(user_id, status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_debts_type ON debts(debt_type) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_debt_payments_debt ON debt_payments(debt_id, payment_date DESC);
CREATE INDEX IF NOT EXISTS idx_budget_categories_budget ON budget_categories(budget_id);
CREATE INDEX IF NOT EXISTS idx_savings_goals_user ON savings_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id, is_read, created_at DESC);
