package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"kirim-chiqim-backend/internal/config"
	"kirim-chiqim-backend/internal/database"
	"kirim-chiqim-backend/internal/handler"
	"kirim-chiqim-backend/internal/middleware"
)

func main() {
	cfg := config.Load()

	log.Printf("[Server] Starting Kirim-Chiqim Backend on port :%s (env: %s)...\n", cfg.Port, cfg.AppEnv)

	repo, cleanup, err := database.InitRepository(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("[Server] Failed to initialize repository: %v", err)
	}
	defer cleanup()

	// Initialize handlers
	authH := handler.NewAuthHandler(repo, cfg.JWTSecret)
	txH := handler.NewTransactionHandler(repo)
	budgetH := handler.NewBudgetHandler(repo)
	debtH := handler.NewDebtHandler(repo)
	goalH := handler.NewGoalHandler(repo)
	dashH := handler.NewDashboardHandler(repo)
	healthH := handler.NewHealthHandler()

	mux := http.NewServeMux()

	// Public routes
	mux.HandleFunc("GET /health", healthH.Health)
	mux.HandleFunc("GET /api/v1/health", healthH.Health)
	mux.HandleFunc("POST /api/v1/auth/register", authH.Register)
	mux.HandleFunc("POST /api/v1/auth/login", authH.Login)
	mux.HandleFunc("POST /api/v1/auth/send-otp", authH.SendOTP)
	mux.HandleFunc("POST /api/v1/auth/verify-otp", authH.VerifyOTP)
	mux.HandleFunc("POST /api/v1/auth/complete-registration", authH.CompleteRegistration)

	// Protected routes helper
	protect := middleware.Auth(cfg.JWTSecret, repo)

	// Auth & User Profile
	mux.Handle("GET /api/v1/auth/me", protect(http.HandlerFunc(authH.Me)))
	mux.Handle("PUT /api/v1/auth/profile", protect(http.HandlerFunc(authH.UpdateProfile)))
	mux.Handle("PUT /api/v1/auth/initial-balance", protect(http.HandlerFunc(authH.SetInitialBalance)))
	mux.Handle("DELETE /api/v1/auth/account", protect(http.HandlerFunc(authH.DeleteAccount)))

	// Transactions
	mux.Handle("GET /api/v1/transactions", protect(http.HandlerFunc(txH.List)))
	mux.Handle("POST /api/v1/transactions", protect(http.HandlerFunc(txH.Create)))
	mux.Handle("GET /api/v1/transactions/{id}", protect(http.HandlerFunc(txH.Get)))
	mux.Handle("PUT /api/v1/transactions/{id}", protect(http.HandlerFunc(txH.Update)))
	mux.Handle("DELETE /api/v1/transactions/{id}", protect(http.HandlerFunc(txH.Delete)))

	// Dashboard & Stats
	mux.Handle("GET /api/v1/dashboard", protect(http.HandlerFunc(dashH.GetSummary)))
	mux.Handle("GET /api/v1/statistics", protect(http.HandlerFunc(dashH.GetStatistics)))

	// Monthly Budget ("Smeta")
	mux.Handle("GET /api/v1/budget", protect(http.HandlerFunc(budgetH.Get)))
	mux.Handle("PUT /api/v1/budget", protect(http.HandlerFunc(budgetH.UpdateTotal)))
	mux.Handle("PUT /api/v1/budget/categories/{categoryId}", protect(http.HandlerFunc(budgetH.SetCategoryLimit)))
	mux.Handle("POST /api/v1/budget/categories", protect(http.HandlerFunc(budgetH.SetCategoryLimit)))

	// Debts ("Qarzlar")
	mux.Handle("GET /api/v1/debts", protect(http.HandlerFunc(debtH.List)))
	mux.Handle("POST /api/v1/debts", protect(http.HandlerFunc(debtH.Create)))
	mux.Handle("GET /api/v1/debts/{id}", protect(http.HandlerFunc(debtH.Get)))
	mux.Handle("POST /api/v1/debts/{id}/repay", protect(http.HandlerFunc(debtH.Repay)))
	mux.Handle("DELETE /api/v1/debts/{id}", protect(http.HandlerFunc(debtH.Delete)))

	// Savings Goals ("Jamg'arma")
	mux.Handle("GET /api/v1/goals", protect(http.HandlerFunc(goalH.List)))
	mux.Handle("POST /api/v1/goals", protect(http.HandlerFunc(goalH.Create)))
	mux.Handle("POST /api/v1/goals/{id}/deposit", protect(http.HandlerFunc(goalH.Deposit)))
	mux.Handle("DELETE /api/v1/goals/{id}", protect(http.HandlerFunc(goalH.Delete)))

	// Global middleware chain: Recovery -> Logger -> CORS -> Router
	var finalHandler http.Handler = mux
	finalHandler = middleware.CORS(cfg.CorsOrigins)(finalHandler)
	finalHandler = middleware.Logger(finalHandler)
	finalHandler = middleware.Recovery(finalHandler)

	srv := &http.Server{
		Addr:         fmt.Sprintf(":%s", cfg.Port),
		Handler:      finalHandler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Graceful shutdown
	idleConnsClosed := make(chan struct{})
	go func() {
		sigint := make(chan os.Signal, 1)
		signal.Notify(sigint, os.Interrupt, syscall.SIGTERM)
		<-sigint

		log.Println("[Server] Shutting down gracefully...")
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()

		if err := srv.Shutdown(ctx); err != nil {
			log.Printf("[Server] HTTP shutdown error: %v\n", err)
		}
		close(idleConnsClosed)
	}()

	log.Printf("[Server] HTTP server listening on http://0.0.0.0:%s\n", cfg.Port)
	if err := srv.ListenAndServe(); err != http.ErrServerClosed {
		log.Fatalf("[Server] HTTP listen error: %v", err)
	}

	<-idleConnsClosed
	log.Println("[Server] Server stopped cleanly.")
}
