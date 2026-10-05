package handler

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
	"kirim-chiqim-backend/internal/middleware"
	"kirim-chiqim-backend/internal/models"
	"kirim-chiqim-backend/internal/repository"
)

type BillingHandler struct {
	repo repository.Repository
}

func NewBillingHandler(repo repository.Repository) *BillingHandler {
	return &BillingHandler{repo: repo}
}

// 1. GET /api/v1/billing/plans
func (h *BillingHandler) GetPlans(w http.ResponseWriter, r *http.Request) {
	plans, err := h.repo.GetPlans(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Ta'rif rejalarini yuklab bo'lmadi")
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{"plans": plans})
}

// 2. GET /api/v1/billing/subscription
func (h *BillingHandler) GetSubscription(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Avtorizatsiyadan o'tilmagan")
		return
	}

	details, err := h.buildSubscriptionDetails(r.Context(), userID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Obuna ma'lumotlarini olishda xatolik")
		return
	}

	writeJSON(w, http.StatusOK, details)
}

// 3. POST /api/v1/billing/orders
func (h *BillingHandler) CreateOrder(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Avtorizatsiyadan o'tilmagan")
		return
	}

	var req models.CreateOrderRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Noto'g'ri so'rov formati")
		return
	}

	planID := strings.TrimSpace(req.PlanID)
	if planID == "" || planID == models.PlanIDFree {
		writeError(w, http.StatusBadRequest, "To'lovli tarif rejasini tanlang (masalan, pro)")
		return
	}

	plan, err := h.repo.GetPlanByID(r.Context(), planID)
	if err != nil {
		writeError(w, http.StatusNotFound, "Bunday tarif rejasi topilmadi")
		return
	}

	cycle := strings.ToLower(strings.TrimSpace(req.BillingCycle))
	if cycle != models.BillingCycleAnnual && cycle != models.BillingCycleMonthly {
		cycle = models.BillingCycleAnnual // default to annual with discount
	}

	amount := plan.MonthlyPrice
	if cycle == models.BillingCycleAnnual {
		amount = plan.AnnualPrice
	}

	method := strings.ToLower(strings.TrimSpace(req.PaymentMethod))
	if method == "" {
		method = models.PaymentMethodManual
	}

	orderID := uuid.New()
	now := time.Now()
	expiresAt := now.Add(24 * time.Hour) // 24 hours invoice validity

	order := &models.PaymentOrder{
		ID:            orderID,
		UserID:        userID,
		PlanID:        plan.ID,
		BillingCycle:  cycle,
		Amount:        amount,
		Currency:      plan.Currency,
		Status:        models.OrderStatusPending,
		PaymentMethod: method,
		ExpiresAt:     expiresAt,
		PaymentURL:    fmt.Sprintf("https://kirimchiqim.uz/pay/%s", orderID),
		BotDeepLink:   fmt.Sprintf("tg://resolve?domain=kirim_chiqim_bot&start=pay_%s", orderID),
		CreatedAt:     now,
		UpdatedAt:     now,
	}

	if err := h.repo.CreatePaymentOrder(r.Context(), order); err != nil {
		writeError(w, http.StatusInternalServerError, "To'lov buyurtmasini yaratib bo'lmadi")
		return
	}

	writeJSON(w, http.StatusCreated, order)
}

// 4. GET /api/v1/billing/orders/{id}
func (h *BillingHandler) GetOrder(w http.ResponseWriter, r *http.Request) {
	idStr := r.PathValue("id")
	orderID, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "Noto'g'ri buyurtma ID")
		return
	}

	order, err := h.repo.GetPaymentOrderByID(r.Context(), orderID)
	if err != nil {
		writeError(w, http.StatusNotFound, "To'lov buyurtmasi topilmadi")
		return
	}

	writeJSON(w, http.StatusOK, order)
}

// 5. POST /api/v1/billing/orders/{id}/confirm (Idempotent confirmation)
func (h *BillingHandler) ConfirmOrder(w http.ResponseWriter, r *http.Request) {
	idStr := r.PathValue("id")
	orderID, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "Noto'g'ri buyurtma ID")
		return
	}

	var req models.ConfirmOrderRequest
	_ = json.NewDecoder(r.Body).Decode(&req)

	order, err := h.repo.GetPaymentOrderByID(r.Context(), orderID)
	if err != nil {
		writeError(w, http.StatusNotFound, "To'lov buyurtmasi topilmadi")
		return
	}

	now := time.Now()

	// Idempotency: if order is already paid, do not re-apply duration
	if order.Status == models.OrderStatusPaid {
		details, _ := h.buildSubscriptionDetails(r.Context(), order.UserID)
		writeJSON(w, http.StatusOK, map[string]interface{}{
			"message":      "To'lov allaqachon tasdiqlangan (Idempotent)",
			"order":        order,
			"subscription": details,
		})
		return
	}

	if now.After(order.ExpiresAt) && order.Status == models.OrderStatusPending {
		order.Status = models.OrderStatusExpired
		_ = h.repo.UpdatePaymentOrder(r.Context(), order)
		writeError(w, http.StatusBadRequest, "To'lov buyurtmasining amal qilish muddati tugagan")
		return
	}

	// External transaction ID deduplication check
	extTx := strings.TrimSpace(req.ExternalTransactionID)
	if extTx == "" {
		extTx = fmt.Sprintf("tx_confirm_%s_%d", orderID.String()[:8], now.Unix())
	} else {
		if existing, err := h.repo.GetPaymentOrderByExternalTx(r.Context(), extTx); err == nil && existing != nil && existing.ID != orderID {
			writeError(w, http.StatusConflict, "Ushbu to'lov tranzaksiyasi boshqa buyurtmada ishlatilgan")
			return
		}
	}

	order.Status = models.OrderStatusPaid
	order.PaidAt = &now
	order.ExternalTransactionID = &extTx
	if req.PaymentMethod != "" {
		order.PaymentMethod = req.PaymentMethod
	}
	if req.Notes != "" {
		order.Notes = req.Notes
	}

	if err := h.repo.UpdatePaymentOrder(r.Context(), order); err != nil {
		writeError(w, http.StatusInternalServerError, "To'lov holatini yangilab bo'lmadi")
		return
	}

	// Activate Pro subscription
	durationDays := 30
	if order.BillingCycle == models.BillingCycleAnnual {
		durationDays = 365
	}
	periodEnd := now.AddDate(0, 0, durationDays)

	sub := &models.Subscription{
		UserID:             order.UserID,
		PlanID:             order.PlanID,
		Status:             models.SubscriptionStatusActive,
		BillingCycle:       order.BillingCycle,
		StartDate:          now,
		CurrentPeriodStart: now,
		CurrentPeriodEnd:   &periodEnd,
		UpdatedAt:          now,
	}

	if err := h.repo.UpsertSubscription(r.Context(), sub); err != nil {
		writeError(w, http.StatusInternalServerError, "Obunani faollashtirishda xatolik yuz berdi")
		return
	}

	details, _ := h.buildSubscriptionDetails(r.Context(), order.UserID)
	writeJSON(w, http.StatusOK, map[string]interface{}{
		"message":      "To'lov muvaffaqiyatli tasdiqlandi va Pro obuna faollashtirildi 🎉",
		"order":        order,
		"subscription": details,
	})
}

// 6. POST /api/v1/billing/cancel
func (h *BillingHandler) CancelSubscription(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Avtorizatsiyadan o'tilmagan")
		return
	}

	if err := h.repo.CancelSubscription(r.Context(), userID); err != nil {
		writeError(w, http.StatusInternalServerError, "Obunani bekor qilib bo'lmadi")
		return
	}

	details, _ := h.buildSubscriptionDetails(r.Context(), userID)
	writeJSON(w, http.StatusOK, map[string]interface{}{
		"message":      "Pro obuna bekor qilindi (Bepul reja faollashtirildi)",
		"subscription": details,
	})
}

// 7. POST /api/v1/billing/admin/subscriptions (Manual Admin activation)
func (h *BillingHandler) AdminSubscription(w http.ResponseWriter, r *http.Request) {
	var req models.AdminSubscriptionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Noto'g'ri ma'lumot")
		return
	}

	if req.UserID == uuid.Nil {
		writeError(w, http.StatusBadRequest, "Foydalanuvchi ID talab qilinadi")
		return
	}

	planID := req.PlanID
	if planID == "" {
		planID = models.PlanIDPro
	}

	days := req.DurationDays
	if days <= 0 {
		days = 30
	}

	now := time.Now()
	periodEnd := now.AddDate(0, 0, days)

	cycle := req.BillingCycle
	if cycle == "" {
		cycle = models.BillingCycleMonthly
	}

	sub := &models.Subscription{
		UserID:             req.UserID,
		PlanID:             planID,
		Status:             models.SubscriptionStatusActive,
		BillingCycle:       cycle,
		StartDate:          now,
		CurrentPeriodStart: now,
		CurrentPeriodEnd:   &periodEnd,
		UpdatedAt:          now,
	}

	if err := h.repo.UpsertSubscription(r.Context(), sub); err != nil {
		writeError(w, http.StatusInternalServerError, "Admin obunani saqlay olmadi")
		return
	}

	details, _ := h.buildSubscriptionDetails(r.Context(), req.UserID)
	writeJSON(w, http.StatusOK, map[string]interface{}{
		"message":      "Admin orqali obuna muvaffaqiyatli saqlandi",
		"subscription": details,
	})
}

// ============================================================
// PROTECTED PRO ACTIONS WITH FEATURE ENTITLEMENT & USAGE LIMITS
// ============================================================

// POST /api/v1/intelligence/what-if
func (h *BillingHandler) WhatIfSimulate(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Avtorizatsiyadan o'tilmagan")
		return
	}

	var body struct {
		PlannedExpense int64  `json:"plannedExpense"`
		Title          string `json:"title"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.PlannedExpense <= 0 {
		writeError(w, http.StatusBadRequest, "Rejalashtirilgan xarajat summasi kiritilishi shart")
		return
	}

	// 1. Check feature entitlement & enforce usage limit
	entitled, limit, currentUsage, periodKey, err := h.checkFeatureEntitlement(r.Context(), userID, models.FeatureWhatIfSimulator)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Ruxsat tekshirishda xatolik")
		return
	}

	if !entitled {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusForbidden)
		_ = json.NewEncoder(w).Encode(map[string]interface{}{
			"error":        "LIMIT_EXCEEDED",
			"message":      fmt.Sprintf("Oylik bepul xaridni hisoblash limitingiz tugadi (%d/%d). Cheksiz tahlillar uchun Pro tarifga o'ting.", currentUsage, limit),
			"featureKey":   models.FeatureWhatIfSimulator,
			"limit":        limit,
			"currentUsage": currentUsage,
			"upgradeUrl":   "/pricing",
		})
		return
	}

	// 2. Increment usage counter
	newUsage, _ := h.repo.IncrementFeatureUsage(r.Context(), userID, models.FeatureWhatIfSimulator, periodKey, 1)

	// 3. Compute real financial impact
	summary, _ := h.repo.GetDashboardSummary(r.Context(), userID)
	currentBalance := int64(0)
	remainingBudget := int64(0)
	if summary != nil {
		currentBalance = summary.Balance
		remainingBudget = summary.RemainingBudget
	}

	balanceAfter := currentBalance - body.PlannedExpense
	isAffordable := balanceAfter >= 0
	riskLevel := "low"
	if balanceAfter < 0 {
		riskLevel = "high"
	} else if remainingBudget > 0 && body.PlannedExpense > remainingBudget {
		riskLevel = "medium"
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"success":         true,
		"featureKey":      models.FeatureWhatIfSimulator,
		"currentUsage":    newUsage,
		"limit":           limit,
		"plannedExpense":  body.PlannedExpense,
		"currentBalance":  currentBalance,
		"balanceAfter":    balanceAfter,
		"remainingBudget": remainingBudget,
		"isAffordable":    isAffordable,
		"riskLevel":       riskLevel,
		"advice":          getWhatIfAdvice(riskLevel, balanceAfter),
	})
}

// POST /api/v1/reports/export
func (h *BillingHandler) ExportReport(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Avtorizatsiyadan o'tilmagan")
		return
	}

	entitled, limit, currentUsage, periodKey, err := h.checkFeatureEntitlement(r.Context(), userID, models.FeatureExportReports)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Ruxsat tekshirishda xatolik")
		return
	}

	if !entitled {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusForbidden)
		_ = json.NewEncoder(w).Encode(map[string]interface{}{
			"error":        "LIMIT_EXCEEDED",
			"message":      fmt.Sprintf("Oylik bepul eksport limitingiz tugadi (%d/%d). Cheksiz yuklab olish uchun Pro tarifga o'ting.", currentUsage, limit),
			"featureKey":   models.FeatureExportReports,
			"limit":        limit,
			"currentUsage": currentUsage,
			"upgradeUrl":   "/pricing",
		})
		return
	}

	newUsage, _ := h.repo.IncrementFeatureUsage(r.Context(), userID, models.FeatureExportReports, periodKey, 1)

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"success":      true,
		"featureKey":   models.FeatureExportReports,
		"currentUsage": newUsage,
		"limit":        limit,
		"message":      "Eksport muvaffaqiyatli ruxsat berildi",
	})
}

// GET /api/v1/intelligence/runway (Pro-only endpoint)
func (h *BillingHandler) GetRunwayForecast(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Avtorizatsiyadan o'tilmagan")
		return
	}

	entitled, _, _, _, _ := h.checkFeatureEntitlement(r.Context(), userID, models.FeatureRunwayForecast)
	if !entitled {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusForbidden)
		_ = json.NewEncoder(w).Encode(map[string]interface{}{
			"error":      "PRO_REQUIRED",
			"message":    "Mablag' yetish muddati prognozi faqat Pro tarifda ochiq.",
			"featureKey": models.FeatureRunwayForecast,
			"upgradeUrl": "/pricing",
		})
		return
	}

	summary, _ := h.repo.GetDashboardSummary(r.Context(), userID)
	daysRemaining := 30
	if summary != nil && summary.MonthExpense > 0 {
		dailyAvg := summary.MonthExpense / int64(time.Now().Day())
		if dailyAvg > 0 {
			daysRemaining = int(summary.Balance / dailyAvg)
			if daysRemaining < 0 {
				daysRemaining = 0
			}
		}
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"featureKey":    models.FeatureRunwayForecast,
		"isPro":         true,
		"daysRemaining": daysRemaining,
		"forecastDate":  time.Now().AddDate(0, 0, daysRemaining).Format("2006-01-02"),
	})
}

// ============================================================
// HELPER METHODS: ENTITLEMENT EVALUATION
// ============================================================

func (h *BillingHandler) buildSubscriptionDetails(ctx context.Context, userID uuid.UUID) (*models.SubscriptionDetailsResponse, error) {
	sub, plan, err := h.repo.GetUserSubscription(ctx, userID)
	if err != nil {
		return nil, err
	}

	isPro := plan.ID == models.PlanIDPro && sub.Status == models.SubscriptionStatusActive
	periodKey := time.Now().Format("2006-01")

	entitlements := make(map[string]models.Entitlement)

	// Features list
	features := []string{
		models.FeatureWhatIfSimulator,
		models.FeatureDailyBudgetBreakdown,
		models.FeatureRunwayForecast,
		models.FeatureExportReports,
		models.FeatureCloudSync,
	}

	for _, fk := range features {
		limit := getPlanFeatureLimit(plan.ID, fk, isPro)
		usage, _ := h.repo.GetFeatureUsage(ctx, userID, fk, periodKey)

		isEntitled := true
		remaining := -1

		if limit == 0 {
			isEntitled = false
			remaining = 0
		} else if limit > 0 {
			remaining = limit - usage
			if remaining <= 0 {
				remaining = 0
				isEntitled = false
			}
		}

		entitlements[fk] = models.Entitlement{
			FeatureKey:   fk,
			IsEntitled:   isEntitled,
			Limit:        limit,
			CurrentUsage: usage,
			Remaining:    remaining,
			Period:       periodKey,
		}
	}

	return &models.SubscriptionDetailsResponse{
		Plan:         *plan,
		Subscription: *sub,
		IsPro:        isPro,
		Entitlements: entitlements,
	}, nil
}

func (h *BillingHandler) checkFeatureEntitlement(ctx context.Context, userID uuid.UUID, featureKey string) (bool, int, int, string, error) {
	sub, plan, err := h.repo.GetUserSubscription(ctx, userID)
	if err != nil {
		return false, 0, 0, "", err
	}

	isPro := plan.ID == models.PlanIDPro && sub.Status == models.SubscriptionStatusActive
	periodKey := time.Now().Format("2006-01")
	limit := getPlanFeatureLimit(plan.ID, featureKey, isPro)

	if limit == -1 {
		// Unlimited
		usage, _ := h.repo.GetFeatureUsage(ctx, userID, featureKey, periodKey)
		return true, -1, usage, periodKey, nil
	}

	if limit == 0 {
		return false, 0, 0, periodKey, nil
	}

	usage, err := h.repo.GetFeatureUsage(ctx, userID, featureKey, periodKey)
	if err != nil {
		return false, limit, 0, periodKey, err
	}

	if usage >= limit {
		return false, limit, usage, periodKey, nil
	}

	return true, limit, usage, periodKey, nil
}

func getPlanFeatureLimit(planID, featureKey string, isPro bool) int {
	if isPro || planID == models.PlanIDPro {
		return -1 // Unlimited for Pro
	}

	// Free Plan Limits
	switch featureKey {
	case models.FeatureWhatIfSimulator:
		return 3 // 3 calculations per month
	case models.FeatureExportReports:
		return 2 // 2 CSV exports per month
	case models.FeatureRunwayForecast:
		return 0 // Locked on free plan
	case models.FeatureDailyBudgetBreakdown:
		return 5 // 5 daily breakdowns per month
	case models.FeatureCloudSync:
		return -1 // Basic cloud sync enabled
	default:
		return -1
	}
}

func getWhatIfAdvice(riskLevel string, balanceAfter int64) string {
	switch riskLevel {
	case "high":
		return "Ogohlantirish: Bu xarid byudjetingizni qizil chiziqqa tushiradi yoki qarzga kirishga majbur qiladi."
	case "medium":
		return "Ehtiyotkorlik: Bu xarid oylik toifaviy byudjetingiz chegarasidan oshib ketishi mumkin."
	default:
		return "Xavfsiz: Mavjud mablag'ingiz ushbu xaridni bemalol ko'tara oladi."
	}
}
