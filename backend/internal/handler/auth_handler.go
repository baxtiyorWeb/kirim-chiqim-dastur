package handler

import (
	"crypto/rand"
	"encoding/json"
	"fmt"
	"math/big"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"kirim-chiqim-backend/internal/middleware"
	"kirim-chiqim-backend/internal/models"
	"kirim-chiqim-backend/internal/repository"
)

type otpData struct {
	code      string
	expiresAt time.Time
}

type AuthHandler struct {
	repo      repository.Repository
	jwtSecret string
	otpMu     sync.RWMutex
	otpStore  map[string]otpData
}

func NewAuthHandler(repo repository.Repository, jwtSecret string) *AuthHandler {
	return &AuthHandler{
		repo:      repo,
		jwtSecret: jwtSecret,
		otpStore:  make(map[string]otpData),
	}
}

type RegisterRequest struct {
	Email       string `json:"email"`
	Password    string `json:"password"`
	FullName    string `json:"fullName"`
	PhoneNumber string `json:"phoneNumber,omitempty"`
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type AuthResponse struct {
	Token string       `json:"token"`
	User  *models.User `json:"user"`
}

func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	var req RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	req.Email = strings.TrimSpace(strings.ToLower(req.Email))
	if req.Email == "" || req.Password == "" || req.FullName == "" {
		writeError(w, http.StatusBadRequest, "Email, password, and full name are required")
		return
	}

	if len(req.Password) < 6 {
		writeError(w, http.StatusBadRequest, "Password must be at least 6 characters")
		return
	}

	// Check if already exists
	existing, _ := h.repo.GetUserByEmail(r.Context(), req.Email)
	if existing != nil {
		writeError(w, http.StatusConflict, "Email already registered")
		return
	}

	hashed, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to hash password")
		return
	}

	user := &models.User{
		ID:           uuid.New(),
		Email:        req.Email,
		PhoneNumber:  req.PhoneNumber,
		PasswordHash: string(hashed),
		FullName:     req.FullName,
		Currency:     "UZS",
		IsActive:     true,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	if err := h.repo.CreateUser(r.Context(), user); err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to create user account")
		return
	}

	token, err := h.generateToken(user.ID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to generate session token")
		return
	}

	writeJSON(w, http.StatusCreated, AuthResponse{Token: token, User: user})
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	req.Email = strings.TrimSpace(strings.ToLower(req.Email))
	if req.Email == "" || req.Password == "" {
		writeError(w, http.StatusBadRequest, "Email and password are required")
		return
	}

	user, err := h.repo.GetUserByEmail(r.Context(), req.Email)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "Invalid email or password")
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		writeError(w, http.StatusUnauthorized, "Invalid email or password")
		return
	}

	token, err := h.generateToken(user.ID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to generate session token")
		return
	}

	writeJSON(w, http.StatusOK, AuthResponse{Token: token, User: user})
}

func (h *AuthHandler) Me(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	user, err := h.repo.GetUserByID(r.Context(), userID)
	if err != nil {
		if err == repository.ErrNotFound {
			user = &models.User{
				ID:        userID,
				FullName:  "Foydalanuvchi",
				Currency:  "UZS",
				IsActive:  true,
				CreatedAt: time.Now(),
				UpdatedAt: time.Now(),
			}
			_ = h.repo.CreateUser(r.Context(), user)
			writeJSON(w, http.StatusOK, user)
			return
		}
		writeError(w, http.StatusNotFound, "User not found")
		return
	}

	writeJSON(w, http.StatusOK, user)
}

type SetInitialBalanceRequest struct {
	InitialBalance int64 `json:"initialBalance"`
}

func (h *AuthHandler) SetInitialBalance(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req SetInitialBalanceRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	if req.InitialBalance < 0 {
		writeError(w, http.StatusBadRequest, "Boshlang'ich balans manfiy bo'lishi mumkin emas")
		return
	}

	user, err := h.repo.GetUserByID(r.Context(), userID)
	if err != nil {
		if err == repository.ErrNotFound {
			user = &models.User{
				ID:             userID,
				FullName:       "Foydalanuvchi",
				Currency:       "UZS",
				InitialBalance: req.InitialBalance,
				IsActive:       true,
				CreatedAt:      time.Now(),
				UpdatedAt:      time.Now(),
			}
			if createErr := h.repo.CreateUser(r.Context(), user); createErr != nil {
				writeError(w, http.StatusInternalServerError, "Foydalanuvchi yaratishda xatolik: "+createErr.Error())
				return
			}
			writeJSON(w, http.StatusOK, map[string]interface{}{
				"message":        "Boshlang'ich balans saqlandi",
				"initialBalance": req.InitialBalance,
				"user":           user,
			})
			return
		}
		writeError(w, http.StatusInternalServerError, "Foydalanuvchini tekshirishda xatolik")
		return
	}

	if err := h.repo.UpdateInitialBalance(r.Context(), userID, req.InitialBalance); err != nil {
		writeError(w, http.StatusInternalServerError, "Boshlang'ich balansni saqlashda xatolik: "+err.Error())
		return
	}

	user.InitialBalance = req.InitialBalance
	writeJSON(w, http.StatusOK, map[string]interface{}{
		"message":        "Boshlang'ich balans saqlandi",
		"initialBalance": req.InitialBalance,
		"user":           user,
	})
}

type UpdateProfileRequest struct {
	FullName  string `json:"fullName"`
	Email     string `json:"email,omitempty"`
	AvatarURL string `json:"avatarUrl,omitempty"`
}

func (h *AuthHandler) UpdateProfile(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req UpdateProfileRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	user, err := h.repo.GetUserByID(r.Context(), userID)
	if err != nil {
		writeError(w, http.StatusNotFound, "User not found")
		return
	}

	if name := strings.TrimSpace(req.FullName); name != "" {
		user.FullName = name
	}
	if email := strings.TrimSpace(strings.ToLower(req.Email)); email != "" {
		user.Email = email
	}
	if avatar := strings.TrimSpace(req.AvatarURL); avatar != "" {
		user.AvatarURL = avatar
	}

	if err := h.repo.UpdateUser(r.Context(), user); err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to update profile: "+err.Error())
		return
	}

	writeJSON(w, http.StatusOK, user)
}

func (h *AuthHandler) DeleteAccount(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	if err := h.repo.DeleteUser(r.Context(), userID); err != nil {
		writeError(w, http.StatusInternalServerError, "Failed to delete account")
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{
		"message": "Account deleted successfully",
	})
}

// -------------------------------------------------------------
// PHONE + OTP UNIFIED AUTHENTICATION FLOW
// -------------------------------------------------------------

type SendOTPRequest struct {
	PhoneNumber string `json:"phoneNumber"`
}

type SendOTPResponse struct {
	Success      bool   `json:"success"`
	Message      string `json:"message"`
	PhoneNumber  string `json:"phoneNumber"`
	IsRegistered bool   `json:"isRegistered"`
	OTP          string `json:"otp,omitempty"`
}

type VerifyOTPRequest struct {
	PhoneNumber string `json:"phoneNumber"`
	Code        string `json:"code"`
}

type VerifyOTPResponse struct {
	IsNewUser   bool         `json:"isNewUser"`
	Token       string       `json:"token,omitempty"`
	User        *models.User `json:"user,omitempty"`
	PhoneNumber string       `json:"phoneNumber,omitempty"`
	Message     string       `json:"message,omitempty"`
}

type CompleteRegistrationRequest struct {
	PhoneNumber string `json:"phoneNumber"`
	FullName    string `json:"fullName"`
}

func cleanPhoneNumber(p string) string {
	digits := strings.Map(func(r rune) rune {
		if r >= '0' && r <= '9' {
			return r
		}
		return -1
	}, p)
	if len(digits) == 9 {
		digits = "998" + digits
	}
	if digits != "" {
		return "+" + digits
	}
	return strings.TrimSpace(p)
}

func (h *AuthHandler) SendOTP(w http.ResponseWriter, r *http.Request) {
	var req SendOTPRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Noto'g'ri so'rov formati")
		return
	}

	phone := cleanPhoneNumber(req.PhoneNumber)
	if len(phone) < 9 {
		writeError(w, http.StatusBadRequest, "Telefon raqami to'liq emas")
		return
	}

	// Generate 4-digit OTP code (random 1000..9999)
	n, _ := rand.Int(rand.Reader, big.NewInt(9000))
	code := fmt.Sprintf("%04d", n.Int64()+1000)

	// Save in store with 5 minute expiration
	h.otpMu.Lock()
	h.otpStore[phone] = otpData{
		code:      code,
		expiresAt: time.Now().Add(5 * time.Minute),
	}
	h.otpMu.Unlock()

	// Check if already registered in database
	existingUser, _ := h.repo.GetUserByPhone(r.Context(), phone)
	isRegistered := (existingUser != nil)

	writeJSON(w, http.StatusOK, SendOTPResponse{
		Success:      true,
		Message:      "Tasdiqlash kodi yuborildi",
		PhoneNumber:  phone,
		IsRegistered: isRegistered,
		OTP:          code, // Dev/testing friendly
	})
}

func (h *AuthHandler) VerifyOTP(w http.ResponseWriter, r *http.Request) {
	var req VerifyOTPRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Noto'g'ri so'rov formati")
		return
	}

	phone := cleanPhoneNumber(req.PhoneNumber)
	reqCode := strings.TrimSpace(req.Code)
	if len(reqCode) != 4 {
		writeError(w, http.StatusBadRequest, "Tasdiqlash kodi 4 xonali bo'lishi kerak")
		return
	}

	// Validate code against store or dev test codes (1379, 1234)
	isValid := false
	if reqCode == "1379" || reqCode == "1234" {
		isValid = true
	} else {
		h.otpMu.RLock()
		stored, exists := h.otpStore[phone]
		h.otpMu.RUnlock()
		if exists && stored.code == reqCode && time.Now().Before(stored.expiresAt) {
			isValid = true
		}
	}

	if !isValid {
		writeError(w, http.StatusBadRequest, "Tasdiqlash kodi noto'g'ri yoki muddati tugagan")
		return
	}

	// Clear used OTP
	h.otpMu.Lock()
	delete(h.otpStore, phone)
	h.otpMu.Unlock()

	// Check user existence in DB
	user, err := h.repo.GetUserByPhone(r.Context(), phone)
	if err == nil && user != nil {
		// Existing user -> Login directly without asking name!
		token, err := h.generateToken(user.ID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "Token yaratishda xatolik yuz berdi")
			return
		}
		writeJSON(w, http.StatusOK, VerifyOTPResponse{
			IsNewUser:   false,
			Token:       token,
			User:        user,
			PhoneNumber: phone,
		})
		return
	}

	// New user -> require name registration in step 3
	writeJSON(w, http.StatusOK, VerifyOTPResponse{
		IsNewUser:   true,
		PhoneNumber: phone,
		Message:     "Yangi foydalanuvchi, profilingizni yaratish uchun ismingizni kiriting",
	})
}

func (h *AuthHandler) CompleteRegistration(w http.ResponseWriter, r *http.Request) {
	var req CompleteRegistrationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Noto'g'ri so'rov formati")
		return
	}

	phone := cleanPhoneNumber(req.PhoneNumber)
	fullName := strings.TrimSpace(req.FullName)
	if fullName == "" {
		writeError(w, http.StatusBadRequest, "Ismingizni kiriting")
		return
	}

	// Check if already registered
	existing, _ := h.repo.GetUserByPhone(r.Context(), phone)
	if existing != nil {
		token, err := h.generateToken(existing.ID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, "Token yaratishda xatolik")
			return
		}
		writeJSON(w, http.StatusOK, AuthResponse{Token: token, User: existing})
		return
	}

	user := &models.User{
		ID:          uuid.New(),
		PhoneNumber: phone,
		FullName:    fullName,
		Currency:    "UZS",
		IsActive:    true,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	if err := h.repo.CreateUser(r.Context(), user); err != nil {
		writeError(w, http.StatusInternalServerError, "Hisob yaratishda xatolik: "+err.Error())
		return
	}

	token, err := h.generateToken(user.ID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "Token yaratishda xatolik")
		return
	}

	writeJSON(w, http.StatusCreated, AuthResponse{Token: token, User: user})
}

func (h *AuthHandler) generateToken(userID uuid.UUID) (string, error) {
	claims := jwt.MapClaims{
		"sub": userID.String(),
		"iat": time.Now().Unix(),
		"exp": time.Now().Add(30 * 24 * time.Hour).Unix(), // 30 days
	}
	t := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return t.SignedString([]byte(h.jwtSecret))
}
