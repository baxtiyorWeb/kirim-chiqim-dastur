-- Migration: 004_add_password_hash.sql
-- Description: Add password_hash column to users table for real authentication

ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255) NOT NULL DEFAULT '';
