package handler

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"kirim-chiqim-backend/internal/middleware"
	"kirim-chiqim-backend/internal/models"
	"kirim-chiqim-backend/internal/repository"
)

func setupBillingTestServer(t *testing.T) (*repository.MemoryRepository, *BillingHandler, uuid.UUID) {
	repo := repository.NewMemoryRepository()
	h := NewBillingHandler(repo)
	userID := uuid.New()

	err := repo.CreateUser(context.Background(), &models.User{
		ID:             userID,
		FullName:       "Test User",
		Email:          "test@billing.uz",
		InitialBalance: 5000000,
		IsActive:       true,
		CreatedAt:      time.Now(),
		UpdatedAt:      time.Now(),
	})
	if err != nil {
		t.Fatalf("Failed to create user: %v", err)
	}

	return repo, h, userID
}

func addAuthContext(r *http.Request, userID uuid.UUID) *http.Request {
	ctx := context.WithValue(r.Context(), middleware.UserIDKey, userID)
	return r.WithContext(ctx)
}

func TestBillingPlans(t *testing.T) {
	_, h, _ := setupBillingTestServer(t)

	req := httptest.NewRequest("GET", "/api/v1/billing/plans", nil)
	w := httptest.NewRecorder()
	h.GetPlans(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", w.Code)
	}

	var res struct {
		Plans []models.Plan `json:"plans"`
	}
	if err := json.NewDecoder(w.Body).Decode(&res); err != nil {
		t.Fatalf("failed to decode: %v", err)
	}

	if len(res.Plans) < 2 {
		t.Fatalf("expected at least 2 plans (free, pro), got %d", len(res.Plans))
	}
}

func TestDefaultFreeSubscriptionAndLimits(t *testing.T) {
	_, h, userID := setupBillingTestServer(t)

	req := httptest.NewRequest("GET", "/api/v1/billing/subscription", nil)
	req = addAuthContext(req, userID)
	w := httptest.NewRecorder()
	h.GetSubscription(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", w.Code, w.Body.String())
	}

	var res models.SubscriptionDetailsResponse
	if err := json.NewDecoder(w.Body).Decode(&res); err != nil {
		t.Fatalf("decode error: %v", err)
	}

	if res.IsPro {
		t.Fatalf("expected new user to NOT be pro")
	}
	if res.Plan.ID != models.PlanIDFree {
		t.Fatalf("expected free plan, got %s", res.Plan.ID)
	}

	// Verify free limit for what_if_simulator is 3
	ent, ok := res.Entitlements[models.FeatureWhatIfSimulator]
	if !ok {
		t.Fatalf("missing entitlement for what_if_simulator")
	}
	if ent.Limit != 3 {
		t.Fatalf("expected limit 3 for what_if_simulator, got %d", ent.Limit)
	}
	if ent.CurrentUsage != 0 {
		t.Fatalf("expected 0 usage, got %d", ent.CurrentUsage)
	}
}

func TestWhatIfSimulatorLimitEnforcement(t *testing.T) {
	_, h, userID := setupBillingTestServer(t)

	// Free user is allowed 3 calculations
	for i := 1; i <= 3; i++ {
		body := `{"plannedExpense": 50000, "title": "Kiyim"}`
		req := httptest.NewRequest("POST", "/api/v1/intelligence/what-if", bytes.NewBufferString(body))
		req = addAuthContext(req, userID)
		w := httptest.NewRecorder()
		h.WhatIfSimulate(w, req)

		if w.Code != http.StatusOK {
			t.Fatalf("iteration %d: expected 200, got %d: %s", i, w.Code, w.Body.String())
		}
	}

	// 4th calculation must be rejected with HTTP 403 LIMIT_EXCEEDED
	body := `{"plannedExpense": 50000, "title": "Ortiqcha xarid"}`
	req := httptest.NewRequest("POST", "/api/v1/intelligence/what-if", bytes.NewBufferString(body))
	req = addAuthContext(req, userID)
	w := httptest.NewRecorder()
	h.WhatIfSimulate(w, req)

	if w.Code != http.StatusForbidden {
		t.Fatalf("expected 403 Forbidden for 4th usage, got %d: %s", w.Code, w.Body.String())
	}

	var errResp map[string]interface{}
	_ = json.NewDecoder(w.Body).Decode(&errResp)
	if errResp["error"] != "LIMIT_EXCEEDED" {
		t.Fatalf("expected LIMIT_EXCEEDED, got %v", errResp["error"])
	}
}

func TestPaymentOrderCreationAndConfirmationFlow(t *testing.T) {
	_, h, userID := setupBillingTestServer(t)

	// 1. Create Order for Pro Annual
	orderPayload := `{"planId": "pro", "billingCycle": "annual", "paymentMethod": "telegram"}`
	req := httptest.NewRequest("POST", "/api/v1/billing/orders", bytes.NewBufferString(orderPayload))
	req = addAuthContext(req, userID)
	w := httptest.NewRecorder()
	h.CreateOrder(w, req)

	if w.Code != http.StatusCreated {
		t.Fatalf("expected 201 Created, got %d: %s", w.Code, w.Body.String())
	}

	var order models.PaymentOrder
	if err := json.NewDecoder(w.Body).Decode(&order); err != nil {
		t.Fatalf("decode order error: %v", err)
	}

	if order.Status != models.OrderStatusPending {
		t.Fatalf("expected status pending, got %s", order.Status)
	}
	if order.Amount != 149000 {
		t.Fatalf("expected amount 149000 UZS, got %d", order.Amount)
	}

	// 2. Confirm Order
	confirmPayload := `{"externalTransactionId": "tg_charge_99890", "paymentMethod": "telegram", "notes": "Paid via bot"}`
	confirmReq := httptest.NewRequest("POST", fmt.Sprintf("/api/v1/billing/orders/%s/confirm", order.ID), bytes.NewBufferString(confirmPayload))
	confirmReq.SetPathValue("id", order.ID.String())
	wConfirm := httptest.NewRecorder()
	h.ConfirmOrder(wConfirm, confirmReq)

	if wConfirm.Code != http.StatusOK {
		t.Fatalf("expected 200 OK on confirm, got %d: %s", wConfirm.Code, wConfirm.Body.String())
	}

	// 3. Verify user is now Pro with unlimited calculations
	subReq := httptest.NewRequest("GET", "/api/v1/billing/subscription", nil)
	subReq = addAuthContext(subReq, userID)
	wSub := httptest.NewRecorder()
	h.GetSubscription(wSub, subReq)

	var subDetails models.SubscriptionDetailsResponse
	_ = json.NewDecoder(wSub.Body).Decode(&subDetails)
	if !subDetails.IsPro {
		t.Fatalf("expected user to be Pro after payment confirmation")
	}

	ent := subDetails.Entitlements[models.FeatureWhatIfSimulator]
	if ent.Limit != -1 {
		t.Fatalf("expected unlimited (-1) limit for Pro user, got %d", ent.Limit)
	}

	// 4. Test that user can now do more simulations without limit rejection
	for i := 0; i < 5; i++ {
		simReq := httptest.NewRequest("POST", "/api/v1/intelligence/what-if", bytes.NewBufferString(`{"plannedExpense": 20000}`))
		simReq = addAuthContext(simReq, userID)
		wSim := httptest.NewRecorder()
		h.WhatIfSimulate(wSim, simReq)
		if wSim.Code != http.StatusOK {
			t.Fatalf("pro user simulation failed: %d", wSim.Code)
		}
	}
}

func TestIdempotentOrderConfirmation(t *testing.T) {
	_, h, userID := setupBillingTestServer(t)

	// Create order
	req := httptest.NewRequest("POST", "/api/v1/billing/orders", bytes.NewBufferString(`{"planId": "pro", "billingCycle": "monthly"}`))
	req = addAuthContext(req, userID)
	w := httptest.NewRecorder()
	h.CreateOrder(w, req)

	var order models.PaymentOrder
	_ = json.NewDecoder(w.Body).Decode(&order)

	// First confirmation
	confirmReq1 := httptest.NewRequest("POST", fmt.Sprintf("/api/v1/billing/orders/%s/confirm", order.ID), bytes.NewBufferString(`{"externalTransactionId": "ext_tx_1"}`))
	confirmReq1.SetPathValue("id", order.ID.String())
	w1 := httptest.NewRecorder()
	h.ConfirmOrder(w1, confirmReq1)
	if w1.Code != http.StatusOK {
		t.Fatalf("first confirm failed: %d", w1.Code)
	}

	// Second confirmation (duplicate from bot/webhook)
	confirmReq2 := httptest.NewRequest("POST", fmt.Sprintf("/api/v1/billing/orders/%s/confirm", order.ID), bytes.NewBufferString(`{"externalTransactionId": "ext_tx_1"}`))
	confirmReq2.SetPathValue("id", order.ID.String())
	w2 := httptest.NewRecorder()
	h.ConfirmOrder(w2, confirmReq2)
	if w2.Code != http.StatusOK {
		t.Fatalf("duplicate confirm should succeed idempotently with 200, got: %d", w2.Code)
	}

	var dupRes map[string]interface{}
	_ = json.NewDecoder(w2.Body).Decode(&dupRes)
	if !strings.Contains(fmt.Sprintf("%v", dupRes["message"]), "allaqachon") {
		t.Fatalf("expected message mentioning already confirmed, got %v", dupRes["message"])
	}
}
