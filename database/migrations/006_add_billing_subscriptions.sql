-- ============================================================
-- MIGRATION 006: ADD BILLING, SUBSCRIPTIONS & ENTITLEMENTS
-- Free & Pro subscription plans, payment orders and usage tracking
-- ============================================================

-- 1. PLANS TABLE
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

-- Seed Initial Plans (Free & Pro, extensible to business/team in future)
INSERT INTO plans (id, name, description, monthly_price, annual_price, currency, is_active, sort_order)
VALUES
    ('free', 'Oddiy Reja', 'Asosiy daromad-xarajat hisobi va cheklangan tahlillar', 0, 0, 'UZS', true, 1),
    ('pro', 'Pro Intellekt', 'Cheksiz AI qaror tahlili, dinamik xarajat me''yori va eksport', 19000, 149000, 'UZS', true, 2)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    monthly_price = EXCLUDED.monthly_price,
    annual_price = EXCLUDED.annual_price;

-- 2. SUBSCRIPTIONS TABLE
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

-- 3. PAYMENT ORDERS TABLE
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

-- 4. FEATURE USAGES TABLE
CREATE TABLE IF NOT EXISTS feature_usages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    feature_key VARCHAR(64) NOT NULL,
    period_key VARCHAR(16) NOT NULL,
    usage_count INT NOT NULL DEFAULT 0 CHECK (usage_count >= 0),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_feature_period UNIQUE (user_id, feature_key, period_key)
);

-- 5. INDEXES
CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_orders_user ON payment_orders(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payment_orders_status ON payment_orders(status);
CREATE INDEX IF NOT EXISTS idx_payment_orders_ext_tx ON payment_orders(external_transaction_id) WHERE external_transaction_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_feature_usages_user ON feature_usages(user_id, feature_key, period_key);
