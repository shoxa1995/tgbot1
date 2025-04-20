/*
  # Create default admin user

  1. Changes
    - Add default admin user with email 'admin@example.com'
    - Password hash is for 'admin123' (using bcrypt)
    - Set role as 'admin'
  
  2. Security
    - Uses secure password hashing
    - Sets appropriate role for admin access
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
      '$2a$10$5S1dZHtGxoWxK5N5QlF7GOi8J8b4qHJ9TaF9TJcLXB.h8U3UHgyEe', -- bcrypt hash for 'admin123'
      'admin'
    );
  END IF;
END $$;