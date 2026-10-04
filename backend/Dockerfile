# Multi-stage production build for Kirim-Chiqim Go backend
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Install git and ca-certificates
RUN apk update && apk add --no-cache git ca-certificates tzdata

# Cache dependencies
COPY go.mod go.sum* ./
RUN go mod download

# Copy source code
COPY . .

# Build statically linked binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o /app/server cmd/server/main.go

# Production scratch/alpine container
FROM alpine:3.20

RUN apk --no-cache add ca-certificates tzdata
WORKDIR /app

# Copy binary and database migrations
COPY --from=builder /app/server /app/server
COPY --from=builder /app/../database /app/database

# Default configuration
ENV PORT=8080
ENV APP_ENV=production

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/health || exit 1

ENTRYPOINT ["/app/server"]
