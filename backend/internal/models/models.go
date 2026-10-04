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
	Currency     string     `json:"currency"`
	IsActive     bool       `json:"isActive"`
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
	TotalIncome        int64            `json:"totalIncome"`
	TotalExpense       int64            `json:"totalExpense"`
	TodayIncome        int64            `json:"todayIncome"`
	TodayExpense       int64            `json:"todayExpense"`
	MonthExpense       int64            `json:"monthExpense"`
	RemainingBudget    int64            `json:"remainingBudget"`
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
