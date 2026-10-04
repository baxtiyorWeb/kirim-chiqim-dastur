package database

import (
	"context"
	"database/sql"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"

	_ "github.com/lib/pq"
	"kirim-chiqim-backend/internal/repository"
)

// InitRepository initializes the persistent repository.
// If databaseURL is provided and reachable, it runs database schema migrations and returns a PostgresRepository.
// If databaseURL is empty or cannot be reached, it initializes a high-performance in-memory repository.
func InitRepository(databaseURL string) (repository.Repository, func(), error) {
	cleanURL := strings.TrimSpace(databaseURL)
	if cleanURL == "" {
		log.Println("[Database] No DATABASE_URL provided. Running in high-performance in-memory mode.")
		return repository.NewMemoryRepository(), func() {}, nil
	}

	// Clean Neon/AWS parameters unsupported by lib/pq driver
	cleanURL = strings.ReplaceAll(cleanURL, "&channel_binding=require", "")
	cleanURL = strings.ReplaceAll(cleanURL, "?channel_binding=require", "")
	cleanURL = strings.ReplaceAll(cleanURL, "channel_binding=require&", "")
	cleanURL = strings.ReplaceAll(cleanURL, "-pooler.", ".")

	log.Printf("[Database] Connecting to PostgreSQL / Neon: %s\n", maskConnStr(cleanURL))
	db, err := sql.Open("postgres", cleanURL)
	if err != nil {
		log.Printf("[Database] Connection failed: %v. Falling back to in-memory mode.\n", err)
		return repository.NewMemoryRepository(), func() {}, nil
	}

	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(15 * time.Minute)
	db.SetConnMaxIdleTime(1 * time.Minute)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		log.Printf("[Database] Ping failed: %v. Falling back to in-memory mode.\n", err)
		_ = db.Close()
		return repository.NewMemoryRepository(), func() {}, nil
	}

	log.Println("[Database] Connected successfully to PostgreSQL / Neon.")

	// Auto-apply schema migrations if file exists
	runMigrations(db)

	cleanup := func() {
		_ = db.Close()
	}

	return repository.NewPostgresRepository(db), cleanup, nil
}

func runMigrations(db *sql.DB) {
	// Look for schema.sql in likely locations
	candidates := []string{
		"database/schema.sql",
		"../database/schema.sql",
		"../../database/schema.sql",
		filepath.Join(".", "schema.sql"),
	}

	var schemaPath string
	for _, p := range candidates {
		if _, err := os.Stat(p); err == nil {
			schemaPath = p
			break
		}
	}

	if schemaPath == "" {
		log.Println("[Database] schema.sql not found in standard paths, skipping auto-migration.")
		return
	}

	content, err := os.ReadFile(schemaPath)
	if err != nil {
		log.Printf("[Database] Failed to read schema %s: %v\n", schemaPath, err)
		return
	}

	log.Printf("[Database] Executing schema migrations from %s...\n", schemaPath)
	if _, err := db.Exec(string(content)); err != nil {
		log.Printf("[Database] Migration execution warning: %v\n", err)
	} else {
		log.Println("[Database] Schema migrations executed successfully.")
	}
}

func maskConnStr(connStr string) string {
	parts := strings.Split(connStr, "@")
	if len(parts) > 1 {
		return "postgres://***@" + parts[1]
	}
	return "postgres://***"
}
