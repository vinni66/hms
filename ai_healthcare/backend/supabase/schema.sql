-- AI Healthcare System - Supabase Schema (PostgreSQL)

-- Enable UUID extension if not already enabled
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Users table
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    name TEXT NOT NULL DEFAULT 'User',
    role TEXT NOT NULL DEFAULT 'patient',
    age INTEGER DEFAULT 0,
    gender TEXT DEFAULT '',
    phone TEXT DEFAULT '',
    blood_group TEXT DEFAULT '',
    allergies TEXT DEFAULT '',
    emergency_contact TEXT DEFAULT '',
    specialty TEXT DEFAULT '',
    qualification TEXT DEFAULT '',
    experience_years INTEGER DEFAULT 0,
    avatar_color TEXT DEFAULT '#667EEA',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Chat messages table
CREATE TABLE IF NOT EXISTS chat_messages (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    conversation_id TEXT NOT NULL,
    text TEXT NOT NULL,
    is_user BOOLEAN NOT NULL DEFAULT TRUE,
    risk_level TEXT DEFAULT 'normal',
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Appointments table
CREATE TABLE IF NOT EXISTS appointments (
    id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    doctor_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    doctor_name TEXT NOT NULL,
    patient_name TEXT NOT NULL,
    specialty TEXT NOT NULL,
    date_time TIMESTAMP WITH TIME ZONE NOT NULL,
    location TEXT DEFAULT '',
    notes TEXT DEFAULT '',
    status TEXT DEFAULT 'pending',
    consultation_notes TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Prescriptions table
CREATE TABLE IF NOT EXISTS prescriptions (
    id TEXT PRIMARY KEY,
    appointment_id TEXT,
    patient_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    doctor_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    doctor_name TEXT NOT NULL,
    patient_name TEXT NOT NULL,
    diagnosis TEXT DEFAULT '',
    medications JSONB DEFAULT '[]'::jsonb,
    instructions TEXT DEFAULT '',
    date_issued TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Health metrics table
CREATE TABLE IF NOT EXISTS health_metrics (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    value REAL NOT NULL,
    unit TEXT DEFAULT '',
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. Scan reports table
CREATE TABLE IF NOT EXISTS scan_reports (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    image_path TEXT DEFAULT '',
    extracted_text TEXT DEFAULT '',
    ai_summary TEXT DEFAULT '',
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. Medical records table
CREATE TABLE IF NOT EXISTS medical_records (
    id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    record_type TEXT DEFAULT 'general',
    file_path TEXT DEFAULT '',
    created_by TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 8. Pharmacies table
CREATE TABLE IF NOT EXISTS pharmacies (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    distance_km REAL NOT NULL,
    phone TEXT DEFAULT ''
);

-- 9. Pharmacy Inventory
CREATE TABLE IF NOT EXISTS pharmacy_inventory (
    id TEXT PRIMARY KEY,
    pharmacy_id TEXT NOT NULL REFERENCES pharmacies(id) ON DELETE CASCADE,
    medicine_name TEXT NOT NULL,
    stock_status TEXT DEFAULT 'In Stock',
    price REAL DEFAULT 0.0
);
