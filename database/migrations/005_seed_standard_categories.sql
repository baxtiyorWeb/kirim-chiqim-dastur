-- Migration: 005_seed_standard_categories.sql
-- Description: Seed default global categories so any fresh database / restore has valid foreign keys

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
