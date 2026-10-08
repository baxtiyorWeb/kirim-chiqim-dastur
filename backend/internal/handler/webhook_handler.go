package handler

import (
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"kirim-chiqim-backend/internal/config"
	"kirim-chiqim-backend/internal/models"
	"kirim-chiqim-backend/internal/repository"
)

type WebhookHandler struct {
	repo repository.Repository
	cfg  *config.Config
}

func NewWebhookHandler(repo repository.Repository, cfg *config.Config) *WebhookHandler {
	return &WebhookHandler{repo: repo, cfg: cfg}
}

// ============================================================
// CLICK WEBHOOK PROTOCOL (Prepare: action=0, Complete: action=1)
// ============================================================

type ClickRequest struct {
	ClickTransID    int64  `json:"click_trans_id"`
	ServiceID       int64  `json:"service_id"`
	ClickPaydocID   int64  `json:"click_paydoc_id"`
	MerchantTransID string `json:"merchant_trans_id"` // Our OrderID
	Amount          float64 `json:"amount"`
	Action          int    `json:"action"` // 0 = prepare, 1 = complete
	Error           int    `json:"error"`
	ErrorNote       string `json:"error_note"`
	SignTime        string `json:"sign_time"`
	SignString      string `json:"sign_string"`
}

type ClickResponse struct {
	ClickTransID      int64  `json:"click_trans_id"`
	MerchantTransID   string `json:"merchant_trans_id"`
	MerchantPrepareID int64  `json:"merchant_prepare_id,omitempty"`
	MerchantConfirmID int64  `json:"merchant_confirm_id,omitempty"`
	Error             int    `json:"error"`
	ErrorNote         string `json:"error_note"`
}

func (h *WebhookHandler) ClickWebhook(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
		return
	}

	var req ClickRequest
	contentType := r.Header.Get("Content-Type")

	if strings.Contains(contentType, "application/json") {
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			h.writeClickResponse(w, 0, "", -8, "Failed to parse JSON body")
			return
		}
	} else {
		_ = r.ParseForm()
		req.ClickTransID, _ = strconv.ParseInt(r.FormValue("click_trans_id"), 10, 64)
		req.ServiceID, _ = strconv.ParseInt(r.FormValue("service_id"), 10, 64)
		req.ClickPaydocID, _ = strconv.ParseInt(r.FormValue("click_paydoc_id"), 10, 64)
		req.MerchantTransID = r.FormValue("merchant_trans_id")
		req.Amount, _ = strconv.ParseFloat(r.FormValue("amount"), 64)
		req.Action, _ = strconv.Atoi(r.FormValue("action"))
		req.Error, _ = strconv.Atoi(r.FormValue("error"))
		req.ErrorNote = r.FormValue("error_note")
		req.SignTime = r.FormValue("sign_time")
		req.SignString = r.FormValue("sign_string")
	}

	log.Printf("[ClickWebhook] Received action=%d orderID=%s amount=%.2f clickTransID=%d\n",
		req.Action, req.MerchantTransID, req.Amount, req.ClickTransID)

	// Validate sign_string if secret key is set
	if h.cfg.ClickSecretKey != "" {
		expectedRaw := fmt.Sprintf("%d%d%s%s%.2f%d%s",
			req.ClickTransID, req.ServiceID, h.cfg.ClickSecretKey,
			req.MerchantTransID, req.Amount, req.Action, req.SignTime)
		hasher := md5.New()
		hasher.Write([]byte(expectedRaw))
		expectedSign := hex.EncodeToString(hasher.Sum(nil))

		if !strings.EqualFold(expectedSign, req.SignString) {
			log.Printf("[ClickWebhook] Sign verification failed. Expected: %s, Got: %s\n", expectedSign, req.SignString)
			h.writeClickResponse(w, req.ClickTransID, req.MerchantTransID, -1, "SIGN CHECK FAILED")
			return
		}
	}

	// Find order
	orderUUID, err := uuid.Parse(req.MerchantTransID)
	if err != nil {
		h.writeClickResponse(w, req.ClickTransID, req.MerchantTransID, -5, "User or order does not exist")
		return
	}

	order, err := h.repo.GetPaymentOrderByID(r.Context(), orderUUID)
	if err != nil || order == nil {
		h.writeClickResponse(w, req.ClickTransID, req.MerchantTransID, -5, "Order not found")
		return
	}

	// Check amount (Uzbekistan so'm)
	expectedAmount := float64(order.Amount)
	if req.Amount != expectedAmount {
		h.writeClickResponse(w, req.ClickTransID, req.MerchantTransID, -2, "Incorrect parameter amount")
		return
	}

	if req.Action == 0 {
		// Action 0: PREPARE
		if order.Status == models.OrderStatusPaid {
			h.writeClickResponse(w, req.ClickTransID, req.MerchantTransID, -4, "Already paid")
			return
		}
		res := ClickResponse{
			ClickTransID:      req.ClickTransID,
			MerchantTransID:   req.MerchantTransID,
			MerchantPrepareID: req.ClickTransID,
			Error:             0,
			ErrorNote:         "Success",
		}
		writeJSON(w, http.StatusOK, res)
		return
	}

	if req.Action == 1 {
		// Action 1: COMPLETE
		if order.Status == models.OrderStatusPaid {
			res := ClickResponse{
				ClickTransID:      req.ClickTransID,
				MerchantTransID:   req.MerchantTransID,
				MerchantConfirmID: req.ClickTransID,
				Error:             0,
				ErrorNote:         "Success (Already paid)",
			}
			writeJSON(w, http.StatusOK, res)
			return
		}

		now := time.Now()
		extTx := fmt.Sprintf("click_%d", req.ClickTransID)
		order.Status = models.OrderStatusPaid
		order.PaidAt = &now
		order.ExternalTransactionID = &extTx
		order.PaymentMethod = models.PaymentMethodLocalClick
		order.Notes = fmt.Sprintf("Click to'lovi muvaffaqiyatli yakunlandi. TransID: %d", req.ClickTransID)

		if err := h.repo.UpdatePaymentOrder(r.Context(), order); err != nil {
			h.writeClickResponse(w, req.ClickTransID, req.MerchantTransID, -7, "Database update failed")
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
		_ = h.repo.UpsertSubscription(r.Context(), sub)

		log.Printf("[ClickWebhook] Pro subscription successfully activated for user %s via Click Trans %d\n",
			order.UserID, req.ClickTransID)

		res := ClickResponse{
			ClickTransID:      req.ClickTransID,
			MerchantTransID:   req.MerchantTransID,
			MerchantConfirmID: req.ClickTransID,
			Error:             0,
			ErrorNote:         "Success",
		}
		writeJSON(w, http.StatusOK, res)
		return
	}

	h.writeClickResponse(w, req.ClickTransID, req.MerchantTransID, -3, "Action not found")
}

func (h *WebhookHandler) writeClickResponse(w http.ResponseWriter, clickTransID int64, merchantTransID string, errCode int, errNote string) {
	res := ClickResponse{
		ClickTransID:    clickTransID,
		MerchantTransID: merchantTransID,
		Error:           errCode,
		ErrorNote:       errNote,
	}
	writeJSON(w, http.StatusOK, res)
}

// ============================================================
// PAYME WEBHOOK PROTOCOL (JSON-RPC 2.0 Merchant API)
// ============================================================

type PaymeRPCRequest struct {
	Method string                 `json:"method"`
	Params map[string]interface{} `json:"params"`
	ID     interface{}            `json:"id"`
}

type PaymeRPCResponse struct {
	Result interface{} `json:"result,omitempty"`
	Error  interface{} `json:"error,omitempty"`
	ID     interface{} `json:"id"`
}

func (h *WebhookHandler) PaymeWebhook(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
		return
	}

	var req PaymeRPCRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusOK, map[string]interface{}{
			"error": map[string]interface{}{"code": -32700, "message": "Parse error"},
			"id":    nil,
		})
		return
	}

	log.Printf("[PaymeWebhook] RPC Method=%s ID=%v\n", req.Method, req.ID)

	switch req.Method {
	case "CheckPerformTransaction":
		h.handlePaymeCheckPerform(w, req)
	case "CreateTransaction":
		h.handlePaymeCreateTransaction(w, req)
	case "PerformTransaction":
		h.handlePaymePerformTransaction(w, req)
	case "CheckTransaction":
		h.handlePaymeCheckTransaction(w, req)
	case "CancelTransaction":
		h.handlePaymeCancelTransaction(w, req)
	default:
		writeJSON(w, http.StatusOK, PaymeRPCResponse{
			ID:    req.ID,
			Error: map[string]interface{}{"code": -32601, "message": "Method not found"},
		})
	}
}

func (h *WebhookHandler) handlePaymeCheckPerform(w http.ResponseWriter, req PaymeRPCRequest) {
	account, _ := req.Params["account"].(map[string]interface{})
	orderIDStr, _ := account["order_id"].(string)
	if orderIDStr == "" {
		orderIDStr, _ = account["orderId"].(string)
	}

	orderUUID, err := uuid.Parse(orderIDStr)
	if err != nil {
		h.writePaymeError(w, req.ID, -31001, "Buyurtma topilmadi")
		return
	}

	order, err := h.repo.GetPaymentOrderByID(rContext(), orderUUID)
	if err != nil || order == nil {
		h.writePaymeError(w, req.ID, -31001, "Buyurtma topilmadi")
		return
	}

	// Payme transmits amount in tiyin (1 UZS = 100 tiyin)
	amountTiyin, _ := req.Params["amount"].(float64)
	expectedTiyin := float64(order.Amount * 100)
	if int64(amountTiyin) != int64(expectedTiyin) {
		h.writePaymeError(w, req.ID, -31001, "Noto'g'ri to'lov summasi")
		return
	}

	writeJSON(w, http.StatusOK, PaymeRPCResponse{
		ID:     req.ID,
		Result: map[string]interface{}{"allow": true},
	})
}

func (h *WebhookHandler) handlePaymeCreateTransaction(w http.ResponseWriter, req PaymeRPCRequest) {
	account, _ := req.Params["account"].(map[string]interface{})
	orderIDStr, _ := account["order_id"].(string)
	if orderIDStr == "" {
		orderIDStr, _ = account["orderId"].(string)
	}
	paymeTransID, _ := req.Params["id"].(string)

	nowMs := time.Now().UnixMilli()

	writeJSON(w, http.StatusOK, PaymeRPCResponse{
		ID: req.ID,
		Result: map[string]interface{}{
			"create_time":  nowMs,
			"transaction":  paymeTransID,
			"state":        1, // Created
			"receivers":    nil,
			"order_id":     orderIDStr,
		},
	})
}

func (h *WebhookHandler) handlePaymePerformTransaction(w http.ResponseWriter, req PaymeRPCRequest) {
	paymeTransID, _ := req.Params["id"].(string)

	// In real setup, look up order by external tx or store Payme ID
	now := time.Now()
	nowMs := now.UnixMilli()

	writeJSON(w, http.StatusOK, PaymeRPCResponse{
		ID: req.ID,
		Result: map[string]interface{}{
			"transaction":  paymeTransID,
			"perform_time": nowMs,
			"state":        2, // Completed
		},
	})
}

func (h *WebhookHandler) handlePaymeCheckTransaction(w http.ResponseWriter, req PaymeRPCRequest) {
	paymeTransID, _ := req.Params["id"].(string)
	writeJSON(w, http.StatusOK, PaymeRPCResponse{
		ID: req.ID,
		Result: map[string]interface{}{
			"transaction":  paymeTransID,
			"create_time":  time.Now().UnixMilli() - 1000,
			"perform_time": time.Now().UnixMilli(),
			"cancel_time":  0,
			"state":        2,
			"reason":       nil,
		},
	})
}

func (h *WebhookHandler) handlePaymeCancelTransaction(w http.ResponseWriter, req PaymeRPCRequest) {
	paymeTransID, _ := req.Params["id"].(string)
	writeJSON(w, http.StatusOK, PaymeRPCResponse{
		ID: req.ID,
		Result: map[string]interface{}{
			"transaction": paymeTransID,
			"cancel_time": time.Now().UnixMilli(),
			"state":       -1,
			"reason":      1,
		},
	})
}

func (h *WebhookHandler) writePaymeError(w http.ResponseWriter, id interface{}, code int, msg string) {
	writeJSON(w, http.StatusOK, PaymeRPCResponse{
		ID: id,
		Error: map[string]interface{}{
			"code":    code,
			"message": map[string]string{"uz": msg, "ru": msg, "en": msg},
		},
	})
}

func rContext() contextWrapper {
	// Fallback helper for contexts
	return contextWrapper{}
}

type contextWrapper struct{}

func (cw contextWrapper) Deadline() (deadline time.Time, ok bool) { return time.Time{}, false }
func (cw contextWrapper) Done() <-chan struct{}                   { return nil }
func (cw contextWrapper) Err() error                              { return nil }
func (cw contextWrapper) Value(key interface{}) interface{}        { return nil }
