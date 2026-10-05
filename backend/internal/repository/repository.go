package repository

import (
	"context"
	"time"

	"github.com/google/uuid"
	"kirim-chiqim-backend/internal/models"
)

type TransactionFilter struct {
	Type       string
	CategoryID string
	StartDate  *time.Time
	EndDate    *time.Time
	Limit      int
	Offset     int
}

type Repository interface {
	// User / Auth
	CreateUser(ctx context.Context, user *models.User) error
	EnsureUserExists(ctx context.Context, userID uuid.UUID, phone, fullName string) error
	GetUserByEmail(ctx context.Context, email string) (*models.User, error)
	GetUserByPhone(ctx context.Context, phone string) (*models.User, error)
	GetUserByID(ctx context.Context, id uuid.UUID) (*models.User, error)
	UpdateUser(ctx context.Context, user *models.User) error
	UpdateInitialBalance(ctx context.Context, userID uuid.UUID, amount int64) error
	DeleteUser(ctx context.Context, id uuid.UUID) error

	// Transactions
	CreateTransaction(ctx context.Context, tx *models.Transaction) error
	GetTransactionByID(ctx context.Context, userID, id uuid.UUID) (*models.Transaction, error)
	ListTransactions(ctx context.Context, userID uuid.UUID, filter TransactionFilter) ([]models.Transaction, error)
	UpdateTransaction(ctx context.Context, tx *models.Transaction) error
	DeleteTransaction(ctx context.Context, userID, id uuid.UUID) error

	// Budget ("Smeta")
	GetBudgetByMonth(ctx context.Context, userID uuid.UUID, yearMonth string) (*models.Budget, error)
	CreateOrUpdateBudget(ctx context.Context, budget *models.Budget) error
	SetCategoryLimit(ctx context.Context, userID, budgetID uuid.UUID, categoryID string, limitAmount int64) error

	// Debts ("Qarzlar")
	CreateDebt(ctx context.Context, debt *models.Debt) error
	GetDebtByID(ctx context.Context, userID, id uuid.UUID) (*models.Debt, error)
	ListDebts(ctx context.Context, userID uuid.UUID, debtType, status string) ([]models.Debt, error)
	UpdateDebt(ctx context.Context, debt *models.Debt) error
	DeleteDebt(ctx context.Context, userID, id uuid.UUID) error
	AddRepayment(ctx context.Context, userID, debtID uuid.UUID, amount int64, note string) error

	// Goals ("Jamg'arma")
	CreateGoal(ctx context.Context, goal *models.SavingsGoal) error
	GetGoalByID(ctx context.Context, userID, id uuid.UUID) (*models.SavingsGoal, error)
	ListGoals(ctx context.Context, userID uuid.UUID) ([]models.SavingsGoal, error)
	UpdateGoal(ctx context.Context, goal *models.SavingsGoal) error
	DeleteGoal(ctx context.Context, userID, id uuid.UUID) error
	AddGoalDeposit(ctx context.Context, userID, goalID uuid.UUID, amount int64) error

	// Dashboard & Stats
	GetDashboardSummary(ctx context.Context, userID uuid.UUID) (*models.DashboardSummary, error)
	GetStatistics(ctx context.Context, userID uuid.UUID, period string) (*models.StatisticsResponse, error)

	// Billing, Plans & Subscriptions
	GetPlans(ctx context.Context) ([]models.Plan, error)
	GetPlanByID(ctx context.Context, planID string) (*models.Plan, error)
	GetUserSubscription(ctx context.Context, userID uuid.UUID) (*models.Subscription, *models.Plan, error)
	UpsertSubscription(ctx context.Context, sub *models.Subscription) error
	CancelSubscription(ctx context.Context, userID uuid.UUID) error

	// Payment Orders
	CreatePaymentOrder(ctx context.Context, order *models.PaymentOrder) error
	GetPaymentOrderByID(ctx context.Context, orderID uuid.UUID) (*models.PaymentOrder, error)
	GetPaymentOrderByExternalTx(ctx context.Context, extTxID string) (*models.PaymentOrder, error)
	UpdatePaymentOrder(ctx context.Context, order *models.PaymentOrder) error
	ListUserPaymentOrders(ctx context.Context, userID uuid.UUID, limit int) ([]models.PaymentOrder, error)

	// Entitlements & Usage Tracking
	GetFeatureUsage(ctx context.Context, userID uuid.UUID, featureKey, periodKey string) (int, error)
	IncrementFeatureUsage(ctx context.Context, userID uuid.UUID, featureKey, periodKey string, amount int) (int, error)
}

