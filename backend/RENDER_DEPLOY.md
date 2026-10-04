# Render.com ga Go Backendni Deploy Qilish Qo'llanmasi (2026)

Ushbu qo'llanma **Kirim-Chiqim (Moliya)** Go backendini [Render.com](https://render.com) bulutli platformasiga eng so'nggi 2026-yilgi standartlar asosida bepul va xatosiz deploy qilishni bosqichma-bosqich ko'rsatib beradi.

---

## 🚀 1-USUL: Avtomatik Deploy (Blueprint / `render.yaml`) — TAVSIYA ETILADI

Loyiha ildizida va `backend/` papkasida Render Blueprint standarti bo'yicha tayyor `render.yaml` fayli yaratilgan.

1. Loyihangizni **GitHub** yoki **GitLab** profilingizga push qiling:
   ```bash
   git add .
   git commit -m "feat: add Render 2026 deployment config"
   git push origin main
   ```
2. [Render.com](https://dashboard.render.com) ga kiring.
3. Yuqori o'ng burchakdagi **"New +"** tugmasini bosing va **"Blueprint"** ni tanlang.
4. GitHub repozitoriyangizni tanlang (`Connect repository`).
5. Render avtomatik ravishda `render.yaml` faylini aniqlaydi:
   * **Name:** `kirim-chiqim-backend`
   * **Region:** `Frankfurt (EU Central)` — O'zbekiston uchun eng past ping (~60-80ms)!
   * **Runtime:** `Go` (yoki `Docker`)
   * **Health Check Path:** `/health`
6. Render sizdan bitta parametrni so'raydi:
   * `DATABASE_URL` — Neon PostgreSQL ulanish manzilingiz (masalan, `postgresql://neondb_owner:password@ep-xxx.neon.tech/neondb?sslmode=require`).
7. **"Apply"** tugmasini bosing. Render 1 daqiqa ichida backendni build qilib ishga tushiradi!

---

## 🛠️ 2-USUL: Render Dashboard orqali Qo'lda Deploy Qilish (Manual Web Service)

Agar Blueprint ishlatmasdan, to'g'ridan-to'g'ri Web Service ochmoqchi bo'lsangiz:

1. Render Dashboardda **"New +" -> "Web Service"** ni bosing.
2. Repozitoriyangizni ulang.
3. Quyidagi parametrlarni kiriting:
   * **Name:** `kirim-chiqim-backend`
   * **Region:** `Frankfurt (EU Central)`
   * **Branch:** `main`
   * **Root Directory:** `backend`
   * **Runtime:** `Go`
   * **Build Command:** `go build -v -ldflags="-w -s" -o server cmd/server/main.go`
   * **Start Command:** `./server`
   * **Instance Type:** `Free`
4. **Advanced Settings (Kengaytirilgan sozlamalar):**
   * **Health Check Path:** `/health`
   * **Auto-Deploy:** `Yes`
5. **Environment Variables (Muhit o'zgaruvchilari) bo'limida:**
   | Kalit (Key) | Qiymat (Value) | Izoh |
   | :--- | :--- | :--- |
   | `APP_ENV` | `production` | Ishlab chiqarish muhiti |
   | `PORT` | `10000` | Render standart porti |
   | `DATABASE_URL` | `postgresql://user:pass@ep-xxx.neon.tech/neondb?sslmode=require` | Neon DB manzili |
   | `JWT_SECRET` | *(kamida 32 ta belgili ixtiyoriy maxfiy kalit)* | Auth xavfsizligi |
   | `CORS_ORIGINS` | `*` | Barcha so'rovlarga ruxsat |
6. **"Create Web Service"** tugmasini bosing.

---

## 🗄️ Baza Migratsiyasi Qanday Ishlaydi?

Siz hech narsa qilishingiz shart emas! Server ishga tushishi bilan `backend/database/schema.sql` faylini avtomatik o'qiydi va bazangizda jadvallar hamda standart toifalarni (Ovqatlanish, Transport, Maosh va h.k.) avtomatik yaratib oladi.

---

## 📱 Flutter Mobil Ilovani Render Backendiga Ulash

Render sizga tayyor HTTPS manzil beradi, masalan:
`https://kirim-chiqim-backend.onrender.com`

Mobil ilovani ushbu manzilga ulashning 2 ta yo'li bor:

### Variant A: Ishga tushirishda (Kodga tegmasdan)
```bash
flutter run --dart-define=API_BASE_URL=https://kirim-chiqim-backend.onrender.com
```

### Variant B: `lib/core/constants/api_constants.dart` faylida
`lib/core/constants/api_constants.dart` faylidagi `defaultBaseUrl` ga o'z Render manzilingizni qo'yishingiz mumkin.

---

## 🔍 Tekshirish (Verification)

Deploy tugagach, brauzerda testing:
```
https://kirim-chiqim-backend.onrender.com/health
```
Qaytadigan javob:
```json
{"status":"ok","timestamp":"2026-10-04T19:00:00Z"}
```
Agar ushbu javob chiqsa — serveringiz 100% muvaffaqiyatli ishga tushgan!
