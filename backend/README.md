# Kirim-Chiqim (Moliya) Go REST API Backend

Production-ready backend for the Kirim-Chiqim Personal Finance application.

## Architecture
- **Language**: Go 1.24+ / 1.27
- **Database**: PostgreSQL (Fully compatible with Neon, Supabase, AWS RDS, Docker Postgres)
- **Monetary Precision**: Exact integer amounts in Uzbek So'm (no floating-point rounding errors)
- **Authentication**: JWT Bearer tokens (30 days expiration, bcrypt password hashing)
- **Security**: IDOR prevention via strict user ownership constraints (`user_id = $1`)
- **Portability**: Pure 12-factor application configured exclusively via environment variables

---

## Server Migration & Deployment Guide (Boshqa Serverga Ko'chirish Qo'llanmasi)

The backend is 100% portable. To move to any new VPS, cloud server (Ubuntu, Debian, CentOS), Docker, or PaaS (Railway, Render, Fly.io, DigitalOcean):

### Option 1: Docker Deployment (Eng oson va ishonchli usul)
```bash
# 1. Clone repository on the new server
git clone <repo-url>
cd kirim-chiqim-dastur/backend

# 2. Configure environment
cp .env.example .env
# Edit .env with your production database credentials and JWT secret

# 3. Start containers with automatic migrations
docker compose up -d --build

# 4. Check status
docker compose ps
curl http://localhost:8080/health
```

### Option 2: Direct Binary Execution (Systemd or Direct)
```bash
# 1. Install Go and PostgreSQL on server (or connect to remote Neon PostgreSQL)
cd backend

# 2. Set environment variables
export PORT=8080
export APP_ENV=production
export DATABASE_URL="postgresql://user:password@host:5432/dbname?sslmode=require"
export JWT_SECRET="your-strong-production-secret-key"

# 3. Build & Run
go build -o server cmd/server/main.go
./server
```

---

## API Endpoints

### Public
- `GET /health` - Service health status & uptime
- `POST /api/v1/auth/register` - Create account (`email`, `password`, `fullName`)
- `POST /api/v1/auth/login` - Authenticate (`email`, `password`)

### Protected (Requires `Authorization: Bearer <token>`)
- `GET /api/v1/auth/me` - Profile information
- `DELETE /api/v1/auth/account` - Delete account & all user financial data
- `GET /api/v1/dashboard` - Real calculated balance, income, expense, category breakdown
- `GET /api/v1/statistics?period=monthly|weekly|yearly` - Analytics
- `GET /api/v1/transactions` - Filtered transaction list (`type`, `categoryId`, `startDate`, `endDate`, `limit`, `offset`)
- `POST /api/v1/transactions` - Record income or expense
- `GET /api/v1/transactions/{id}` - Details
- `PUT /api/v1/transactions/{id}` - Update
- `DELETE /api/v1/transactions/{id}` - Soft delete
- `GET /api/v1/budget?yearMonth=2026-10` - Monthly budget & category limits
- `PUT /api/v1/budget` - Update total monthly limit
- `PUT /api/v1/budget/categories/{categoryId}` - Update specific category limit (Smeta modal)
- `GET /api/v1/debts?type=borrowed|lent` - List debts
- `POST /api/v1/debts` - Create debt
- `POST /api/v1/debts/{id}/repay` - Add repayment (updates remaining & status deterministically)
- `DELETE /api/v1/debts/{id}` - Delete debt
- `GET /api/v1/goals` - Savings goals
- `POST /api/v1/goals` - Create goal
- `POST /api/v1/goals/{id}/deposit` - Add deposit to goal
- `DELETE /api/v1/goals/{id}` - Delete goal
