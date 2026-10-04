-- ============================================================
-- KIRIM-CHIQIM MOLIYA DASTURI: POSTGRESQL / NEON DATABASE SCHEMA
-- Authoritative Single Source of Truth
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. USERS TABLE
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE,
    phone_number VARCHAR(50) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    currency VARCHAR(10) NOT NULL DEFAULT 'UZS',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(LOWER(email)) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone_number) WHERE deleted_at IS NULL;

-- 2. CATEGORIES TABLE
CREATE TABLE IF NOT EXISTS categories (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category_type VARCHAR(20) NOT NULL DEFAULT 'expense',
    icon VARCHAR(100) NOT NULL,
    color VARCHAR(30) NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

DO $$
DECLARE
    r RECORD;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='categories' AND column_name='category_type') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='categories' AND column_name='type') THEN
            ALTER TABLE categories RENAME COLUMN type TO category_type;
        ELSE
            ALTER TABLE categories ADD COLUMN category_type VARCHAR(20) NOT NULL DEFAULT 'expense';
        END IF;
    END IF;

    -- Dynamically drop NOT NULL constraint from any existing legacy columns in categories table
    FOR r IN (
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'categories' 
          AND column_name NOT IN ('id', 'name')
          AND is_nullable = 'NO'
    ) LOOP
        EXECUTE 'ALTER TABLE categories ALTER COLUMN "' || r.column_name || '" DROP NOT NULL';
    END LOOP;

    ALTER TABLE categories ADD COLUMN IF NOT EXISTS icon VARCHAR(100) NOT NULL DEFAULT 'category';
    ALTER TABLE categories ADD COLUMN IF NOT EXISTS icon_name VARCHAR(100) DEFAULT 'category';
    ALTER TABLE categories ADD COLUMN IF NOT EXISTS color VARCHAR(30) NOT NULL DEFAULT '#FF6B6B';
    ALTER TABLE categories ADD COLUMN IF NOT EXISTS color_hex VARCHAR(30) DEFAULT '#FF6B6B';
    ALTER TABLE categories ADD COLUMN IF NOT EXISTS bg_color_hex VARCHAR(30) DEFAULT '#FFEAEA';
    ALTER TABLE categories ADD COLUMN IF NOT EXISTS is_default BOOLEAN NOT NULL DEFAULT TRUE;

    -- Reset any legacy dummy 5,000,000 budget limits
    UPDATE budgets SET total_monthly_limit = 0 WHERE total_monthly_limit = 5000000;
END $$;

-- Seed default categories if not present
INSERT INTO categories (id, name, category_type, icon, icon_name, color, color_hex, is_default) VALUES
    ('food', 'Oziq-ovqat', 'expense', 'restaurant', 'restaurant', '#FF6B6B', '#FF6B6B', TRUE),
    ('transport', 'Transport', 'expense', 'directions_car', 'directions_car', '#4D96FF', '#4D96FF', TRUE),
    ('utilities', 'Kommunal', 'expense', 'home', 'home', '#6BCB77', '#6BCB77', TRUE),
    ('entertainment', 'Ko''ngilochar', 'expense', 'sports_esports', 'sports_esports', '#FFD93D', '#FFD93D', TRUE),
    ('shopping', 'Xaridlar', 'expense', 'shopping_bag', 'shopping_bag', '#9B51E0', '#9B51E0', TRUE),
    ('health', 'Salomatlik', 'expense', 'medical_services', 'medical_services', '#FF8066', '#FF8066', TRUE),
    ('education', 'Ta''lim', 'expense', 'school', 'school', '#00C9A7', '#00C9A7', TRUE),
    ('other_expense', 'Boshqa', 'expense', 'more_horiz', 'more_horiz', '#84817A', '#84817A', TRUE),
    ('salary', 'Oylik maosh', 'income', 'payments', 'payments', '#2ECC71', '#2ECC71', TRUE),
    ('business', 'Biznes', 'income', 'store', 'store', '#3498DB', '#3498DB', TRUE),
    ('freelance', 'Frilans', 'income', 'laptop', 'laptop', '#9B59B6', '#9B59B6', TRUE),
    ('gift', 'Sovg''a', 'income', 'card_giftcard', 'card_giftcard', '#E67E22', '#E67E22', TRUE),
    ('other_income', 'Boshqa daromad', 'income', 'add_circle', 'add_circle', '#1ABC9C', '#1ABC9C', TRUE)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    category_type = EXCLUDED.category_type,
    icon = EXCLUDED.icon,
    icon_name = EXCLUDED.icon_name,
    color = EXCLUDED.color,
    color_hex = EXCLUDED.color_hex;

-- 3. TRANSACTIONS TABLE
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id VARCHAR(50) REFERENCES categories(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    amount BIGINT NOT NULL CHECK (amount > 0),
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('income', 'expense')),
    transaction_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    note TEXT,
    payment_method VARCHAR(50) NOT NULL DEFAULT 'cash',
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_tx_user_date ON transactions(user_id, transaction_date DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_tx_user_type ON transactions(user_id, transaction_type) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_tx_user_cat ON transactions(user_id, category_id) WHERE deleted_at IS NULL;

-- 4. BUDGETS TABLE (Oylik Smeta)
CREATE TABLE IF NOT EXISTS budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    year_month VARCHAR(7) NOT NULL, -- Format: YYYY-MM
    total_monthly_limit BIGINT NOT NULL DEFAULT 0 CHECK (total_monthly_limit >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_budget_user_month UNIQUE(user_id, year_month)
);

CREATE INDEX IF NOT EXISTS idx_budgets_user_month ON budgets(user_id, year_month);

-- 5. BUDGET CATEGORY LIMITS
CREATE TABLE IF NOT EXISTS budget_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    budget_id UUID NOT NULL REFERENCES budgets(id) ON DELETE CASCADE,
    category_id VARCHAR(50) NOT NULL,
    limit_amount BIGINT NOT NULL DEFAULT 0 CHECK (limit_amount >= 0),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_budget_cat UNIQUE(budget_id, category_id)
);

CREATE INDEX IF NOT EXISTS idx_budget_cat_budget ON budget_categories(budget_id);

-- 6. DEBTS TABLE (Qarz Daftari)
CREATE TABLE IF NOT EXISTS debts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    person_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(50),
    amount BIGINT NOT NULL CHECK (amount > 0),
    paid_amount BIGINT NOT NULL DEFAULT 0 CHECK (paid_amount >= 0),
    debt_type VARCHAR(20) NOT NULL CHECK (debt_type IN ('borrowed', 'lent')),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'partial', 'returned', 'overdue')),
    due_date TIMESTAMP WITH TIME ZONE,
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_debts_user_status ON debts(user_id, status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_debts_user_type ON debts(user_id, debt_type) WHERE deleted_at IS NULL;

-- 7. DEBT REPAYMENTS TABLE (To'lovlar tarixi)
CREATE TABLE IF NOT EXISTS debt_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    debt_id UUID NOT NULL REFERENCES debts(id) ON DELETE CASCADE,
    amount BIGINT NOT NULL CHECK (amount > 0),
    payment_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_debt_payments_debt ON debt_payments(debt_id, payment_date DESC);

-- 8. SAVINGS GOALS TABLE (Jamg'arma va Maqsadlar)
CREATE TABLE IF NOT EXISTS savings_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    target_amount BIGINT NOT NULL CHECK (target_amount > 0),
    current_amount BIGINT NOT NULL DEFAULT 0 CHECK (current_amount >= 0),
    deadline TIMESTAMP WITH TIME ZONE,
    emoji VARCHAR(20) NOT NULL DEFAULT '🎯',
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_goals_user ON savings_goals(user_id, created_at DESC);
