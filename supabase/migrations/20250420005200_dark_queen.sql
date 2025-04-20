/*
  # Admin Panel Infrastructure Setup

  1. New Tables
    - admin_users
      - id (uuid, primary key)
      - email (text, unique)
      - password_hash (text)
      - role (text)
      - last_login (timestamptz)
      - created_at (timestamptz)
      - updated_at (timestamptz)

    - audit_logs
      - id (uuid, primary key)
      - admin_user_id (uuid, references admin_users)
      - action (text)
      - table_name (text)
      - record_id (text)
      - changes (jsonb)
      - ip_address (text)
      - created_at (timestamptz)

    - system_configs
      - id (uuid, primary key)
      - key (text, unique)
      - value (jsonb)
      - description (text)
      - updated_by (uuid, references admin_users)
      - created_at (timestamptz)
      - updated_at (timestamptz)

  2. Security
    - Enable RLS on all tables
    - Add policies for admin access
*/

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Admin Users table
CREATE TABLE admin_users (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    email text UNIQUE NOT NULL,
    password_hash text NOT NULL,
    role text NOT NULL DEFAULT 'staff',
    last_login timestamptz,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    CONSTRAINT valid_role CHECK (role IN ('admin', 'staff'))
);

-- Enable RLS for admin_users
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Policies for admin_users
CREATE POLICY "Admins can do everything with admin_users"
    ON admin_users
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'admin')
    WITH CHECK (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Staff can read and update their own record"
    ON admin_users
    TO authenticated
    USING (auth.uid() = id AND auth.jwt() ->> 'role' = 'staff')
    WITH CHECK (auth.uid() = id AND auth.jwt() ->> 'role' = 'staff');

-- Audit Logs table
CREATE TABLE audit_logs (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_user_id uuid REFERENCES admin_users(id),
    action text NOT NULL,
    table_name text NOT NULL,
    record_id text NOT NULL,
    changes jsonb NOT NULL DEFAULT '{}',
    ip_address text,
    created_at timestamptz DEFAULT now()
);

-- Enable RLS for audit_logs
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Policies for audit_logs
CREATE POLICY "Admins can read all audit logs"
    ON audit_logs
    FOR SELECT
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Staff can read their own audit logs"
    ON audit_logs
    FOR SELECT
    TO authenticated
    USING (admin_user_id = auth.uid());

-- System Configurations table
CREATE TABLE system_configs (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    key text UNIQUE NOT NULL,
    value jsonb NOT NULL,
    description text,
    updated_by uuid REFERENCES admin_users(id),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Enable RLS for system_configs
ALTER TABLE system_configs ENABLE ROW LEVEL SECURITY;

-- Policies for system_configs
CREATE POLICY "Admins can manage system configs"
    ON system_configs
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'admin')
    WITH CHECK (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Staff can read system configs"
    ON system_configs
    FOR SELECT
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'staff');

-- Create indexes for better performance
CREATE INDEX idx_audit_logs_admin_user_id ON audit_logs(admin_user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX idx_system_configs_key ON system_configs(key);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_admin_users_updated_at
    BEFORE UPDATE ON admin_users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_system_configs_updated_at
    BEFORE UPDATE ON system_configs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create function to log changes
CREATE OR REPLACE FUNCTION log_table_changes()
RETURNS TRIGGER AS $$
DECLARE
    changes jsonb;
    admin_user_id uuid;
BEGIN
    -- Get the admin user ID from the current session
    admin_user_id := auth.uid();
    
    -- Calculate changes
    IF TG_OP = 'DELETE' THEN
        changes := to_jsonb(OLD);
    ELSIF TG_OP = 'UPDATE' THEN
        changes := jsonb_build_object(
            'old', to_jsonb(OLD),
            'new', to_jsonb(NEW)
        );
    ELSE
        changes := to_jsonb(NEW);
    END IF;

    -- Insert audit log
    INSERT INTO audit_logs (
        admin_user_id,
        action,
        table_name,
        record_id,
        changes
    ) VALUES (
        admin_user_id,
        TG_OP,
        TG_TABLE_NAME,
        CASE
            WHEN TG_OP = 'DELETE' THEN OLD.id::text
            ELSE NEW.id::text
        END,
        changes
    );

    RETURN NULL;
END;
$$ language 'plpgsql';

-- Create audit triggers for admin_users
CREATE TRIGGER audit_admin_users_changes
    AFTER INSERT OR UPDATE OR DELETE ON admin_users
    FOR EACH ROW EXECUTE FUNCTION log_table_changes();

-- Create audit triggers for system_configs
CREATE TRIGGER audit_system_configs_changes
    AFTER INSERT OR UPDATE OR DELETE ON system_configs
    FOR EACH ROW EXECUTE FUNCTION log_table_changes();

-- Insert default admin user (password: admin123)
INSERT INTO admin_users (email, password_hash, role)
VALUES (
    'admin@example.com',
    '$2a$12$K8HFh3886Hf5q4kJ3y6ee.DztF.MLyxRHx3UBqDEbr6jE9SM4dFni',
    'admin'
);

-- Insert initial system configurations
INSERT INTO system_configs (key, value, description)
VALUES
    ('booking_settings', 
     '{"max_advance_days": 14, "min_duration": 30, "max_duration": 120}',
     'General booking system settings'),
    ('notification_settings',
     '{"email_notifications": true, "sms_notifications": false}',
     'Notification preferences'),
    ('payment_settings',
     '{"allowed_methods": ["click"], "currency": "UZS"}',
     'Payment system settings');