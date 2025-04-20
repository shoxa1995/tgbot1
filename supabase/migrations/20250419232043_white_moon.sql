/*
  # Initial Schema Setup for Telegram Booking System

  1. New Tables
    - users
      - id (uuid, primary key)
      - telegram_id (text, unique)
      - name (text)
      - phone (text)
      - language (text)
      - created_at (timestamp)

    - staff
      - id (uuid, primary key)
      - name (text)
      - position (text)
      - photo_url (text)
      - description_en (text)
      - description_ru (text)
      - description_uz (text)
      - pricing (integer)
      - available (boolean)
      - created_at (timestamp)

    - bookings
      - id (uuid, primary key)
      - user_id (uuid, references users)
      - staff_id (uuid, references staff)
      - date (date)
      - start_time (time)
      - end_time (time)
      - status (text)
      - payment_id (text)
      - zoom_link (text)
      - bitrix_event_id (text)
      - created_at (timestamp)
      - updated_at (timestamp)

    - schedules
      - id (uuid, primary key)
      - staff_id (uuid, references staff)
      - date (date)
      - is_working (boolean)
      - created_at (timestamp)

    - time_slots
      - id (uuid, primary key)
      - schedule_id (uuid, references schedules)
      - start_time (time)
      - end_time (time)
      - created_at (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
*/

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  telegram_id text UNIQUE NOT NULL,
  name text NOT NULL,
  phone text,
  language text NOT NULL DEFAULT 'en',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own data"
  ON users
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Staff table
CREATE TABLE staff (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  position text NOT NULL,
  photo_url text NOT NULL,
  description_en text NOT NULL,
  description_ru text NOT NULL,
  description_uz text NOT NULL,
  pricing integer NOT NULL DEFAULT 0,
  available boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE staff ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read staff"
  ON staff
  FOR SELECT
  TO authenticated
  USING (true);

-- Bookings table
CREATE TABLE bookings (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES users(id) NOT NULL,
  staff_id uuid REFERENCES staff(id) NOT NULL,
  date date NOT NULL,
  start_time time NOT NULL,
  end_time time NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  payment_id text,
  zoom_link text,
  bitrix_event_id text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own bookings"
  ON bookings
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Schedules table
CREATE TABLE schedules (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id uuid REFERENCES staff(id) NOT NULL,
  date date NOT NULL,
  is_working boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read schedules"
  ON schedules
  FOR SELECT
  TO authenticated
  USING (true);

-- Time slots table
CREATE TABLE time_slots (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  schedule_id uuid REFERENCES schedules(id) NOT NULL,
  start_time time NOT NULL,
  end_time time NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE time_slots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read time slots"
  ON time_slots
  FOR SELECT
  TO authenticated
  USING (true);

-- Add indexes for better performance
CREATE INDEX idx_bookings_user_id ON bookings(user_id);
CREATE INDEX idx_bookings_staff_id ON bookings(staff_id);
CREATE INDEX idx_bookings_date ON bookings(date);
CREATE INDEX idx_schedules_staff_id_date ON schedules(staff_id, date);
CREATE INDEX idx_time_slots_schedule_id ON time_slots(schedule_id);