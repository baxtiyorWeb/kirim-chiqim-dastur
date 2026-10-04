#!/usr/bin/env bash
# ==============================================================================
# Kirim-Chiqim Backend Keep-Alive Script (Render Sleep Prevention)
# Render Free tier 15 minutlik nofaollikdan so'ng uxlaydi.
# Ushbu skript har 12 minutda xavfsiz /health so'rovini yuboradi.
# ==============================================================================

set -u

# URL argument sifatida berilishi yoki standart olinishi mumkin
URL="${1:-https://kirim-chiqim-dastur.onrender.com}"
HEALTH_URL="${URL%/}/health"
INTERVAL_MINUTES="${2:-12}"
INTERVAL_SECONDS=$((INTERVAL_MINUTES * 60))

echo "=========================================================="
echo "🚀 Render Keep-Alive Pinger ishga tushdi"
echo "Target:   $HEALTH_URL"
echo "Interval: $INTERVAL_MINUTES minut ($INTERVAL_SECONDS soniya)"
echo "To'xtatish uchun: Ctrl + C"
echo "=========================================================="

while true; do
  TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
  
  # So'rov yuborish (timeout: 25s)
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -A "KeepAliveScript/2026" --max-time 25 "$HEALTH_URL" 2>/dev/null || echo "000")
  
  if [ "$HTTP_CODE" = "200" ]; then
    echo "[$TIMESTAMP] ✅ Ping muvaffaqiyatli: $HEALTH_URL (HTTP 200 OK)"
  elif [ "$HTTP_CODE" = "000" ]; then
    echo "[$TIMESTAMP] ❌ Ulanish xatosi (Server uxlayotgan yoki tarmoq yo'q)"
  else
    echo "[$TIMESTAMP] ⚠️ Javob kodi: HTTP $HTTP_CODE"
  fi
  
  sleep "$INTERVAL_SECONDS"
done
