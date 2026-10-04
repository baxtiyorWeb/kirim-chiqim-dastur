package repository

import (
	"context"
	"fmt"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"kirim-chiqim-backend/internal/models"
)

type MemoryRepository struct {
	mu           sync.RWMutex
	users        map[uuid.UUID]*models.User
	transactions map[uuid.UUID]*models.Transaction
	budgets      map[string]*models.Budget // key: userID:yearMonth
	debts        map[uuid.UUID]*models.Debt
	goals        map[uuid.UUID]*models.SavingsGoal
}

func NewMemoryRepository() *MemoryRepository {
	return &MemoryRepository{
		users:        make(map[uuid.UUID]*models.User),
		transactions: make(map[uuid.UUID]*models.Transaction),
		budgets:      make(map[string]*models.Budget),
		debts:        make(map[uuid.UUID]*models.Debt),
		goals:        make(map[uuid.UUID]*models.SavingsGoal),
	}
}

// User
func (m *MemoryRepository) CreateUser(ctx context.Context, user *models.User) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	for _, u := range m.users {
		if user.Email != "" && u.Email == user.Email && u.DeletedAt == nil {
			return fmt.Errorf("user with email already exists")
		}
	}
	m.users[user.ID] = user
	return nil
}

func (m *MemoryRepository) GetUserByEmail(ctx context.Context, email string) (*models.User, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	for _, u := range m.users {
		if u.Email == email && u.DeletedAt == nil {
			copy := *u
			return &copy, nil
		}
	}
	return nil, ErrNotFound
}

func (m *MemoryRepository) GetUserByPhone(ctx context.Context, phone string) (*models.User, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	cleanPhone := strings.Map(func(r rune) rune {
		if r >= '0' && r <= '9' {
			return r
		}
		return -1
	}, phone)

	for _, u := range m.users {
		uClean := strings.Map(func(r rune) rune {
			if r >= '0' && r <= '9' {
				return r
			}
			return -1
		}, u.PhoneNumber)
		if (u.PhoneNumber == phone || (cleanPhone != "" && cleanPhone == uClean)) && u.DeletedAt == nil {
			copy := *u
			return &copy, nil
		}
	}
	return nil, ErrNotFound
}

func (m *MemoryRepository) GetUserByID(ctx context.Context, id uuid.UUID) (*models.User, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	u, ok := m.users[id]
	if !ok || u.DeletedAt != nil {
		return nil, ErrNotFound
	}
	copy := *u
	return &copy, nil
}

func (m *MemoryRepository) UpdateUser(ctx context.Context, user *models.User) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	u, ok := m.users[user.ID]
	if !ok || u.DeletedAt != nil {
		return ErrNotFound
	}
	u.FullName = user.FullName
	if user.Email != "" {
		u.Email = user.Email
	}
	if user.AvatarURL != "" {
		u.AvatarURL = user.AvatarURL
	}
	u.UpdatedAt = time.Now()
	return nil
}

func (m *MemoryRepository) DeleteUser(ctx context.Context, id uuid.UUID) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	u, ok := m.users[id]
	if !ok || u.DeletedAt != nil {
		return ErrNotFound
	}
	now := time.Now()
	u.DeletedAt = &now
	return nil
}

// Transactions
func (m *MemoryRepository) CreateTransaction(ctx context.Context, tx *models.Transaction) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	copy := *tx
	m.transactions[tx.ID] = &copy
	return nil
}

func (m *MemoryRepository) GetTransactionByID(ctx context.Context, userID, id uuid.UUID) (*models.Transaction, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	tx, ok := m.transactions[id]
	if !ok || tx.UserID != userID {
		return nil, ErrNotFound
	}
	copy := *tx
	return &copy, nil
}

func (m *MemoryRepository) ListTransactions(ctx context.Context, userID uuid.UUID, filter TransactionFilter) ([]models.Transaction, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	var result []models.Transaction
	for _, tx := range m.transactions {
		if tx.UserID != userID {
			continue
		}
		if filter.Type != "" && tx.TransactionType != filter.Type {
			continue
		}
		if filter.CategoryID != "" && tx.CategoryID != filter.CategoryID {
			continue
		}
		if filter.StartDate != nil && tx.TransactionDate.Before(*filter.StartDate) {
			continue
		}
		if filter.EndDate != nil && tx.TransactionDate.After(*filter.EndDate) {
			continue
		}
		result = append(result, *tx)
	}

	sort.Slice(result, func(i, j int) bool {
		return result[i].TransactionDate.After(result[j].TransactionDate)
	})

	if filter.Offset > 0 {
		if filter.Offset >= len(result) {
			return []models.Transaction{}, nil
		}
		result = result[filter.Offset:]
	}

	if filter.Limit > 0 && len(result) > filter.Limit {
		result = result[:filter.Limit]
	}

	return result, nil
}

func (m *MemoryRepository) UpdateTransaction(ctx context.Context, tx *models.Transaction) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	existing, ok := m.transactions[tx.ID]
	if !ok || existing.UserID != tx.UserID {
		return ErrNotFound
	}
	copy := *tx
	copy.UpdatedAt = time.Now()
	m.transactions[tx.ID] = &copy
	return nil
}

func (m *MemoryRepository) DeleteTransaction(ctx context.Context, userID, id uuid.UUID) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	existing, ok := m.transactions[id]
	if !ok || existing.UserID != userID {
		return ErrNotFound
	}
	delete(m.transactions, id)
	return nil
}

// Budget
func (m *MemoryRepository) GetBudgetByMonth(ctx context.Context, userID uuid.UUID, yearMonth string) (*models.Budget, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	key := fmt.Sprintf("%s:%s", userID, yearMonth)
	b, ok := m.budgets[key]
	if !ok {
		b = &models.Budget{
			ID:                uuid.New(),
			UserID:            userID,
			YearMonth:         yearMonth,
			TotalMonthlyLimit: 0,
			IsActive:          true,
			CreatedAt:         time.Now(),
			UpdatedAt:         time.Now(),
		}
		m.budgets[key] = b
	}

	// Recalculate spent
	var spent int64
	catSpent := make(map[string]int64)
	for _, tx := range m.transactions {
		if tx.UserID == userID && tx.TransactionType == "expense" && tx.TransactionDate.Format("2006-01") == yearMonth {
			spent += tx.Amount
			catSpent[tx.CategoryID] += tx.Amount
		}
	}
	b.SpentAmount = spent
	b.RemainingAmount = b.TotalMonthlyLimit - spent

	for i := range b.CategoryLimits {
		b.CategoryLimits[i].SpentAmount = catSpent[b.CategoryLimits[i].CategoryID]
	}

	copy := *b
	return &copy, nil
}

func (m *MemoryRepository) CreateOrUpdateBudget(ctx context.Context, budget *models.Budget) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	key := fmt.Sprintf("%s:%s", budget.UserID, budget.YearMonth)
	copy := *budget
	copy.UpdatedAt = time.Now()
	m.budgets[key] = &copy
	return nil
}

func (m *MemoryRepository) SetCategoryLimit(ctx context.Context, userID, budgetID uuid.UUID, categoryID string, limitAmount int64) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	var targetBudget *models.Budget
	for _, b := range m.budgets {
		if b.ID == budgetID && b.UserID == userID {
			targetBudget = b
			break
		}
	}
	if targetBudget == nil {
		return ErrNotFound
	}

	found := false
	for i, cl := range targetBudget.CategoryLimits {
		if cl.CategoryID == categoryID {
			targetBudget.CategoryLimits[i].LimitAmount = limitAmount
			found = true
			break
		}
	}
	if !found {
		targetBudget.CategoryLimits = append(targetBudget.CategoryLimits, models.BudgetCategoryLimit{
			ID:          uuid.New(),
			BudgetID:    budgetID,
			CategoryID:  categoryID,
			LimitAmount: limitAmount,
		})
	}
	targetBudget.UpdatedAt = time.Now()
	return nil
}

// Debts
func (m *MemoryRepository) CreateDebt(ctx context.Context, debt *models.Debt) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	copy := *debt
	m.debts[debt.ID] = &copy
	return nil
}

func (m *MemoryRepository) GetDebtByID(ctx context.Context, userID, id uuid.UUID) (*models.Debt, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	d, ok := m.debts[id]
	if !ok || d.UserID != userID {
		return nil, ErrNotFound
	}
	copy := *d
	return &copy, nil
}

func (m *MemoryRepository) ListDebts(ctx context.Context, userID uuid.UUID, debtType, status string) ([]models.Debt, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	var result []models.Debt
	for _, d := range m.debts {
		if d.UserID != userID {
			continue
		}
		if debtType != "" && d.DebtType != debtType {
			continue
		}
		if status != "" && d.Status != status {
			continue
		}
		result = append(result, *d)
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].CreatedAt.After(result[j].CreatedAt)
	})
	return result, nil
}

func (m *MemoryRepository) UpdateDebt(ctx context.Context, debt *models.Debt) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	existing, ok := m.debts[debt.ID]
	if !ok || existing.UserID != debt.UserID {
		return ErrNotFound
	}
	copy := *debt
	copy.UpdatedAt = time.Now()
	m.debts[debt.ID] = &copy
	return nil
}

func (m *MemoryRepository) DeleteDebt(ctx context.Context, userID, id uuid.UUID) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	existing, ok := m.debts[id]
	if !ok || existing.UserID != userID {
		return ErrNotFound
	}
	delete(m.debts, id)
	return nil
}

func (m *MemoryRepository) AddRepayment(ctx context.Context, userID, debtID uuid.UUID, amount int64, note string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	d, ok := m.debts[debtID]
	if !ok || d.UserID != userID {
		return ErrNotFound
	}

	d.PaidAmount += amount
	if d.PaidAmount >= d.Amount {
		d.PaidAmount = d.Amount
		d.Status = "returned"
	} else {
		d.Status = "partially_paid"
	}

	d.Repayments = append(d.Repayments, models.DebtRepayment{
		ID:          uuid.New(),
		DebtID:      debtID,
		Amount:      amount,
		PaymentDate: time.Now(),
		Note:        note,
		CreatedAt:   time.Now(),
	})
	d.UpdatedAt = time.Now()
	return nil
}

// Goals
func (m *MemoryRepository) CreateGoal(ctx context.Context, goal *models.SavingsGoal) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	copy := *goal
	m.goals[goal.ID] = &copy
	return nil
}

func (m *MemoryRepository) GetGoalByID(ctx context.Context, userID, id uuid.UUID) (*models.SavingsGoal, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	g, ok := m.goals[id]
	if !ok || g.UserID != userID {
		return nil, ErrNotFound
	}
	copy := *g
	return &copy, nil
}

func (m *MemoryRepository) ListGoals(ctx context.Context, userID uuid.UUID) ([]models.SavingsGoal, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	var result []models.SavingsGoal
	for _, g := range m.goals {
		if g.UserID == userID {
			result = append(result, *g)
		}
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].CreatedAt.After(result[j].CreatedAt)
	})
	return result, nil
}

func (m *MemoryRepository) UpdateGoal(ctx context.Context, goal *models.SavingsGoal) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	existing, ok := m.goals[goal.ID]
	if !ok || existing.UserID != goal.UserID {
		return ErrNotFound
	}
	copy := *goal
	copy.UpdatedAt = time.Now()
	m.goals[goal.ID] = &copy
	return nil
}

func (m *MemoryRepository) DeleteGoal(ctx context.Context, userID, id uuid.UUID) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	existing, ok := m.goals[id]
	if !ok || existing.UserID != userID {
		return ErrNotFound
	}
	delete(m.goals, id)
	return nil
}

func (m *MemoryRepository) AddGoalDeposit(ctx context.Context, userID, goalID uuid.UUID, amount int64) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	g, ok := m.goals[goalID]
	if !ok || g.UserID != userID {
		return ErrNotFound
	}
	g.CurrentAmount += amount
	if g.CurrentAmount >= g.TargetAmount {
		g.IsCompleted = true
	}
	g.UpdatedAt = time.Now()
	return nil
}

// Dashboard & Stats
func (m *MemoryRepository) GetDashboardSummary(ctx context.Context, userID uuid.UUID) (*models.DashboardSummary, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	summary := &models.DashboardSummary{
		CategoryExpenses: make(map[string]int64),
	}

	todayStr := time.Now().Format("2006-01-02")
	monthStr := time.Now().Format("2006-01")

	for _, tx := range m.transactions {
		if tx.UserID != userID {
			continue
		}
		if tx.TransactionType == "income" {
			summary.TotalIncome += tx.Amount
			if tx.TransactionDate.Format("2006-01-02") == todayStr {
				summary.TodayIncome += tx.Amount
			}
		} else if tx.TransactionType == "expense" {
			summary.TotalExpense += tx.Amount
			if tx.TransactionDate.Format("2006-01-02") == todayStr {
				summary.TodayExpense += tx.Amount
			}
			if tx.TransactionDate.Format("2006-01") == monthStr {
				summary.MonthExpense += tx.Amount
				summary.CategoryExpenses[tx.CategoryID] += tx.Amount
			}
		}
	}

	summary.Balance = summary.TotalIncome - summary.TotalExpense

	// Remaining budget
	key := fmt.Sprintf("%s:%s", userID, monthStr)
	if b, ok := m.budgets[key]; ok && b.TotalMonthlyLimit > 0 {
		rem := b.TotalMonthlyLimit - summary.MonthExpense
		if rem < 0 {
			rem = 0
		}
		summary.RemainingBudget = rem
	} else {
		summary.RemainingBudget = 0
	}

	// Recent transactions
	var list []models.Transaction
	for _, tx := range m.transactions {
		if tx.UserID == userID {
			list = append(list, *tx)
		}
	}
	sort.Slice(list, func(i, j int) bool {
		return list[i].TransactionDate.After(list[j].TransactionDate)
	})
	if len(list) > 10 {
		list = list[:10]
	}
	summary.RecentTransactions = list

	return summary, nil
}

func (m *MemoryRepository) GetStatistics(ctx context.Context, userID uuid.UUID, period string) (*models.StatisticsResponse, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	resp := &models.StatisticsResponse{Period: period}
	var startDate time.Time
	now := time.Now()
	switch period {
	case "weekly":
		startDate = now.AddDate(0, 0, -7)
	case "yearly":
		startDate = now.AddDate(-1, 0, 0)
	default:
		startDate = now.AddDate(0, -1, 0)
	}

	catExp := make(map[string]int64)
	for _, tx := range m.transactions {
		if tx.UserID != userID || tx.TransactionDate.Before(startDate) {
			continue
		}
		if tx.TransactionType == "income" {
			resp.TotalIncome += tx.Amount
		} else if tx.TransactionType == "expense" {
			resp.TotalExpense += tx.Amount
			catExp[tx.CategoryID] += tx.Amount
		}
	}
	resp.NetSavings = resp.TotalIncome - resp.TotalExpense

	for catID, total := range catExp {
		perc := 0.0
		if resp.TotalExpense > 0 {
			perc = float64(total) / float64(resp.TotalExpense) * 100
		}
		resp.CategoryExpenses = append(resp.CategoryExpenses, models.CategoryStat{
			CategoryID: catID,
			Total:      total,
			Percentage: perc,
		})
	}

	sort.Slice(resp.CategoryExpenses, func(i, j int) bool {
		return resp.CategoryExpenses[i].Total > resp.CategoryExpenses[j].Total
	})

	return resp, nil
}
