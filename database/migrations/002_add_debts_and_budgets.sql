-- Migration: 002_add_debts_and_budgets.sql
-- Description: Add budgets ("Smeta"), category limits, debts ("Qarz daftari"), and repayments history

-- 1. Budgets & Smeta
CREATE TABLE IF NOT EXISTS budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    year_month VARCHAR(7) NOT NULL,
    total_monthly_limit NUMERIC(18, 0) NOT NULL CHECK (total_monthly_limit >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_budget_month UNIQUE (user_id, year_month)
);

CREATE TABLE IF NOT EXISTS budget_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    budget_id UUID NOT NULL REFERENCES budgets(id) ON DELETE CASCADE,
    category_id VARCHAR(64) NOT NULL REFERENCES categories(id),
    limit_amount NUMERIC(18, 0) NOT NULL CHECK (limit_amount >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_budget_category UNIQUE (budget_id, category_id)
);

-- 2. Debts ("Qarz daftari")
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

CREATE TABLE IF NOT EXISTS debt_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    debt_id UUID NOT NULL REFERENCES debts(id) ON DELETE CASCADE,
    amount NUMERIC(18, 0) NOT NULL CHECK (amount > 0),
    payment_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Link transaction to debt if debt repayment is recorded as financial transaction
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS person_name VARCHAR(128);
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS debt_id UUID REFERENCES debts(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_debts_user_status ON debts(user_id, status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_debt_payments_debt ON debt_payments(debt_id, payment_date DESC);
CREATE INDEX IF NOT EXISTS idx_budget_categories_budget ON budget_categories(budget_id);
