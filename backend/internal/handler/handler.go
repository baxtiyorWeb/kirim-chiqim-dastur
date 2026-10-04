package handler

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"
)

func writeJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func writeError(w http.ResponseWriter, status int, message string) {
	log.Printf("[API ERROR %d] %s\n", status, message)
	writeJSON(w, status, map[string]string{"error": message})
}

func parseAmountFlex(val interface{}) int64 {
	if val == nil {
		return 0
	}
	switch v := val.(type) {
	case int64:
		return v
	case int:
		return int64(v)
	case float64:
		return int64(v)
	case string:
		cleaned := strings.ReplaceAll(v, " ", "")
		cleaned = strings.ReplaceAll(cleaned, "so'm", "")
		cleaned = strings.TrimSpace(cleaned)
		n, _ := strconv.ParseInt(cleaned, 10, 64)
		return n
	case json.Number:
		n, _ := v.Int64()
		return n
	}
	return 0
}

func parseTimeFlex(val interface{}) *time.Time {
	if val == nil {
		return nil
	}
	str := strings.TrimSpace(fmt.Sprintf("%v", val))
	if str == "" || str == "<nil>" {
		return nil
	}
	// Try standard RFC3339 / ISO 8601
	if t, err := time.Parse(time.RFC3339Nano, str); err == nil {
		return &t
	}
	if t, err := time.Parse(time.RFC3339, str); err == nil {
		return &t
	}
	// Try common formats without timezone
	layouts := []string{
		"2006-01-02T15:04:05.999999999",
		"2006-01-02T15:04:05.999999",
		"2006-01-02T15:04:05.999",
		"2006-01-02T15:04:05",
		"2006-01-02 15:04:05",
		"2006-01-02",
	}
	for _, l := range layouts {
		if t, err := time.Parse(l, str); err == nil {
			return &t
		}
	}
	return nil
}
