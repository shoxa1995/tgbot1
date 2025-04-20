/*
  # Fix admin user authentication

  1. Changes
    - Enable pgcrypto extension for password hashing
    - Create function to handle admin user creation
    - Create admin user with proper authentication
    - Add trigger to sync auth.users with admin_users
    - Fix password_hash sync from auth.users

  2. Security
    - Uses Supabase's built-in auth system
    - Maintains password security
    - Ensures proper role assignment
*/

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create function to sync auth user with admin_users
CREATE OR REPLACE FUNCTION sync_auth_user_to_admin()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.raw_app_meta_data->>'role' = 'admin' THEN
    INSERT INTO public.admin_users (
      id,
      email,
      password_hash,
      role,
      created_at,
      updated_at
    ) VALUES (
      NEW.id,
      NEW.email,
      NEW.encrypted_password,
      'admin',
      NEW.created_at,
      NEW.updated_at
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to sync auth users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION sync_auth_user_to_admin();

-- Create the admin user
DO $$
DECLARE
  admin_user_id uuid;
  encrypted_pwd text;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM auth.users WHERE email = 'admin@example.com'
  ) THEN
    -- Generate encrypted password
    encrypted_pwd := crypt('admin123', gen_salt('bf'));

    -- Insert into auth.users
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      confirmation_token,
      email_change,
      email_change_token_new,
      recovery_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      gen_random_uuid(),
      'authenticated',
      'authenticated',
      'admin@example.com',
      encrypted_pwd,
      now(),
      '{"role": "admin"}'::jsonb,
      '{}'::jsonb,
      now(),
      now(),
      '',
      '',
      '',
      ''
    ) RETURNING id INTO admin_user_id;

    -- The trigger will automatically create the admin_users record
  END IF;
END;
$$;