/*
  # Add admin login function
  
  1. Changes
    - Add function to handle admin user login
    - Add function to verify password
    - Update admin_users table with last_login timestamp
    
  2. Security
    - Uses secure password comparison
    - Updates login timestamp
    - Returns minimal user data
*/

-- Create admin login function
CREATE OR REPLACE FUNCTION admin_login(p_email text, p_password text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user admin_users;
  v_valid boolean;
BEGIN
  -- Get user by email
  SELECT * INTO v_user
  FROM admin_users
  WHERE email = p_email;
  
  -- Check if user exists
  IF v_user IS NULL THEN
    RETURN json_build_object(
      'error', 'Invalid email or password'
    );
  END IF;
  
  -- Verify password
  SELECT (v_user.password_hash = crypt(p_password, v_user.password_hash)) INTO v_valid;
  
  IF NOT v_valid THEN
    RETURN json_build_object(
      'error', 'Invalid email or password'
    );
  END IF;
  
  -- Update last login timestamp
  UPDATE admin_users
  SET last_login = now()
  WHERE id = v_user.id;
  
  -- Return user data
  RETURN json_build_object(
    'id', v_user.id,
    'email', v_user.email,
    'role', v_user.role
  );
END;
$$;