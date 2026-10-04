package handler

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"kirim-chiqim-backend/internal/repository"
)

func TestAuthOTPFlow(t *testing.T) {
	repo := repository.NewMemoryRepository()
	authH := NewAuthHandler(repo, "test-jwt-secret-key-123456789012")

	// 1. Send OTP for new phone
	sendReq := SendOTPRequest{PhoneNumber: "+998 90 123 45 67"}
	body, _ := json.Marshal(sendReq)
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/send-otp", bytes.NewReader(body))
	rec := httptest.NewRecorder()
	authH.SendOTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200 from SendOTP, got %d: %s", rec.Code, rec.Body.String())
	}

	var sendResp SendOTPResponse
	if err := json.NewDecoder(rec.Body).Decode(&sendResp); err != nil {
		t.Fatalf("failed to decode send-otp response: %v", err)
	}
	if sendResp.OTP == "" || len(sendResp.OTP) != 4 {
		t.Fatalf("expected 4-digit OTP, got %s", sendResp.OTP)
	}
	if sendResp.IsRegistered {
		t.Fatalf("expected new phone to be not registered")
	}

	// 2. Verify with wrong code -> should fail
	wrongReq := VerifyOTPRequest{PhoneNumber: "+998901234567", Code: "9999"}
	body, _ = json.Marshal(wrongReq)
	req = httptest.NewRequest(http.MethodPost, "/api/v1/auth/verify-otp", bytes.NewReader(body))
	rec = httptest.NewRecorder()
	authH.VerifyOTP(rec, req)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for wrong OTP, got %d", rec.Code)
	}

	// 3. Verify with correct code -> should return isNewUser: true
	verifyReq := VerifyOTPRequest{PhoneNumber: "+998901234567", Code: sendResp.OTP}
	body, _ = json.Marshal(verifyReq)
	req = httptest.NewRequest(http.MethodPost, "/api/v1/auth/verify-otp", bytes.NewReader(body))
	rec = httptest.NewRecorder()
	authH.VerifyOTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200 from VerifyOTP, got %d: %s", rec.Code, rec.Body.String())
	}
	var verifyResp VerifyOTPResponse
	if err := json.NewDecoder(rec.Body).Decode(&verifyResp); err != nil {
		t.Fatalf("failed to decode verify-otp response: %v", err)
	}
	if !verifyResp.IsNewUser {
		t.Fatalf("expected isNewUser to be true for first-time phone")
	}

	// 4. Complete registration with name
	compReq := CompleteRegistrationRequest{PhoneNumber: "+998901234567", FullName: "Baxtiyor"}
	body, _ = json.Marshal(compReq)
	req = httptest.NewRequest(http.MethodPost, "/api/v1/auth/complete-registration", bytes.NewReader(body))
	rec = httptest.NewRecorder()
	authH.CompleteRegistration(rec, req)

	if rec.Code != http.StatusCreated && rec.Code != http.StatusOK {
		t.Fatalf("expected 201/200 from CompleteRegistration, got %d: %s", rec.Code, rec.Body.String())
	}
	var authResp AuthResponse
	if err := json.NewDecoder(rec.Body).Decode(&authResp); err != nil {
		t.Fatalf("failed to decode auth response: %v", err)
	}
	if authResp.Token == "" {
		t.Fatalf("expected token in complete-registration response")
	}
	if authResp.User.FullName != "Baxtiyor" {
		t.Fatalf("expected user name 'Baxtiyor', got '%s'", authResp.User.FullName)
	}

	// 5. Subsequent SendOTP & VerifyOTP should now detect registered user and login immediately
	req = httptest.NewRequest(http.MethodPost, "/api/v1/auth/send-otp", bytes.NewReader(body))
	rec = httptest.NewRecorder()
	authH.SendOTP(rec, req)
	var sendResp2 SendOTPResponse
	_ = json.NewDecoder(rec.Body).Decode(&sendResp2)
	if !sendResp2.IsRegistered {
		t.Fatalf("expected phone to be registered now")
	}

	verifyReq2 := VerifyOTPRequest{PhoneNumber: "+998901234567", Code: sendResp2.OTP}
	body, _ = json.Marshal(verifyReq2)
	req = httptest.NewRequest(http.MethodPost, "/api/v1/auth/verify-otp", bytes.NewReader(body))
	rec = httptest.NewRecorder()
	authH.VerifyOTP(rec, req)

	var verifyResp2 VerifyOTPResponse
	_ = json.NewDecoder(rec.Body).Decode(&verifyResp2)
	if verifyResp2.IsNewUser {
		t.Fatalf("expected isNewUser to be false for existing user")
	}
	if verifyResp2.Token == "" || verifyResp2.User == nil {
		t.Fatalf("expected existing user to get token and user profile immediately")
	}
}
