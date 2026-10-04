# Neon PostgreSQL Qo'llanmasi (Docker va pgAdmin o'rnatmasdan ishlash)

Kompyuteringiz kuchsiz bo'lsa, **Docker, PostgreSQL yoki pgAdmin o'rnatishingiz shart emas**.
Neon PostgreSQL butunlay bulutda (cloud) tekin ishlaydi va kompyuteringiz xotirasidan 0 MB joy oladi.

---

## 1. Neon Bazasini Ulash (30 soniya)

1. [https://neon.tech](https://neon.tech) saytida bepul ro'yxatdan o'ting.
2. Yangi loyiha (Project) yarating, masalan: `moliya-db`.
3. Bosh sahifada (Dashboard) sizga tayyor connection string beriladi:
   ```text
   postgresql://neondb_owner:npg_xxxxxx@ep-sample-123456.us-east-2.aws.neon.tech/neondb?sslmode=require
   ```
4. `backend/.env` faylini oching va shu manzilni qo'ying:
   ```env
   PORT=8080
   APP_ENV=production
   DATABASE_URL=postgresql://neondb_owner:npg_xxxxxx@ep-sample-123456.us-east-2.aws.neon.tech/neondb?sslmode=require
   JWT_SECRET=moliya_maxfiy_kalit_2026_xavfsiz
   ```
5. `backend` papkasida `server.exe` ni ishga tushiring:
   ```cmd
   .\server.exe
   ```
   **Server Neon ga ulanadi va barcha jadval hamda standart kategoriyalarni avtomatik yaratadi!**

---

## 2. Keyinchalik Ma'lumotlarni Dumping Qilish va Yangi Serverga Ko'chirish

Loyiha bazasi 100% ANSI PostgreSQL standartida yaratilgan ([database/schema.sql](file:///c:/Users/user/Desktop/kirim-chiqim-dastur/database/schema.sql)). Hech qanday xususiy yoki nostandart funksiyalar ishlatilmagan.

### A. Neon dan hamma ma'lumotlarni dump (nusxa) olish:
```bash
pg_dump "postgresql://neondb_owner:npg_xxxxxx@ep-sample-123456.us-east-2.aws.neon.tech/neondb?sslmode=require" --no-owner --no-acl > moliya_backup.sql
```

### B. Yangi serverga (yoki yangi kompyuterga) 100% tiklash (Restore):
```bash
psql "yangi_server_postgres_url" < moliya_backup.sql
```
Barcha jadvallar, foydalanuvchilar, tranzaksiyalar, qarzlar, smeta limitlari va indekslar xatosiz, 100% aniqlikda boshqa serverga o'tadi.
