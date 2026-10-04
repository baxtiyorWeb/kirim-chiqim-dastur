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

type GoalHandler struct {
	repo repository.Repository
}

func NewGoalHandler(repo repository.Repository) *GoalHandler {
	return &GoalHandler{repo: repo}
}

type CreateGoalRequest struct {
	Title        string      `json:"title"`
	TargetAmount interface{} `json:"targetAmount"`
	Deadline     interface{} `json:"deadline,omitempty"`
	Emoji        string      `json:"emoji,omitempty"`
}

type DepositGoalRequest struct {
	Amount interface{} `json:"amount"`
}

func (h *GoalHandler) Create(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req CreateGoalRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	if req.Title == "" {
		writeError(w, http.StatusBadRequest, "Goal title is required")
		return
	}

	targetAmt := parseAmountFlex(req.TargetAmount)
	if targetAmt <= 0 {
		writeError(w, http.StatusBadRequest, "Target amount must be greater than zero")
		return
	}

	emoji := req.Emoji
	if emoji == "" {
		emoji = "🎯"
	}

	deadline := parseTimeFlex(req.Deadline)

	goal := &models.SavingsGoal{
		ID:            uuid.New(),
		UserID:        userID,
		Title:         req.Title,
		TargetAmount:  targetAmt,
		CurrentAmount: 0,
		Deadline:      deadline,
		Emoji:         emoji,
		IsCompleted:   false,
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	}

	if err := h.repo.CreateGoal(r.Context(), goal); err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to create savings goal")
		return
	}

	writeJSON(w, http.StatusCreated, goal)
}

func (h *GoalHandler) List(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	goals, err := h.repo.ListGoals(r.Context(), userID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to retrieve goals: "+err.Error())
		return
	}

	if goals == nil {
		goals = []models.SavingsGoal{}
	}

	writeJSON(w, http.StatusOK, goals)
}

func (h *GoalHandler) Deposit(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	idStr := r.PathValue("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "Invalid goal ID")
		return
	}

	var req DepositGoalRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	amt := parseAmountFlex(req.Amount)
	if amt <= 0 {
		writeError(w, http.StatusBadRequest, "Deposit amount must be positive")
		return
	}

	if err := h.repo.AddGoalDeposit(r.Context(), userID, id, amt); err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to deposit to savings goal")
		return
	}

	updated, err := h.repo.GetGoalByID(r.Context(), userID, id)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Deposit succeeded but failed to fetch updated goal")
		return
	}

	writeJSON(w, http.StatusOK, updated)
}

func (h *GoalHandler) Delete(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	idStr := r.PathValue("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		writeError(w, http.StatusBadRequest, "Invalid goal ID")
		return
	}

	if err := h.repo.DeleteGoal(r.Context(), userID, id); err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to delete savings goal")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"message": "Savings goal deleted successfully"})
}
