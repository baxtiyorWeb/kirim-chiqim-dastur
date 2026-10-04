package handler

import (
	"net/http"

	"kirim-chiqim-backend/internal/middleware"
	"kirim-chiqim-backend/internal/repository"
)

type DashboardHandler struct {
	repo repository.Repository
}

func NewDashboardHandler(repo repository.Repository) *DashboardHandler {
	return &DashboardHandler{repo: repo}
}

func (h *DashboardHandler) GetSummary(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	summary, err := h.repo.GetDashboardSummary(r.Context(), userID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to calculate dashboard summary")
		return
	}

	writeJSON(w, http.StatusOK, summary)
}

func (h *DashboardHandler) GetStatistics(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	period := r.URL.Query().Get("period")
	if period == "" {
		period = "monthly"
	}

	stats, err := h.repo.GetStatistics(r.Context(), userID, period)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to compute financial statistics")
		return
	}

	writeJSON(w, http.StatusOK, stats)
}
