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
    password_hash VARCHAR(255) NOT NULL DEFAULT '',
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

-- ============================================================
-- STANDARD GLOBAL CATEGORIES SEED DATA
-- (Guarantees zero foreign key errors on fresh Neon/Postgres setups)
-- ============================================================
INSERT INTO categories (id, name, type, icon_name, color_hex, bg_color_hex, is_custom, sort_order)
VALUES
    ('food', 'Ovqatlanish', 'expense', 'restaurant', '#FF6B6B', '#FFE3E3', false, 1),
    ('transport', 'Transport', 'expense', 'directions_car', '#4D96FF', '#E8F1FF', false, 2),
    ('home', 'Uy-joy', 'expense', 'home', '#6BCB77', '#E8F8EA', false, 3),
    ('education', 'Ta''lim', 'expense', 'school', '#FFD93D', '#FFF9E6', false, 4),
    ('health', 'Salomatlik', 'expense', 'favorite', '#FF6B8B', '#FFEAF0', false, 5),
    ('clothes', 'Kiyim', 'expense', 'checkroom', '#9B51E0', '#F3E8FF', false, 6),
    ('entertainment', 'Ko''ngilochar', 'expense', 'sports_esports', '#FF9F45', '#FFF3E8', false, 7),
    ('other', 'Boshqa', 'expense', 'more_horiz', '#8A92A6', '#F0F2F5', false, 8),
    ('salary', 'Maosh', 'income', 'account_balance_wallet', '#2ECC71', '#E8F8F0', false, 1),
    ('business', 'Biznes', 'income', 'business_center', '#00BA88', '#E6F8F3', false, 2),
    ('bonus', 'Bonus', 'income', 'card_giftcard', '#F39C12', '#FEF5E7', false, 3),
    ('investment', 'Investitsiya', 'income', 'trending_up', '#3498DB', '#EBF5FB', false, 4),
    ('other_income', 'Boshqa daromad', 'income', 'add_circle', '#95A5A6', '#F4F6F6', false, 5)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 11. BILLING & SUBSCRIPTIONS SYSTEM
-- ============================================================
CREATE TABLE IF NOT EXISTS plans (
    id VARCHAR(32) PRIMARY KEY,
    name VARCHAR(64) NOT NULL,
    description TEXT,
    monthly_price NUMERIC(18, 0) NOT NULL DEFAULT 0,
    annual_price NUMERIC(18, 0) NOT NULL DEFAULT 0,
    currency VARCHAR(8) NOT NULL DEFAULT 'UZS',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO plans (id, name, description, monthly_price, annual_price, currency, is_active, sort_order)
VALUES
    ('free', 'Oddiy Reja', 'Asosiy daromad-xarajat hisobi va cheklangan tahlillar', 0, 0, 'UZS', true, 1),
    ('pro', 'Pro Intellekt', 'Cheksiz AI qaror tahlili, dinamik xarajat me''yori va eksport', 19000, 149000, 'UZS', true, 2)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    monthly_price = EXCLUDED.monthly_price,
    annual_price = EXCLUDED.annual_price;

CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id VARCHAR(32) NOT NULL REFERENCES plans(id) ON DELETE RESTRICT,
    status VARCHAR(24) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'canceled', 'trialing')),
    billing_cycle VARCHAR(16) NOT NULL DEFAULT 'none' CHECK (billing_cycle IN ('none', 'monthly', 'annual', 'lifetime')),
    start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    current_period_start TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    current_period_end TIMESTAMPTZ,
    canceled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_subscription UNIQUE (user_id)
);

CREATE TABLE IF NOT EXISTS payment_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id VARCHAR(32) NOT NULL REFERENCES plans(id) ON DELETE RESTRICT,
    billing_cycle VARCHAR(16) NOT NULL DEFAULT 'monthly' CHECK (billing_cycle IN ('monthly', 'annual')),
    amount NUMERIC(18, 0) NOT NULL CHECK (amount >= 0),
    currency VARCHAR(8) NOT NULL DEFAULT 'UZS',
    status VARCHAR(24) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'failed', 'expired', 'canceled')),
    payment_method VARCHAR(32) NOT NULL DEFAULT 'manual',
    external_transaction_id VARCHAR(128),
    paid_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ NOT NULL,
    notes TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS feature_usages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    feature_key VARCHAR(64) NOT NULL,
    period_key VARCHAR(16) NOT NULL,
    usage_count INT NOT NULL DEFAULT 0 CHECK (usage_count >= 0),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_feature_period UNIQUE (user_id, feature_key, period_key)
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_orders_user ON payment_orders(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payment_orders_status ON payment_orders(status);
CREATE INDEX IF NOT EXISTS idx_payment_orders_ext_tx ON payment_orders(external_transaction_id) WHERE external_transaction_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_feature_usages_user ON feature_usages(user_id, feature_key, period_key);


