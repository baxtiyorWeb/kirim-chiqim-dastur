package models

import (
	"time"

	"github.com/google/uuid"
)

// User represents an authenticated application user
type User struct {
	ID           uuid.UUID  `json:"id"`
	Email        string     `json:"email"`
	PhoneNumber  string     `json:"phoneNumber,omitempty"`
	PasswordHash string     `json:"-"`
	FullName     string     `json:"fullName"`
	AvatarURL    string     `json:"avatarUrl,omitempty"`
	Currency       string     `json:"currency"`
	InitialBalance int64      `json:"initialBalance"`
	IsActive       bool       `json:"isActive"`
	CreatedAt    time.Time  `json:"createdAt"`
	UpdatedAt    time.Time  `json:"updatedAt"`
	DeletedAt    *time.Time `json:"deletedAt,omitempty"`
}

// Transaction represents a financial income or expense
type Transaction struct {
	ID              uuid.UUID  `json:"id"`
	UserID          uuid.UUID  `json:"userId"`
	AccountID       *uuid.UUID `json:"accountId,omitempty"`
	CategoryID      string     `json:"categoryId"`
	Title           string     `json:"title"`
	Amount          int64      `json:"amount"` // Exact integer Uzbek So'm (NUMERIC 18, 0)
	TransactionType string     `json:"transactionType"` // "expense", "income", "transfer"
	TransactionDate time.Time  `json:"transactionDate"`
	Note            string     `json:"note,omitempty"`
	PaymentMethod   string     `json:"paymentMethod"`
	PersonName      string     `json:"personName,omitempty"`
	DebtID          *uuid.UUID `json:"debtId,omitempty"`
	IsRecurring     bool       `json:"isRecurring"`
	CreatedAt       time.Time  `json:"createdAt"`
	UpdatedAt       time.Time  `json:"updatedAt"`
}

// Budget represents a monthly financial allocation ("Smeta")
type Budget struct {
	ID                uuid.UUID             `json:"id"`
	UserID            uuid.UUID             `json:"userId"`
	YearMonth         string                `json:"yearMonth"` // e.g. "2026-10"
	TotalMonthlyLimit int64                 `json:"totalMonthlyLimit"`
	SpentAmount       int64                 `json:"spentAmount"`
	RemainingAmount   int64                 `json:"remainingAmount"`
	CategoryLimits    []BudgetCategoryLimit `json:"categoryLimits"`
	IsActive          bool                  `json:"isActive"`
	CreatedAt         time.Time             `json:"createdAt"`
	UpdatedAt         time.Time             `json:"updatedAt"`
}

// BudgetCategoryLimit represents spending limit and actual spent per category
type BudgetCategoryLimit struct {
	ID          uuid.UUID `json:"id"`
	BudgetID    uuid.UUID `json:"budgetId"`
	CategoryID  string    `json:"categoryId"`
	LimitAmount int64     `json:"limitAmount"`
	SpentAmount int64     `json:"spentAmount"`
}

// Debt represents money borrowed or lent
type Debt struct {
	ID          uuid.UUID       `json:"id"`
	UserID      uuid.UUID       `json:"userId"`
	PersonName  string          `json:"personName"`
	PhoneNumber string          `json:"phoneNumber,omitempty"`
	Amount      int64           `json:"amount"`
	PaidAmount  int64           `json:"paidAmount"`
	DebtType    string          `json:"debtType"` // "borrowed" or "lent"
	Status      string          `json:"status"`   // "active", "partially_paid", "returned"
	DueDate     *time.Time      `json:"dueDate,omitempty"`
	Note        string          `json:"note,omitempty"`
	Repayments  []DebtRepayment `json:"repayments"`
	CreatedAt   time.Time       `json:"createdAt"`
	UpdatedAt   time.Time       `json:"updatedAt"`
}

// DebtRepayment represents an individual repayment towards a debt
type DebtRepayment struct {
	ID          uuid.UUID `json:"id"`
	DebtID      uuid.UUID `json:"debtId"`
	Amount      int64     `json:"amount"`
	PaymentDate time.Time `json:"paymentDate"`
	Note        string    `json:"note,omitempty"`
	CreatedAt   time.Time `json:"createdAt"`
}

// SavingsGoal represents a target financial reserve ("Jamg'arma")
type SavingsGoal struct {
	ID            uuid.UUID  `json:"id"`
	UserID        uuid.UUID  `json:"userId"`
	Title         string     `json:"title"`
	TargetAmount  int64      `json:"targetAmount"`
	CurrentAmount int64      `json:"currentAmount"`
	Deadline      *time.Time `json:"deadline,omitempty"`
	Emoji         string     `json:"emoji"`
	IsCompleted   bool       `json:"isCompleted"`
	CreatedAt     time.Time  `json:"createdAt"`
	UpdatedAt     time.Time  `json:"updatedAt"`
}

// DashboardSummary represents computed real-time financial stats
type DashboardSummary struct {
	Balance            int64            `json:"balance"`
	InitialBalance     int64            `json:"initialBalance"`
	TotalIncome        int64            `json:"totalIncome"`
	TotalExpense       int64            `json:"totalExpense"`
	TodayIncome        int64            `json:"todayIncome"`
	TodayExpense       int64            `json:"todayExpense"`
	MonthExpense       int64            `json:"monthExpense"`
	TotalMonthlyLimit  int64            `json:"totalMonthlyLimit"`
	RemainingBudget    int64            `json:"remainingBudget"`
	TotalBorrowed      int64            `json:"totalBorrowed"`
	RemainingBorrowed  int64            `json:"remainingBorrowed"`
	TotalLent          int64            `json:"totalLent"`
	RemainingLent      int64            `json:"remainingLent"`
	CategoryExpenses   map[string]int64 `json:"categoryExpenses"`
	RecentTransactions []Transaction    `json:"recentTransactions"`
}

// CategoryStat represents aggregate statistics for a category
type CategoryStat struct {
	CategoryID string  `json:"categoryId"`
	Total      int64   `json:"total"`
	Percentage float64 `json:"percentage"`
}

// StatisticsResponse contains period aggregations
type StatisticsResponse struct {
	Period           string         `json:"period"` // "weekly", "monthly", "yearly"
	TotalIncome      int64          `json:"totalIncome"`
	TotalExpense     int64          `json:"totalExpense"`
	NetSavings       int64          `json:"netSavings"`
	CategoryExpenses []CategoryStat `json:"categoryExpenses"`
	CategoryIncomes  []CategoryStat `json:"categoryIncomes"`
}

// ============================================================
// BILLING, PLANS, SUBSCRIPTIONS & ENTITLEMENTS
// ============================================================

const (
	PlanIDFree = "free"
	PlanIDPro  = "pro"

	SubscriptionStatusActive   = "active"
	SubscriptionStatusExpired  = "expired"
	SubscriptionStatusCanceled = "canceled"
	SubscriptionStatusTrialing = "trialing"

	BillingCycleNone     = "none"
	BillingCycleMonthly  = "monthly"
	BillingCycleAnnual   = "annual"
	BillingCycleLifetime = "lifetime"

	OrderStatusPending  = "pending"
	OrderStatusPaid     = "paid"
	OrderStatusFailed   = "failed"
	OrderStatusExpired  = "expired"
	OrderStatusCanceled = "canceled"

	PaymentMethodManual       = "manual"
	PaymentMethodTelegram     = "telegram"
	PaymentMethodLocal        = "local"
	PaymentMethodLocalClick   = "local_click"
	PaymentMethodLocalPayme   = "local_payme"
	PaymentMethodBankTransfer = "bank_transfer"

	FeatureWhatIfSimulator       = "what_if_simulator"
	FeatureDailyBudgetBreakdown  = "intelligence_daily_budget"
	FeatureRunwayForecast        = "runway_forecast"
	FeatureExportReports         = "export_reports"
	FeatureCloudSync             = "cloud_sync"
)

// Plan represents an available subscription tier
type Plan struct {
	ID           string    `json:"id"`
	Name         string    `json:"name"`
	Description  string    `json:"description"`
	MonthlyPrice int64     `json:"monthlyPrice"`
	AnnualPrice  int64     `json:"annualPrice"`
	Currency     string    `json:"currency"`
	IsActive     bool      `json:"isActive"`
	SortOrder    int       `json:"sortOrder"`
	CreatedAt    time.Time `json:"createdAt"`
	UpdatedAt    time.Time `json:"updatedAt"`
}

// Subscription represents a user's plan state and active period
type Subscription struct {
	ID                 uuid.UUID  `json:"id"`
	UserID             uuid.UUID  `json:"userId"`
	PlanID             string     `json:"planId"`
	Status             string     `json:"status"` // active, expired, canceled, trialing
	BillingCycle       string     `json:"billingCycle"` // none, monthly, annual, lifetime
	StartDate          time.Time  `json:"startDate"`
	CurrentPeriodStart time.Time  `json:"currentPeriodStart"`
	CurrentPeriodEnd   *time.Time `json:"currentPeriodEnd,omitempty"`
	CanceledAt         *time.Time `json:"canceledAt,omitempty"`
	CreatedAt          time.Time  `json:"createdAt"`
	UpdatedAt          time.Time  `json:"updatedAt"`
}

// PaymentOrder represents an individual checkout or payment invoice
type PaymentOrder struct {
	ID                    uuid.UUID  `json:"id"`
	UserID                uuid.UUID  `json:"userId"`
	PlanID                string     `json:"planId"`
	BillingCycle          string     `json:"billingCycle"` // monthly, annual
	Amount                int64      `json:"amount"`
	Currency              string     `json:"currency"`
	Status                string     `json:"status"` // pending, paid, failed, expired, canceled
	PaymentMethod         string     `json:"paymentMethod"`
	ExternalTransactionID *string    `json:"externalTransactionId,omitempty"`
	PaidAt                *time.Time `json:"paidAt,omitempty"`
	ExpiresAt             time.Time  `json:"expiresAt"`
	Notes                 string     `json:"notes,omitempty"`
	Metadata              string     `json:"metadata,omitempty"`
	PaymentURL            string     `json:"paymentUrl,omitempty"`
	BotDeepLink           string     `json:"botDeepLink,omitempty"`
	CreatedAt             time.Time  `json:"createdAt"`
	UpdatedAt             time.Time  `json:"updatedAt"`
}

// Entitlement defines whether a feature is permitted and what limits apply
type Entitlement struct {
	FeatureKey   string `json:"featureKey"`
	IsEntitled   bool   `json:"isEntitled"`
	Limit        int    `json:"limit"`        // -1 = unlimited, 0 = locked/disallowed, >0 = limit count
	CurrentUsage int    `json:"currentUsage"` // count used in current period
	Remaining    int    `json:"remaining"`    // -1 = unlimited, 0 = exhausted
	Period       string `json:"period"`       // e.g. "2026-10" or "lifetime"
}

// SubscriptionDetailsResponse provides a comprehensive subscription view
type SubscriptionDetailsResponse struct {
	Plan         Plan                   `json:"plan"`
	Subscription Subscription           `json:"subscription"`
	IsPro        bool                   `json:"isPro"`
	Entitlements map[string]Entitlement `json:"entitlements"`
}

// CreateOrderRequest is the payload to initialize a payment order
type CreateOrderRequest struct {
	PlanID        string `json:"planId"`
	BillingCycle  string `json:"billingCycle"` // monthly or annual
	PaymentMethod string `json:"paymentMethod"`
}

// ConfirmOrderRequest is used by backend, webhook or Telegram bot to confirm payment
type ConfirmOrderRequest struct {
	ExternalTransactionID string `json:"externalTransactionId"`
	PaymentMethod         string `json:"paymentMethod,omitempty"`
	Notes                 string `json:"notes,omitempty"`
}

// AdminSubscriptionRequest allows manual admin upgrade/grant
type AdminSubscriptionRequest struct {
	UserID       uuid.UUID `json:"userId"`
	PlanID       string    `json:"planId"`
	BillingCycle string    `json:"billingCycle"`
	DurationDays int       `json:"durationDays"`
}

