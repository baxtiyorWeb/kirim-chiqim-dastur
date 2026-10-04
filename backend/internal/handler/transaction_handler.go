package handler

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"kirim-chiqim-backend/internal/middleware"
	"kirim-chiqim-backend/internal/models"
	"kirim-chiqim-backend/internal/repository"
)

type TransactionHandler struct {
	repo repository.Repository
}

func NewTransactionHandler(repo repository.Repository) *TransactionHandler {
	return &TransactionHandler{repo: repo}
}

type CreateTransactionRequest struct {
	CategoryID      string    `json:"categoryId"`
	Title           string    `json:"title"`
	Amount          int64     `json:"amount"`
	TransactionType string    `json:"transactionType"` // "expense" or "income"
	TransactionDate time.Time `json:"transactionDate"`
	Note            string    `json:"note,omitempty"`
	PaymentMethod   string    `json:"paymentMethod,omitempty"`
	PersonName      string    `json:"personName,omitempty"`
	IsRecurring     bool      `json:"isRecurring,omitempty"`
}

func (h *TransactionHandler) Create(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req CreateTransactionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	if req.Amount <= 0 {
		writeError(w, http.StatusBadRequest, "Amount must be greater than zero")
		return
	}
	if req.CategoryID == "" {
		writeError(w, http.StatusBadRequest, "Category ID is required")
		return
	}
	if req.Title == "" {
		writeError(w, http.StatusBadRequest, "Title is required")
		return
	}

	txType := strings.ToLower(req.TransactionType)
	if txType != "income" && txType != "expense" {
		txType = "expense"
	}

	if req.TransactionDate.IsZero() {
		req.TransactionDate = time.Now()
	}

	paymentMethod := req.PaymentMethod
	if paymentMethod == "" {
		paymentMethod = "cash"
	}

	tx := &models.Transaction{
		ID:              uuid.New(),
		UserID:          userID,
		CategoryID:      req.CategoryID,
		Title:           req.Title,
		Amount:          req.Amount,
		TransactionType: txType,
		TransactionDate: req.TransactionDate,
		Note:            req.Note,
		PaymentMethod:   paymentMethod,
		PersonName:      req.PersonName,
		IsRecurring:     req.IsRecurring,
		CreatedAt:       time.Now(),
		UpdatedAt:       time.Now(),
	}

	if err := h.repo.CreateTransaction(r.Context(), tx); err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to persist transaction")
		return
	}

	writeJSON(w, http.StatusCreated, tx)
}

func (h *TransactionHandler) List(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	q := r.URL.Query()
	filter := repository.TransactionFilter{
		Type:       q.Get("type"),
		CategoryID: q.Get("categoryId"),
	}

	if limitStr := q.Get("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 {
			filter.Limit = l
		}
	}
	if offsetStr := q.Get("offset"); offsetStr != "" {
		if o, err := strconv.Atoi(offsetStr); err == nil && o >= 0 {
			filter.Offset = o
		}
	}

	if startStr := q.Get("startDate"); startStr != "" {
		if t, err := time.Parse(time.RFC3339, startStr); err == nil {
			filter.StartDate = &t
		}
	}
	if endStr := q.Get("endDate"); endStr != "" {
		if t, err := time.Parse(time.RFC3339, endStr); err == nil {
			filter.EndDate = &t
		}
	}

	transactions, err := h.repo.ListTransactions(r.Context(), userID, filter)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to retrieve transactions")
		return
	}

	if transactions == nil {
		transactions = []models.Transaction{}
	}

	writeJSON(w, http.StatusOK, transactions)
}

func (h *TransactionHandler) Get(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	idStr := r.PathValue("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "Invalid transaction ID")
		return
	}

	tx, err := h.repo.GetTransactionByID(r.Context(), userID, id)
	if err != nil {
		writeError(w, http.StatusNotFound, "Transaction not found")
		return
	}

	writeJSON(w, http.StatusOK, tx)
}

func (h *TransactionHandler) Update(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	idStr := r.PathValue("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "Invalid transaction ID")
		return
	}

	var req CreateTransactionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	tx := &models.Transaction{
		ID:              id,
		UserID:          userID,
		CategoryID:      req.CategoryID,
		Title:           req.Title,
		Amount:          req.Amount,
		TransactionType: req.TransactionType,
		TransactionDate: req.TransactionDate,
		Note:            req.Note,
		PaymentMethod:   req.PaymentMethod,
		PersonName:      req.PersonName,
		IsRecurring:     req.IsRecurring,
	}

	if err := h.repo.UpdateTransaction(r.Context(), tx); err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to update transaction")
		return
	}

	writeJSON(w, http.StatusOK, tx)
}

func (h *TransactionHandler) Delete(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	idStr := r.PathValue("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "Invalid transaction ID")
		return
	}

	if err := h.repo.DeleteTransaction(r.Context(), userID, id); err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to delete transaction")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "Transaction deleted successfully"})
}
