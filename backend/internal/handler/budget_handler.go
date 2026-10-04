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

type BudgetHandler struct {
	repo repository.Repository
}

func NewBudgetHandler(repo repository.Repository) *BudgetHandler {
	return &BudgetHandler{repo: repo}
}

type UpdateBudgetRequest struct {
	YearMonth         string      `json:"yearMonth"`
	TotalMonthlyLimit interface{} `json:"totalMonthlyLimit"`
	Limit             interface{} `json:"limit,omitempty"`
}

type SetCategoryLimitRequest struct {
	YearMonth   string      `json:"yearMonth"`
	CategoryID  string      `json:"categoryId"`
	LimitAmount interface{} `json:"limitAmount"`
	Limit       interface{} `json:"limit,omitempty"`
}

func (h *BudgetHandler) Get(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	yearMonth := r.URL.Query().Get("yearMonth")
	if yearMonth == "" {
		yearMonth = time.Now().Format("2006-01")
	}

	budget, err := h.repo.GetBudgetByMonth(r.Context(), userID, yearMonth)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to retrieve budget: "+err.Error())
		return
	}

	writeJSON(w, http.StatusOK, budget)
}

func (h *BudgetHandler) UpdateTotal(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req UpdateBudgetRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	totalLimit := parseAmountFlex(req.TotalMonthlyLimit)
	if totalLimit == 0 && req.Limit != nil {
		totalLimit = parseAmountFlex(req.Limit)
	}

	if req.YearMonth == "" {
		req.YearMonth = time.Now().Format("2006-01")
	}
	if totalLimit < 0 {
		writeError(w, http.StatusBadRequest, "Monthly limit cannot be negative")
		return
	}

	budget, err := h.repo.GetBudgetByMonth(r.Context(), userID, req.YearMonth)
	if err != nil {
		budget = &models.Budget{
			ID:        uuid.New(),
			UserID:    userID,
			YearMonth: req.YearMonth,
			IsActive:  true,
			CreatedAt: time.Now(),
		}
	}

	budget.TotalMonthlyLimit = totalLimit
	budget.UpdatedAt = time.Now()

	if err := h.repo.CreateOrUpdateBudget(r.Context(), budget); err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to update monthly budget limit")
		return
	}

	// Refetch with current spent calculations
	updated, _ := h.repo.GetBudgetByMonth(r.Context(), userID, req.YearMonth)
	writeJSON(w, http.StatusOK, updated)
}

func (h *BudgetHandler) SetCategoryLimit(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req SetCategoryLimitRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	pathCatID := r.PathValue("categoryId")
	if pathCatID != "" {
		req.CategoryID = pathCatID
	}

	limitAmt := parseAmountFlex(req.LimitAmount)
	if limitAmt == 0 && req.Limit != nil {
		limitAmt = parseAmountFlex(req.Limit)
	}

	if req.CategoryID == "" {
		writeError(w, http.StatusBadRequest, "Category ID is required")
		return
	}
	if limitAmt < 0 {
		writeError(w, http.StatusBadRequest, "Limit amount cannot be negative")
		return
	}
	if req.YearMonth == "" {
		req.YearMonth = time.Now().Format("2006-01")
	}

	budget, err := h.repo.GetBudgetByMonth(r.Context(), userID, req.YearMonth)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to load budget")
		return
	}

	if err := h.repo.SetCategoryLimit(r.Context(), userID, budget.ID, req.CategoryID, limitAmt); err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to save category limit")
		return
	}

	// Return updated budget
	updated, _ := h.repo.GetBudgetByMonth(r.Context(), userID, req.YearMonth)
	writeJSON(w, http.StatusOK, updated)
}
