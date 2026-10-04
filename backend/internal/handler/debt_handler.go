package handler

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/google/uuid"
	"kirim-chiqim-backend/internal/middleware"
	"kirim-chiqim-backend/internal/models"
	"kirim-chiqim-backend/internal/repository"
)

type DebtHandler struct {
	repo repository.Repository
}

func NewDebtHandler(repo repository.Repository) *DebtHandler {
	return &DebtHandler{repo: repo}
}

type CreateDebtRequest struct {
	PersonName  string     `json:"personName"`
	PhoneNumber string     `json:"phoneNumber,omitempty"`
	Amount      int64      `json:"amount"`
	DebtType    string     `json:"debtType"` // "borrowed" or "lent"
	DueDate     *time.Time `json:"dueDate,omitempty"`
	Note        string     `json:"note,omitempty"`
}

type RepayDebtRequest struct {
	Amount int64  `json:"amount"`
	Note   string `json:"note,omitempty"`
}

func (h *DebtHandler) Create(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req CreateDebtRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	if req.PersonName == "" {
		writeError(w, http.StatusBadRequest, "Person name is required")
		return
	}
	if req.Amount <= 0 {
		writeError(w, http.StatusBadRequest, "Debt amount must be greater than zero")
		return
	}
	if req.DebtType != "borrowed" && req.DebtType != "lent" {
		req.DebtType = "lent"
	}

	debt := &models.Debt{
		ID:          uuid.New(),
		UserID:      userID,
		PersonName:  req.PersonName,
		PhoneNumber: req.PhoneNumber,
		Amount:      req.Amount,
		PaidAmount:  0,
		DebtType:    req.DebtType,
		Status:      "active",
		DueDate:     req.DueDate,
		Note:        req.Note,
		Repayments:  []models.DebtRepayment{},
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	if err := h.repo.CreateDebt(r.Context(), debt); err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to create debt record")
		return
	}

	writeJSON(w, http.StatusCreated, debt)
}

func (h *DebtHandler) List(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	debtType := r.URL.Query().Get("type")
	status := r.URL.Query().Get("status")

	debts, err := h.repo.ListDebts(r.Context(), userID, debtType, status)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to retrieve debts")
		return
	}

	if debts == nil {
		debts = []models.Debt{}
	}

	writeJSON(w, http.StatusOK, debts)
}

func (h *DebtHandler) Get(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	idStr := r.PathValue("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "Invalid debt ID")
		return
	}

	debt, err := h.repo.GetDebtByID(r.Context(), userID, id)
	if err != nil {
		writeError(w, http.StatusNotFound, "Debt not found")
		return
	}

	writeJSON(w, http.StatusOK, debt)
}

func (h *DebtHandler) Repay(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	idStr := r.PathValue("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "Invalid debt ID")
		return
	}

	var req RepayDebtRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	if req.Amount <= 0 {
		writeError(w, http.StatusBadRequest, "Repayment amount must be positive")
		return
	}

	if err := h.repo.AddRepayment(r.Context(), userID, id, req.Amount, req.Note); err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to record repayment")
		return
	}

	updated, err := h.repo.GetDebtByID(r.Context(), userID, id)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Repayment recorded but failed to fetch updated debt")
		return
	}

	writeJSON(w, http.StatusOK, updated)
}

func (h *DebtHandler) Delete(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	idStr := r.PathValue("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "Invalid debt ID")
		return
	}

	if err := h.repo.DeleteDebt(r.Context(), userID, id); err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to delete debt record")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "Debt record deleted successfully"})
}
