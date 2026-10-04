package handler_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"kirim-chiqim-backend/internal/handler"
	"kirim-chiqim-backend/internal/middleware"
	"kirim-chiqim-backend/internal/models"
	"kirim-chiqim-backend/internal/repository"
)

const testSecret = "test-secret-key-1234567890123456"

func setupTestApp() (*http.ServeMux, repository.Repository) {
	repo := repository.NewMemoryRepository()
	authH := handler.NewAuthHandler(repo, testSecret)
	txH := handler.NewTransactionHandler(repo)
	budgetH := handler.NewBudgetHandler(repo)
	debtH := handler.NewDebtHandler(repo)
	dashH := handler.NewDashboardHandler(repo)
	healthH := handler.NewHealthHandler()

	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", healthH.Health)
	mux.HandleFunc("POST /api/v1/auth/register", authH.Register)
	mux.HandleFunc("POST /api/v1/auth/login", authH.Login)

	protect := middleware.Auth(testSecret)
	mux.Handle("GET /api/v1/auth/me", protect(http.HandlerFunc(authH.Me)))
	mux.Handle("GET /api/v1/transactions", protect(http.HandlerFunc(txH.List)))
	mux.Handle("POST /api/v1/transactions", protect(http.HandlerFunc(txH.Create)))
	mux.Handle("GET /api/v1/transactions/{id}", protect(http.HandlerFunc(txH.Get)))
	mux.Handle("DELETE /api/v1/transactions/{id}", protect(http.HandlerFunc(txH.Delete)))
	mux.Handle("GET /api/v1/dashboard", protect(http.HandlerFunc(dashH.GetSummary)))
	mux.Handle("GET /api/v1/budget", protect(http.HandlerFunc(budgetH.Get)))
	mux.Handle("PUT /api/v1/budget", protect(http.HandlerFunc(budgetH.UpdateTotal)))
	mux.Handle("PUT /api/v1/budget/categories/{categoryId}", protect(http.HandlerFunc(budgetH.SetCategoryLimit)))
	mux.Handle("GET /api/v1/debts", protect(http.HandlerFunc(debtH.List)))
	mux.Handle("POST /api/v1/debts", protect(http.HandlerFunc(debtH.Create)))
	mux.Handle("POST /api/v1/debts/{id}/repay", protect(http.HandlerFunc(debtH.Repay)))

	return mux, repo
}

func TestHealthCheck(t *testing.T) {
	mux, _ := setupTestApp()
	req := httptest.NewRequest("GET", "/health", nil)
	rr := httptest.NewRecorder()
	mux.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", rr.Code)
	}

	var resp map[string]interface{}
	if err := json.Unmarshal(rr.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	if resp["status"] != "ok" {
		t.Errorf("expected status ok, got %v", resp["status"])
	}
}

func TestAuthFlow(t *testing.T) {
	mux, _ := setupTestApp()

	// 1. Register
	regPayload := handler.RegisterRequest{
		Email:    "test@example.com",
		Password: "password123",
		FullName: "Test User",
	}
	body, _ := json.Marshal(regPayload)
	req := httptest.NewRequest("POST", "/api/v1/auth/register", bytes.NewBuffer(body))
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	mux.ServeHTTP(rr, req)

	if rr.Code != http.StatusCreated {
		t.Fatalf("expected registration 201, got %d: %s", rr.Code, rr.Body.String())
	}

	var authResp handler.AuthResponse
	if err := json.Unmarshal(rr.Body.Bytes(), &authResp); err != nil {
		t.Fatalf("failed to decode auth response: %v", err)
	}
	if authResp.Token == "" {
		t.Fatal("expected non-empty token")
	}

	// 2. Access protected endpoint with token
	reqMe := httptest.NewRequest("GET", "/api/v1/auth/me", nil)
	reqMe.Header.Set("Authorization", "Bearer "+authResp.Token)
	rrMe := httptest.NewRecorder()
	mux.ServeHTTP(rrMe, reqMe)

	if rrMe.Code != http.StatusOK {
		t.Fatalf("expected status 200 on /me, got %d", rrMe.Code)
	}

	// 3. Access without token should be 401
	reqUnauth := httptest.NewRequest("GET", "/api/v1/auth/me", nil)
	rrUnauth := httptest.NewRecorder()
	mux.ServeHTTP(rrUnauth, reqUnauth)
	if rrUnauth.Code != http.StatusUnauthorized {
		t.Fatalf("expected status 401 on unauthenticated request, got %d", rrUnauth.Code)
	}
}

func TestTransactionAndDashboardIntegration(t *testing.T) {
	mux, _ := setupTestApp()

	// Register user
	regPayload := handler.RegisterRequest{Email: "txuser@example.com", Password: "password123", FullName: "Finance Tester"}
	body, _ := json.Marshal(regPayload)
	req := httptest.NewRequest("POST", "/api/v1/auth/register", bytes.NewBuffer(body))
	rr := httptest.NewRecorder()
	mux.ServeHTTP(rr, req)
	var authResp handler.AuthResponse
	_ = json.Unmarshal(rr.Body.Bytes(), &authResp)
	token := authResp.Token

	// 1. Create Income: 1,000,000 UZS
	incomePayload := handler.CreateTransactionRequest{
		CategoryID:      "salary",
		Title:           "Oylik maosh",
		Amount:          1000000,
		TransactionType: "income",
		TransactionDate: time.Now(),
	}
	incBody, _ := json.Marshal(incomePayload)
	reqInc := httptest.NewRequest("POST", "/api/v1/transactions", bytes.NewBuffer(incBody))
	reqInc.Header.Set("Authorization", "Bearer "+token)
	rrInc := httptest.NewRecorder()
	mux.ServeHTTP(rrInc, reqInc)

	if rrInc.Code != http.StatusCreated {
		t.Fatalf("expected status 201 on income, got %d: %s", rrInc.Code, rrInc.Body.String())
	}

	// 2. Create Expense: 150,000 UZS for food
	expPayload := handler.CreateTransactionRequest{
		CategoryID:      "food",
		Title:           "Supermarket",
		Amount:          150000,
		TransactionType: "expense",
		TransactionDate: time.Now(),
	}
	expBody, _ := json.Marshal(expPayload)
	reqExp := httptest.NewRequest("POST", "/api/v1/transactions", bytes.NewBuffer(expBody))
	reqExp.Header.Set("Authorization", "Bearer "+token)
	rrExp := httptest.NewRecorder()
	mux.ServeHTTP(rrExp, reqExp)

	if rrExp.Code != http.StatusCreated {
		t.Fatalf("expected status 201 on expense, got %d", rrExp.Code)
	}

	// 3. Verify Dashboard calculates real numbers
	reqDash := httptest.NewRequest("GET", "/api/v1/dashboard", nil)
	reqDash.Header.Set("Authorization", "Bearer "+token)
	rrDash := httptest.NewRecorder()
	mux.ServeHTTP(rrDash, reqDash)

	if rrDash.Code != http.StatusOK {
		t.Fatalf("expected status 200 on dashboard, got %d", rrDash.Code)
	}

	var dash models.DashboardSummary
	if err := json.Unmarshal(rrDash.Body.Bytes(), &dash); err != nil {
		t.Fatalf("failed to decode dashboard: %v", err)
	}

	if dash.TotalIncome != 1000000 {
		t.Errorf("expected total income 1,000,000, got %d", dash.TotalIncome)
	}
	if dash.TotalExpense != 150000 {
		t.Errorf("expected total expense 150,000, got %d", dash.TotalExpense)
	}
	expectedBalance := int64(1000000 - 150000)
	if dash.Balance != expectedBalance {
		t.Errorf("expected balance %d, got %d", expectedBalance, dash.Balance)
	}
	if dash.CategoryExpenses["food"] != 150000 {
		t.Errorf("expected food expense 150,000, got %d", dash.CategoryExpenses["food"])
	}
}

func TestSmetaCategoryLimitUpdate(t *testing.T) {
	mux, _ := setupTestApp()

	// Register user
	regPayload := handler.RegisterRequest{Email: "budget@example.com", Password: "password123", FullName: "Budget Tester"}
	body, _ := json.Marshal(regPayload)
	req := httptest.NewRequest("POST", "/api/v1/auth/register", bytes.NewBuffer(body))
	rr := httptest.NewRecorder()
	mux.ServeHTTP(rr, req)
	var authResp handler.AuthResponse
	_ = json.Unmarshal(rr.Body.Bytes(), &authResp)
	token := authResp.Token

	// Update category limit for "food" to 800,000 UZS
	limitPayload := handler.SetCategoryLimitRequest{
		CategoryID:  "food",
		LimitAmount: 800000,
	}
	lBody, _ := json.Marshal(limitPayload)
	reqLimit := httptest.NewRequest("PUT", "/api/v1/budget/categories/food", bytes.NewBuffer(lBody))
	reqLimit.Header.Set("Authorization", "Bearer "+token)
	rrLimit := httptest.NewRecorder()
	mux.ServeHTTP(rrLimit, reqLimit)

	if rrLimit.Code != http.StatusOK {
		t.Fatalf("expected status 200 on category limit update, got %d: %s", rrLimit.Code, rrLimit.Body.String())
	}

	var budget models.Budget
	if err := json.Unmarshal(rrLimit.Body.Bytes(), &budget); err != nil {
		t.Fatalf("failed to decode budget: %v", err)
	}

	found := false
	for _, cl := range budget.CategoryLimits {
		if cl.CategoryID == "food" && cl.LimitAmount == 800000 {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("expected category limit 800,000 for food in category limits, got %v", budget.CategoryLimits)
	}
}
