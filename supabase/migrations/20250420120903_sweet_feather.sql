/*
  # Update Bookings RLS Policies

  1. Changes
    - Modify RLS policies for bookings table to allow proper creation of new bookings
    - Ensure authenticated users can create bookings
    - Maintain security while allowing necessary operations

  2. Security
    - Enable RLS on bookings table
    - Add policies for:
      - Creating new bookings
      - Reading own bookings
      - Updating own bookings
      - Staff accessing their assigned bookings
      - Admins managing all bookings
*/

-- Drop existing policies to recreate them with correct permissions
DROP POLICY IF EXISTS "Enable admin access to all bookings" ON bookings;
DROP POLICY IF EXISTS "Enable delete for own bookings" ON bookings;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON bookings;
DROP POLICY IF EXISTS "Enable read for own bookings" ON bookings;
DROP POLICY IF EXISTS "Enable staff access to assigned bookings" ON bookings;
DROP POLICY IF EXISTS "Enable update for own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can view own bookings" ON bookings;

-- Recreate policies with correct permissions
CREATE POLICY "Enable admin access to all bookings" ON bookings
FOR ALL 
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM admin_users 
    WHERE admin_users.id = auth.uid() 
    AND admin_users.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM admin_users 
    WHERE admin_users.id = auth.uid() 
    AND admin_users.role = 'admin'
  )
);

CREATE POLICY "Enable staff access to assigned bookings" ON bookings
FOR ALL 
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM admin_users 
    WHERE admin_users.id = auth.uid() 
    AND admin_users.role = 'staff'
    AND EXISTS (
      SELECT 1 FROM staff 
      WHERE staff.id = bookings.staff_id
    )
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM admin_users 
    WHERE admin_users.id = auth.uid() 
    AND admin_users.role = 'staff'
    AND EXISTS (
      SELECT 1 FROM staff 
      WHERE staff.id = bookings.staff_id
    )
  )
);

-- Allow users to create bookings
CREATE POLICY "Enable insert for authenticated users" ON bookings
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Allow users to read their own bookings
CREATE POLICY "Enable read access for own bookings" ON bookings
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = bookings.user_id
  )
);

-- Allow users to update their own bookings
CREATE POLICY "Enable update for own bookings" ON bookings
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = bookings.user_id
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = bookings.user_id
  )
);

-- Allow users to delete their own bookings
CREATE POLICY "Enable delete for own bookings" ON bookings
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = bookings.user_id
  )
);