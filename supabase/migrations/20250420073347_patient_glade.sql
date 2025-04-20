/*
  # Fix admin user authentication

  1. Changes
    - Remove direct auth.users table manipulation
    - Use admin_users table for local authentication
    - Keep password hashing secure
    - Maintain role-based access control

  2. Security
    - Uses secure password hashing
    - Maintains proper role assignments
    - Follows Supabase security best practices
*/

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Drop existing objects if they exist
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS sync_auth_user_to_admin();

-- Create or replace the admin user
DO $$
BEGIN
  -- Only insert if the admin user doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM admin_users 
    WHERE email = 'admin@example.com'
  ) THEN
    INSERT INTO admin_users (
      id,
      email,
      password_hash,
      role,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      'admin@example.com',
      crypt('admin123', gen_salt('bf')),
      'admin',
      now(),
      now()
    );
  END IF;
END;
$$;