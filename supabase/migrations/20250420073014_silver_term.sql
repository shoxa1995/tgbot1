/*
  # Add default admin user

  1. Changes
    - Add default admin user with email 'admin@example.com'
    - Password will be 'admin123'
    - Role set to 'admin'
    
  2. Security
    - Password is properly hashed using pgcrypto
    - User has admin role for full system access
*/

DO $$ 
BEGIN 
  -- Only insert if the admin user doesn't exist
  IF NOT EXISTS (SELECT 1 FROM admin_users WHERE email = 'admin@example.com') THEN
    INSERT INTO admin_users (
      email,
      password_hash,
      role,
      created_at,
      updated_at
    ) VALUES (
      'admin@example.com',
      crypt('admin123', gen_salt('bf')),
      'admin',
      now(),
      now()
    );
  END IF;
END $$;