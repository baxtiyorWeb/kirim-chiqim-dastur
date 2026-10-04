package repository

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	_ "github.com/lib/pq"
	"kirim-chiqim-backend/internal/models"
)

var ErrNotFound = errors.New("resource not found")

type PostgresRepository struct {
	db *sql.DB
}

func NewPostgresRepository(db *sql.DB) *PostgresRepository {
	return &PostgresRepository{db: db}
}

// User / Auth
func (r *PostgresRepository) CreateUser(ctx context.Context, u *models.User) error {
	query := `
		INSERT INTO users (id, email, phone_number, password_hash, full_name, avatar_url, currency, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
	`
	var emailVal, phoneVal, avatarVal *string
	if strings.TrimSpace(u.Email) != "" {
		trimmed := strings.TrimSpace(strings.ToLower(u.Email))
		emailVal = &trimmed
	}
	if strings.TrimSpace(u.PhoneNumber) != "" {
		trimmed := strings.TrimSpace(u.PhoneNumber)
		phoneVal = &trimmed
	}
	if strings.TrimSpace(u.AvatarURL) != "" {
		trimmed := strings.TrimSpace(u.AvatarURL)
		avatarVal = &trimmed
	}

	_, err := r.db.ExecContext(ctx, query,
		u.ID, emailVal, phoneVal, u.PasswordHash, u.FullName, avatarVal, u.Currency, u.IsActive, u.CreatedAt, u.UpdatedAt,
	)
	return err
}

func (r *PostgresRepository) GetUserByEmail(ctx context.Context, email string) (*models.User, error) {
	query := `
		SELECT id, email, phone_number, password_hash, full_name, avatar_url, currency, is_active, created_at, updated_at
		FROM users
		WHERE LOWER(email) = LOWER($1) AND deleted_at IS NULL
	`
	u := &models.User{}
	var emailVal, phone, avatar sql.NullString
	err := r.db.QueryRowContext(ctx, query, email).Scan(
		&u.ID, &emailVal, &phone, &u.PasswordHash, &u.FullName, &avatar, &u.Currency, &u.IsActive, &u.CreatedAt, &u.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if emailVal.Valid {
		u.Email = emailVal.String
	}
	if phone.Valid {
		u.PhoneNumber = phone.String
	}
	if avatar.Valid {
		u.AvatarURL = avatar.String
	}
	return u, nil
}

func (r *PostgresRepository) GetUserByPhone(ctx context.Context, phone string) (*models.User, error) {
	// Clean digits for fuzzy matching (e.g. +998901234567 vs 901234567)
	digits := strings.Map(func(r rune) rune {
		if r >= '0' && r <= '9' {
			return r
		}
		return -1
	}, phone)

	query := `
		SELECT id, email, phone_number, password_hash, full_name, avatar_url, currency, is_active, created_at, updated_at
		FROM users
		WHERE (phone_number = $1 OR regexp_replace(COALESCE(phone_number, ''), '[^0-9]', '', 'g') = $2)
		  AND deleted_at IS NULL
		ORDER BY created_at DESC
		LIMIT 1
	`
	u := &models.User{}
	var emailVal, phoneVal, avatar sql.NullString
	err := r.db.QueryRowContext(ctx, query, phone, digits).Scan(
		&u.ID, &emailVal, &phoneVal, &u.PasswordHash, &u.FullName, &avatar, &u.Currency, &u.IsActive, &u.CreatedAt, &u.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if emailVal.Valid {
		u.Email = emailVal.String
	}
	if phoneVal.Valid {
		u.PhoneNumber = phoneVal.String
	}
	if avatar.Valid {
		u.AvatarURL = avatar.String
	}
	return u, nil
}

func (r *PostgresRepository) GetUserByID(ctx context.Context, id uuid.UUID) (*models.User, error) {
	query := `
		SELECT id, email, phone_number, password_hash, full_name, avatar_url, currency, is_active, created_at, updated_at
		FROM users
		WHERE id = $1 AND deleted_at IS NULL
	`
	u := &models.User{}
	var emailVal, phone, avatar sql.NullString
	err := r.db.QueryRowContext(ctx, query, id).Scan(
		&u.ID, &emailVal, &phone, &u.PasswordHash, &u.FullName, &avatar, &u.Currency, &u.IsActive, &u.CreatedAt, &u.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if emailVal.Valid {
		u.Email = emailVal.String
	}
	if phone.Valid {
		u.PhoneNumber = phone.String
	}
	if avatar.Valid {
		u.AvatarURL = avatar.String
	}
	return u, nil
}

func (r *PostgresRepository) UpdateUser(ctx context.Context, u *models.User) error {
	query := `
		UPDATE users
		SET full_name = $1, email = $2, avatar_url = $3, updated_at = NOW()
		WHERE id = $4 AND deleted_at IS NULL
	`
	var emailVal, avatarVal *string
	if strings.TrimSpace(u.Email) != "" {
		trimmed := strings.TrimSpace(strings.ToLower(u.Email))
		emailVal = &trimmed
	}
	if strings.TrimSpace(u.AvatarURL) != "" {
		trimmed := strings.TrimSpace(u.AvatarURL)
		avatarVal = &trimmed
	}
	_, err := r.db.ExecContext(ctx, query, u.FullName, emailVal, avatarVal, u.ID)
	return err
}

func (r *PostgresRepository) DeleteUser(ctx context.Context, id uuid.UUID) error {
	now := time.Now()
	query := `UPDATE users SET deleted_at = $1 WHERE id = $2`
	_, err := r.db.ExecContext(ctx, query, now, id)
	return err
}

// Transactions
func (r *PostgresRepository) CreateTransaction(ctx context.Context, tx *models.Transaction) error {
	query := `
		INSERT INTO transactions (id, user_id, category_id, title, amount, transaction_type, transaction_date, note, payment_method, is_recurring, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
	`
	_, err := r.db.ExecContext(ctx, query,
		tx.ID, tx.UserID, tx.CategoryID, tx.Title, tx.Amount, tx.TransactionType, tx.TransactionDate, tx.Note, tx.PaymentMethod, tx.IsRecurring, tx.CreatedAt, tx.UpdatedAt,
	)
	return err
}

func (r *PostgresRepository) GetTransactionByID(ctx context.Context, userID, id uuid.UUID) (*models.Transaction, error) {
	query := `
		SELECT id, user_id, category_id, title, amount, transaction_type, transaction_date, note, payment_method, is_recurring, created_at, updated_at
		FROM transactions
		WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
	`
	t := &models.Transaction{}
	var note sql.NullString
	err := r.db.QueryRowContext(ctx, query, id, userID).Scan(
		&t.ID, &t.UserID, &t.CategoryID, &t.Title, &t.Amount, &t.TransactionType, &t.TransactionDate, &note, &t.PaymentMethod, &t.IsRecurring, &t.CreatedAt, &t.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if note.Valid {
		t.Note = note.String
	}
	return t, nil
}

func (r *PostgresRepository) ListTransactions(ctx context.Context, userID uuid.UUID, filter TransactionFilter) ([]models.Transaction, error) {
	query := `
		SELECT id, user_id, category_id, title, amount, transaction_type, transaction_date, note, payment_method, is_recurring, created_at, updated_at
		FROM transactions
		WHERE user_id = $1 AND deleted_at IS NULL
	`
	args := []interface{}{userID}
	argIdx := 2

	if filter.Type != "" {
		query += fmt.Sprintf(" AND transaction_type = $%d", argIdx)
		args = append(args, filter.Type)
		argIdx++
	}
	if filter.CategoryID != "" {
		query += fmt.Sprintf(" AND category_id = $%d", argIdx)
		args = append(args, filter.CategoryID)
		argIdx++
	}
	if filter.StartDate != nil {
		query += fmt.Sprintf(" AND transaction_date >= $%d", argIdx)
		args = append(args, *filter.StartDate)
		argIdx++
	}
	if filter.EndDate != nil {
		query += fmt.Sprintf(" AND transaction_date <= $%d", argIdx)
		args = append(args, *filter.EndDate)
		argIdx++
	}

	query += " ORDER BY transaction_date DESC"

	if filter.Limit > 0 {
		query += fmt.Sprintf(" LIMIT $%d", argIdx)
		args = append(args, filter.Limit)
		argIdx++
	}
	if filter.Offset > 0 {
		query += fmt.Sprintf(" OFFSET $%d", argIdx)
		args = append(args, filter.Offset)
	}

	rows, err := r.db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []models.Transaction
	for rows.Next() {
		var t models.Transaction
		var note sql.NullString
		if err := rows.Scan(
			&t.ID, &t.UserID, &t.CategoryID, &t.Title, &t.Amount, &t.TransactionType, &t.TransactionDate, &note, &t.PaymentMethod, &t.IsRecurring, &t.CreatedAt, &t.UpdatedAt,
		); err != nil {
			return nil, err
		}
		if note.Valid {
			t.Note = note.String
		}
		list = append(list, t)
	}
	return list, rows.Err()
}

func (r *PostgresRepository) UpdateTransaction(ctx context.Context, tx *models.Transaction) error {
	query := `
		UPDATE transactions
		SET category_id = $1, title = $2, amount = $3, transaction_type = $4, transaction_date = $5, note = $6, payment_method = $7, updated_at = $8
		WHERE id = $9 AND user_id = $10 AND deleted_at IS NULL
	`
	res, err := r.db.ExecContext(ctx, query,
		tx.CategoryID, tx.Title, tx.Amount, tx.TransactionType, tx.TransactionDate, tx.Note, tx.PaymentMethod, time.Now(), tx.ID, tx.UserID,
	)
	if err != nil {
		return err
	}
	rows, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PostgresRepository) DeleteTransaction(ctx context.Context, userID, id uuid.UUID) error {
	query := `UPDATE transactions SET deleted_at = $1 WHERE id = $2 AND user_id = $3 AND deleted_at IS NULL`
	res, err := r.db.ExecContext(ctx, query, time.Now(), id, userID)
	if err != nil {
		return err
	}
	rows, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

// Budget ("Smeta")
func (r *PostgresRepository) GetBudgetByMonth(ctx context.Context, userID uuid.UUID, yearMonth string) (*models.Budget, error) {
	budgetQuery := `
		SELECT id, user_id, year_month, total_monthly_limit, is_active, created_at, updated_at
		FROM budgets
		WHERE user_id = $1 AND year_month = $2
	`
	b := &models.Budget{}
	err := r.db.QueryRowContext(ctx, budgetQuery, userID, yearMonth).Scan(
		&b.ID, &b.UserID, &b.YearMonth, &b.TotalMonthlyLimit, &b.IsActive, &b.CreatedAt, &b.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		// Create default budget record for this month
		b.ID = uuid.New()
		b.UserID = userID
		b.YearMonth = yearMonth
		b.TotalMonthlyLimit = 0 // Default 0 (no budget set until user configures it)
		b.IsActive = true
		b.CreatedAt = time.Now()
		b.UpdatedAt = time.Now()
		insertQ := `
			INSERT INTO budgets (id, user_id, year_month, total_monthly_limit, is_active, created_at, updated_at)
			VALUES ($1, $2, $3, $4, $5, $6, $7)
			ON CONFLICT (user_id, year_month) DO NOTHING
		`
		_, _ = r.db.ExecContext(ctx, insertQ, b.ID, b.UserID, b.YearMonth, b.TotalMonthlyLimit, b.IsActive, b.CreatedAt, b.UpdatedAt)
	} else if err != nil {
		return nil, err
	}

	// Calculate spent amount for the month
	spentQ := `
		SELECT COALESCE(SUM(amount), 0)
		FROM transactions
		WHERE user_id = $1 AND transaction_type = 'expense' AND deleted_at IS NULL
		AND TO_CHAR(transaction_date, 'YYYY-MM') = $2
	`
	_ = r.db.QueryRowContext(ctx, spentQ, userID, yearMonth).Scan(&b.SpentAmount)
	b.RemainingAmount = b.TotalMonthlyLimit - b.SpentAmount

	// Get category limits and spent amounts
	catLimitsQ := `
		SELECT bc.id, bc.budget_id, bc.category_id, bc.limit_amount,
		       COALESCE((
		           SELECT SUM(t.amount)
		           FROM transactions t
		           WHERE t.user_id = $1 AND t.category_id = bc.category_id
		             AND t.transaction_type = 'expense' AND t.deleted_at IS NULL
		             AND TO_CHAR(t.transaction_date, 'YYYY-MM') = $2
		       ), 0) as spent
		FROM budget_categories bc
		WHERE bc.budget_id = $3
	`
	rows, err := r.db.QueryContext(ctx, catLimitsQ, userID, yearMonth, b.ID)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var cl models.BudgetCategoryLimit
			if err := rows.Scan(&cl.ID, &cl.BudgetID, &cl.CategoryID, &cl.LimitAmount, &cl.SpentAmount); err == nil {
				b.CategoryLimits = append(b.CategoryLimits, cl)
			}
		}
	}

	return b, nil
}

func (r *PostgresRepository) CreateOrUpdateBudget(ctx context.Context, budget *models.Budget) error {
	query := `
		INSERT INTO budgets (id, user_id, year_month, total_monthly_limit, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		ON CONFLICT (user_id, year_month)
		DO UPDATE SET total_monthly_limit = EXCLUDED.total_monthly_limit, updated_at = EXCLUDED.updated_at
		RETURNING id
	`
	return r.db.QueryRowContext(ctx, query,
		budget.ID, budget.UserID, budget.YearMonth, budget.TotalMonthlyLimit, budget.IsActive, budget.CreatedAt, budget.UpdatedAt,
	).Scan(&budget.ID)
}

func (r *PostgresRepository) SetCategoryLimit(ctx context.Context, userID, budgetID uuid.UUID, categoryID string, limitAmount int64) error {
	// Verify budget ownership
	var exists bool
	checkQ := `SELECT true FROM budgets WHERE id = $1 AND user_id = $2`
	if err := r.db.QueryRowContext(ctx, checkQ, budgetID, userID).Scan(&exists); err != nil {
		return ErrNotFound
	}

	query := `
		INSERT INTO budget_categories (id, budget_id, category_id, limit_amount, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (budget_id, category_id)
		DO UPDATE SET limit_amount = EXCLUDED.limit_amount, updated_at = EXCLUDED.updated_at
	`
	now := time.Now()
	_, err := r.db.ExecContext(ctx, query, uuid.New(), budgetID, categoryID, limitAmount, now, now)
	return err
}

// Debts
func (r *PostgresRepository) CreateDebt(ctx context.Context, debt *models.Debt) error {
	query := `
		INSERT INTO debts (id, user_id, person_name, phone_number, amount, paid_amount, debt_type, status, due_date, note, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
	`
	_, err := r.db.ExecContext(ctx, query,
		debt.ID, debt.UserID, debt.PersonName, debt.PhoneNumber, debt.Amount, debt.PaidAmount, debt.DebtType, debt.Status, debt.DueDate, debt.Note, debt.CreatedAt, debt.UpdatedAt,
	)
	return err
}

func (r *PostgresRepository) GetDebtByID(ctx context.Context, userID, id uuid.UUID) (*models.Debt, error) {
	query := `
		SELECT id, user_id, person_name, phone_number, amount, paid_amount, debt_type, status, due_date, note, created_at, updated_at
		FROM debts
		WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
	`
	d := &models.Debt{}
	var phone, note sql.NullString
	err := r.db.QueryRowContext(ctx, query, id, userID).Scan(
		&d.ID, &d.UserID, &d.PersonName, &phone, &d.Amount, &d.PaidAmount, &d.DebtType, &d.Status, &d.DueDate, &note, &d.CreatedAt, &d.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if phone.Valid {
		d.PhoneNumber = phone.String
	}
	if note.Valid {
		d.Note = note.String
	}

	// Fetch repayments
	repQ := `SELECT id, debt_id, amount, payment_date, note, created_at FROM debt_payments WHERE debt_id = $1 ORDER BY payment_date DESC`
	rows, err := r.db.QueryContext(ctx, repQ, id)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var p models.DebtRepayment
			var pNote sql.NullString
			if err := rows.Scan(&p.ID, &p.DebtID, &p.Amount, &p.PaymentDate, &pNote, &p.CreatedAt); err == nil {
				if pNote.Valid {
					p.Note = pNote.String
				}
				d.Repayments = append(d.Repayments, p)
			}
		}
	}

	return d, nil
}

func (r *PostgresRepository) ListDebts(ctx context.Context, userID uuid.UUID, debtType, status string) ([]models.Debt, error) {
	query := `
		SELECT id, user_id, person_name, phone_number, amount, paid_amount, debt_type, status, due_date, note, created_at, updated_at
		FROM debts
		WHERE user_id = $1 AND deleted_at IS NULL
	`
	args := []interface{}{userID}
	argIdx := 2
	if debtType != "" {
		query += fmt.Sprintf(" AND debt_type = $%d", argIdx)
		args = append(args, debtType)
		argIdx++
	}
	if status != "" {
		query += fmt.Sprintf(" AND status = $%d", argIdx)
		args = append(args, status)
	}
	query += " ORDER BY created_at DESC"

	rows, err := r.db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []models.Debt
	for rows.Next() {
		var d models.Debt
		var phone, note sql.NullString
		if err := rows.Scan(
			&d.ID, &d.UserID, &d.PersonName, &phone, &d.Amount, &d.PaidAmount, &d.DebtType, &d.Status, &d.DueDate, &note, &d.CreatedAt, &d.UpdatedAt,
		); err != nil {
			return nil, err
		}
		if phone.Valid {
			d.PhoneNumber = phone.String
		}
		if note.Valid {
			d.Note = note.String
		}
		list = append(list, d)
	}
	return list, nil
}

func (r *PostgresRepository) UpdateDebt(ctx context.Context, debt *models.Debt) error {
	query := `
		UPDATE debts
		SET person_name = $1, phone_number = $2, amount = $3, debt_type = $4, status = $5, due_date = $6, note = $7, updated_at = $8
		WHERE id = $9 AND user_id = $10 AND deleted_at IS NULL
	`
	res, err := r.db.ExecContext(ctx, query,
		debt.PersonName, debt.PhoneNumber, debt.Amount, debt.DebtType, debt.Status, debt.DueDate, debt.Note, time.Now(), debt.ID, debt.UserID,
	)
	if err != nil {
		return err
	}
	rows, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PostgresRepository) DeleteDebt(ctx context.Context, userID, id uuid.UUID) error {
	query := `UPDATE debts SET deleted_at = $1 WHERE id = $2 AND user_id = $3 AND deleted_at IS NULL`
	res, err := r.db.ExecContext(ctx, query, time.Now(), id, userID)
	if err != nil {
		return err
	}
	rows, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PostgresRepository) AddRepayment(ctx context.Context, userID, debtID uuid.UUID, amount int64, note string) error {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	// Get current debt
	var totalAmount, paidAmount int64
	var status string
	debtQ := `SELECT amount, paid_amount, status FROM debts WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL FOR UPDATE`
	if err := tx.QueryRowContext(ctx, debtQ, debtID, userID).Scan(&totalAmount, &paidAmount, &status); err != nil {
		return ErrNotFound
	}

	newPaid := paidAmount + amount
	newStatus := "partially_paid"
	if newPaid >= totalAmount {
		newPaid = totalAmount
		newStatus = "returned"
	}

	// Insert repayment record
	payQ := `INSERT INTO debt_payments (id, debt_id, amount, payment_date, note, created_at) VALUES ($1, $2, $3, $4, $5, $6)`
	now := time.Now()
	if _, err := tx.ExecContext(ctx, payQ, uuid.New(), debtID, amount, now, note, now); err != nil {
		return err
	}

	// Update debt
	updateQ := `UPDATE debts SET paid_amount = $1, status = $2, updated_at = $3 WHERE id = $4`
	if _, err := tx.ExecContext(ctx, updateQ, newPaid, newStatus, now, debtID); err != nil {
		return err
	}

	return tx.Commit()
}

// Goals ("Jamg'arma")
func (r *PostgresRepository) CreateGoal(ctx context.Context, goal *models.SavingsGoal) error {
	query := `
		INSERT INTO savings_goals (id, user_id, title, target_amount, current_amount, deadline, emoji, is_completed, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
	`
	_, err := r.db.ExecContext(ctx, query,
		goal.ID, goal.UserID, goal.Title, goal.TargetAmount, goal.CurrentAmount, goal.Deadline, goal.Emoji, goal.IsCompleted, goal.CreatedAt, goal.UpdatedAt,
	)
	return err
}

func (r *PostgresRepository) GetGoalByID(ctx context.Context, userID, id uuid.UUID) (*models.SavingsGoal, error) {
	query := `
		SELECT id, user_id, title, target_amount, current_amount, deadline, emoji, is_completed, created_at, updated_at
		FROM savings_goals
		WHERE id = $1 AND user_id = $2
	`
	g := &models.SavingsGoal{}
	err := r.db.QueryRowContext(ctx, query, id, userID).Scan(
		&g.ID, &g.UserID, &g.Title, &g.TargetAmount, &g.CurrentAmount, &g.Deadline, &g.Emoji, &g.IsCompleted, &g.CreatedAt, &g.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, ErrNotFound
	}
	return g, err
}

func (r *PostgresRepository) ListGoals(ctx context.Context, userID uuid.UUID) ([]models.SavingsGoal, error) {
	query := `
		SELECT id, user_id, title, target_amount, current_amount, deadline, emoji, is_completed, created_at, updated_at
		FROM savings_goals
		WHERE user_id = $1
		ORDER BY created_at DESC
	`
	rows, err := r.db.QueryContext(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []models.SavingsGoal
	for rows.Next() {
		var g models.SavingsGoal
		if err := rows.Scan(
			&g.ID, &g.UserID, &g.Title, &g.TargetAmount, &g.CurrentAmount, &g.Deadline, &g.Emoji, &g.IsCompleted, &g.CreatedAt, &g.UpdatedAt,
		); err != nil {
			return nil, err
		}
		list = append(list, g)
	}
	return list, nil
}

func (r *PostgresRepository) UpdateGoal(ctx context.Context, goal *models.SavingsGoal) error {
	query := `
		UPDATE savings_goals
		SET title = $1, target_amount = $2, deadline = $3, emoji = $4, is_completed = $5, updated_at = $6
		WHERE id = $7 AND user_id = $8
	`
	res, err := r.db.ExecContext(ctx, query,
		goal.Title, goal.TargetAmount, goal.Deadline, goal.Emoji, goal.IsCompleted, time.Now(), goal.ID, goal.UserID,
	)
	if err != nil {
		return err
	}
	rows, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PostgresRepository) DeleteGoal(ctx context.Context, userID, id uuid.UUID) error {
	query := `DELETE FROM savings_goals WHERE id = $1 AND user_id = $2`
	res, err := r.db.ExecContext(ctx, query, id, userID)
	if err != nil {
		return err
	}
	rows, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PostgresRepository) AddGoalDeposit(ctx context.Context, userID, goalID uuid.UUID, amount int64) error {
	query := `
		UPDATE savings_goals
		SET current_amount = current_amount + $1,
		    is_completed = CASE WHEN (current_amount + $1) >= target_amount THEN true ELSE is_completed END,
		    updated_at = $2
		WHERE id = $3 AND user_id = $4
	`
	res, err := r.db.ExecContext(ctx, query, amount, time.Now(), goalID, userID)
	if err != nil {
		return err
	}
	rows, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

// Dashboard & Statistics
func (r *PostgresRepository) GetDashboardSummary(ctx context.Context, userID uuid.UUID) (*models.DashboardSummary, error) {
	summary := &models.DashboardSummary{
		CategoryExpenses: make(map[string]int64),
	}

	now := time.Now()
	todayStr := now.Format("2006-01-02")
	monthStr := now.Format("2006-01")

	// Total income & expense
	qTotals := `
		SELECT
			COALESCE(SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END), 0) as total_inc,
			COALESCE(SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END), 0) as total_exp,
			COALESCE(SUM(CASE WHEN transaction_type = 'income' AND TO_CHAR(transaction_date, 'YYYY-MM-DD') = $2 THEN amount ELSE 0 END), 0) as today_inc,
			COALESCE(SUM(CASE WHEN transaction_type = 'expense' AND TO_CHAR(transaction_date, 'YYYY-MM-DD') = $2 THEN amount ELSE 0 END), 0) as today_exp,
			COALESCE(SUM(CASE WHEN transaction_type = 'expense' AND TO_CHAR(transaction_date, 'YYYY-MM') = $3 THEN amount ELSE 0 END), 0) as month_exp
		FROM transactions
		WHERE user_id = $1 AND deleted_at IS NULL
	`
	_ = r.db.QueryRowContext(ctx, qTotals, userID, todayStr, monthStr).Scan(
		&summary.TotalIncome, &summary.TotalExpense, &summary.TodayIncome, &summary.TodayExpense, &summary.MonthExpense,
	)
	summary.Balance = summary.TotalIncome - summary.TotalExpense

	// Monthly budget remaining
	budget, _ := r.GetBudgetByMonth(ctx, userID, monthStr)
	if budget != nil && budget.TotalMonthlyLimit > 0 {
		rem := budget.TotalMonthlyLimit - summary.MonthExpense
		if rem < 0 {
			rem = 0
		}
		summary.RemainingBudget = rem
	} else {
		summary.RemainingBudget = 0
	}

	// Category expense breakdown for the month
	qCat := `
		SELECT category_id, SUM(amount)
		FROM transactions
		WHERE user_id = $1 AND transaction_type = 'expense' AND deleted_at IS NULL AND TO_CHAR(transaction_date, 'YYYY-MM') = $2
		GROUP BY category_id
	`
	rowsCat, err := r.db.QueryContext(ctx, qCat, userID, monthStr)
	if err == nil {
		defer rowsCat.Close()
		for rowsCat.Next() {
			var catID string
			var sum int64
			if err := rowsCat.Scan(&catID, &sum); err == nil {
				summary.CategoryExpenses[catID] = sum
			}
		}
	}

	// Recent transactions
	recent, _ := r.ListTransactions(ctx, userID, TransactionFilter{Limit: 10})
	summary.RecentTransactions = recent

	return summary, nil
}

func (r *PostgresRepository) GetStatistics(ctx context.Context, userID uuid.UUID, period string) (*models.StatisticsResponse, error) {
	resp := &models.StatisticsResponse{
		Period: period,
	}

	now := time.Now()
	var startDate time.Time
	switch period {
	case "weekly":
		startDate = now.AddDate(0, 0, -7)
	case "yearly":
		startDate = now.AddDate(-1, 0, 0)
	default: // "monthly"
		startDate = now.AddDate(0, -1, 0)
	}

	qTotals := `
		SELECT
			COALESCE(SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END), 0),
			COALESCE(SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END), 0)
		FROM transactions
		WHERE user_id = $1 AND deleted_at IS NULL AND transaction_date >= $2
	`
	_ = r.db.QueryRowContext(ctx, qTotals, userID, startDate).Scan(&resp.TotalIncome, &resp.TotalExpense)
	resp.NetSavings = resp.TotalIncome - resp.TotalExpense

	// Category breakdown for expenses
	qCatExp := `
		SELECT category_id, SUM(amount)
		FROM transactions
		WHERE user_id = $1 AND transaction_type = 'expense' AND deleted_at IS NULL AND transaction_date >= $2
		GROUP BY category_id
		ORDER BY SUM(amount) DESC
	`
	rowsExp, err := r.db.QueryContext(ctx, qCatExp, userID, startDate)
	if err == nil {
		defer rowsExp.Close()
		for rowsExp.Next() {
			var cat models.CategoryStat
			if err := rowsExp.Scan(&cat.CategoryID, &cat.Total); err == nil {
				if resp.TotalExpense > 0 {
					cat.Percentage = float64(cat.Total) / float64(resp.TotalExpense) * 100
				}
				resp.CategoryExpenses = append(resp.CategoryExpenses, cat)
			}
		}
	}

	return resp, nil
}
