package handler

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"kirim-chiqim-backend/internal/middleware"
	"kirim-chiqim-backend/internal/models"
	"kirim-chiqim-backend/internal/repository"
)

type SyncHandler struct {
	repo repository.Repository
}

func NewSyncHandler(repo repository.Repository) *SyncHandler {
	return &SyncHandler{repo: repo}
}

// 1. POST /api/v1/sync/push (Client -> Server batch push)
func (h *SyncHandler) Push(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Avtorizatsiyadan o'tilmagan")
		return
	}

	// Strictly verify Pro Cloud Sync Entitlement on the server
	sub, plan, err := h.repo.GetUserSubscription(r.Context(), userID)
	if err != nil || plan.ID != models.PlanIDPro || sub.Status != models.SubscriptionStatusActive {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusForbidden)
		_ = json.NewEncoder(w).Encode(map[string]interface{}{
			"error":      "PRO_REQUIRED_FOR_CLOUD_SYNC",
			"message":    "Bulutli sinxronizatsiya faqat Pro tarifda mavjud. Bepul tarif faqat mahalliy xotirada (oflayn) ishlaydi.",
			"featureKey": models.FeatureCloudSync,
			"upgradeUrl": "/pricing",
		})
		return
	}

	var req models.SyncPushRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Noto'g'ri sinxronizatsiya paketi")
		return
	}

	processedCount := 0
	conflictsIgnored := 0

	// 1. Push Transactions
	for _, item := range req.Transactions {
		tx := &models.Transaction{
			ID:              item.ID,
			UserID:          userID,
			CategoryID:      item.CategoryID,
			Title:           item.Title,
			Amount:          item.Amount,
			TransactionType: item.TransactionType,
			TransactionDate: item.TransactionDate,
			Note:            item.Note,
			PaymentMethod:   item.PaymentMethod,
			PersonName:      item.PersonName,
			CreatedAt:       item.UpdatedAt,
			UpdatedAt:       item.UpdatedAt,
		}

		if item.DeletedAt != nil {
			_ = h.repo.DeleteTransaction(r.Context(), userID, item.ID)
			processedCount++
			continue
		}

		// Check if exists
		existing, err := h.repo.GetTransactionByID(r.Context(), userID, item.ID)
		if err == nil && existing != nil {
			// Conflict check: if server has newer update, skip or overwrite
			if existing.UpdatedAt.After(item.UpdatedAt) {
				conflictsIgnored++
				continue
			}
			_ = h.repo.UpdateTransaction(r.Context(), tx)
		} else {
			_ = h.repo.CreateTransaction(r.Context(), tx)
		}
		processedCount++
	}

	// 2. Push Debts
	for _, item := range req.Debts {
		debt := &models.Debt{
			ID:          item.ID,
			UserID:      userID,
			PersonName:  item.PersonName,
			PhoneNumber: item.PhoneNumber,
			Amount:      item.Amount,
			PaidAmount:  item.PaidAmount,
			DebtType:    item.DebtType,
			Status:      item.Status,
			DueDate:     item.DueDate,
			Note:        item.Note,
			CreatedAt:   item.UpdatedAt,
			UpdatedAt:   item.UpdatedAt,
		}

		if item.DeletedAt != nil {
			_ = h.repo.DeleteDebt(r.Context(), userID, item.ID)
			processedCount++
			continue
		}

		existing, err := h.repo.GetDebtByID(r.Context(), userID, item.ID)
		if err == nil && existing != nil {
			if existing.UpdatedAt.After(item.UpdatedAt) {
				conflictsIgnored++
				continue
			}
			_ = h.repo.UpdateDebt(r.Context(), debt)
		} else {
			_ = h.repo.CreateDebt(r.Context(), debt)
		}
		processedCount++
	}

	log.Printf("[SyncHandler] Push complete for user %s: processed=%d conflicts=%d\n",
		userID, processedCount, conflictsIgnored)

	writeJSON(w, http.StatusOK, models.SyncPushResponse{
		Success:          true,
		ProcessedCount:   processedCount,
		ServerTime:       time.Now(),
		ConflictsIgnored: conflictsIgnored,
	})
}

// 2. GET /api/v1/sync/pull (Server -> Client delta pull)
func (h *SyncHandler) Pull(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Avtorizatsiyadan o'tilmagan")
		return
	}

	// Strictly verify Pro Cloud Sync Entitlement on the server
	sub, plan, err := h.repo.GetUserSubscription(r.Context(), userID)
	if err != nil || plan.ID != models.PlanIDPro || sub.Status != models.SubscriptionStatusActive {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusForbidden)
		_ = json.NewEncoder(w).Encode(map[string]interface{}{
			"error":      "PRO_REQUIRED_FOR_CLOUD_SYNC",
			"message":    "Bulutli sinxronizatsiya faqat Pro tarifda mavjud. Bepul tarif faqat mahalliy xotirada (oflayn) ishlaydi.",
			"featureKey": models.FeatureCloudSync,
			"upgradeUrl": "/pricing",
		})
		return
	}

	txs, err := h.repo.ListTransactions(r.Context(), userID, repository.TransactionFilter{Limit: 1000})
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Tranzaksiyalarni olishda xatolik")
		return
	}

	debts, err := h.repo.ListDebts(r.Context(), userID, "", "")
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Qarzlarni olishda xatolik")
		return
	}

	writeJSON(w, http.StatusOK, models.SyncPullResponse{
		Transactions: txs,
		Debts:        debts,
		ServerTime:   time.Now(),
		Cursor:       fmt.Sprintf("%d", time.Now().UnixMilli()),
		HasMore:      false,
	})
}
