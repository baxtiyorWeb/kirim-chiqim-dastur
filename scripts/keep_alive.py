#!/usr/bin/env python3
"""
Kirim-Chiqim Backend Keep-Alive Pinger (Render 2026)
Faqat Python 3 standart kutubxonasidan foydalanadi (hech qanday pip install talab qilinmaydi).
Windows, Linux, macOS tizimlarida birdek ishlaydi.
"""

import sys
import time
import urllib.request
import urllib.error
from datetime import datetime

DEFAULT_URL = "https://kirim-chiqim-backend.onrender.com/health"
DEFAULT_INTERVAL_MINUTES = 12


def ping(url: str) -> None:
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "KeepAliveScript/2026 (HealthCheck)"},
    )
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    try:
        with urllib.request.urlopen(req, timeout=25) as response:
            status = response.getcode()
            if status == 200:
                print(f"[{timestamp}] ✅ Server faol: {url} (HTTP 200 OK)")
            else:
                print(f"[{timestamp}] ⚠️ Kutilmagan javob: HTTP {status}")
    except urllib.error.HTTPError as e:
        print(f"[{timestamp}] ⚠️ HTTP xatolik kodi: {e.code}")
    except urllib.error.URLError as e:
        print(f"[{timestamp}] ❌ Ulanish xatosi (server uyg'onish jarayonida bo'lishi mumkin): {e.reason}")
    except Exception as e:
        print(f"[{timestamp}] ❌ Xatolik: {e}")


def main():
    target_url = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_URL
    if not target_url.endswith("/health"):
        target_url = target_url.rstrip("/") + "/health"

    interval_minutes = int(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_INTERVAL_MINUTES
    interval_seconds = interval_minutes * 60

    print("=" * 60)
    print("🚀 Render Keep-Alive Pinger ishga tushdi")
    print(f"Target URL: {target_url}")
    print(f"Interval:   {interval_minutes} minut")
    print("To'xtatish uchun: Ctrl + C")
    print("=" * 60)

    while True:
        ping(target_url)
        time.sleep(interval_seconds)


if __name__ == "__main__":
    main()
