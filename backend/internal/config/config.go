package config

import (
	"os"
	"strings"
)

type Config struct {
	Port           string
	DatabaseURL    string
	JWTSecret      string
	AppEnv         string
	CorsOrigins    []string
	ClickSecretKey string
	ClickServiceID string
	PaymeSecretKey string
}

func Load() *Config {
	loadDotEnv()

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	dbURL := os.Getenv("DATABASE_URL")

	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		jwtSecret = "super-secret-moliya-production-key-change-in-env"
	}

	appEnv := os.Getenv("APP_ENV")
	if appEnv == "" {
		appEnv = "development"
	}

	clickSecretKey := os.Getenv("CLICK_SECRET_KEY")
	clickServiceID := os.Getenv("CLICK_SERVICE_ID")
	paymeSecretKey := os.Getenv("PAYME_SECRET_KEY")

	corsRaw := os.Getenv("CORS_ORIGINS")
	var corsOrigins []string
	if corsRaw == "" {
		corsOrigins = []string{"*"}
	} else {
		for _, o := range strings.Split(corsRaw, ",") {
			corsOrigins = append(corsOrigins, strings.TrimSpace(o))
		}
	}

	return &Config{
		Port:           port,
		DatabaseURL:    dbURL,
		JWTSecret:      jwtSecret,
		AppEnv:         appEnv,
		CorsOrigins:    corsOrigins,
		ClickSecretKey: clickSecretKey,
		ClickServiceID: clickServiceID,
		PaymeSecretKey: paymeSecretKey,
	}
}

func loadDotEnv() {
	candidates := []string{".env", "../.env", "backend/.env"}
	for _, path := range candidates {
		content, err := os.ReadFile(path)
		if err != nil {
			continue
		}
		for _, line := range strings.Split(string(content), "\n") {
			line = strings.TrimSpace(line)
			if line == "" || strings.HasPrefix(line, "#") {
				continue
			}
			parts := strings.SplitN(line, "=", 2)
			if len(parts) == 2 {
				k := strings.TrimSpace(parts[0])
				v := strings.TrimSpace(parts[1])
				if os.Getenv(k) == "" {
					os.Setenv(k, v)
				}
			}
		}
		break
	}
}

