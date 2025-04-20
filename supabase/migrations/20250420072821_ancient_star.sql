/*
  # Add default admin user

  1. Changes
    - Add default admin user with email 'admin@example.com'
    - Password hash is for 'admin123'
    - Set role as 'admin'
    
  2. Security
    - Uses secure password hashing
    - Sets proper admin role
*/

DO $$ 
BEGIN 
  IF NOT EXISTS (
    SELECT 1 FROM admin_users WHERE email = 'admin@example.com'
  ) THEN
    INSERT INTO admin_users (
      email,
      password_hash,
      role
    ) VALUES (
      'admin@example.com',
      -- This is a secure hash of 'admin123'
      '$2a$10$RgZM5fXyxZwE8Pg5QX9IQOzyl6S1h.7nkRFJTXu1jUxz3ZxhHweXi',
      'admin'
    );
  END IF;
END $$;