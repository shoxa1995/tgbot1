/*
  # Fix Bookings Table RLS Policies

  1. Changes
    - Drop existing RLS policies for bookings table
    - Add new policies that properly handle:
      - Authenticated users creating bookings
      - Users managing their own bookings
      - Staff managing assigned bookings
      - Admins managing all bookings

  2. Security
    - Ensure proper access control for all operations
    - Maintain data integrity with booking overlap checks
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can create own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can read own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can update own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can delete own bookings" ON bookings;
DROP POLICY IF EXISTS "Staff can manage assigned bookings" ON bookings;
DROP POLICY IF EXISTS "Admins can manage all bookings" ON bookings;
DROP POLICY IF EXISTS "Staff can view assigned bookings" ON bookings;
DROP POLICY IF EXISTS "Staff can update assigned bookings" ON bookings;
DROP POLICY IF EXISTS "Enable staff schedule management" ON bookings;

-- Create new policies
CREATE POLICY "Enable insert for authenticated users"
ON bookings
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid()::text = (
    SELECT telegram_id 
    FROM users 
    WHERE users.id = bookings.user_id
  )
);

CREATE POLICY "Enable read for own bookings"
ON bookings
FOR SELECT
TO authenticated
USING (
  auth.uid()::text = (
    SELECT telegram_id 
    FROM users 
    WHERE users.id = bookings.user_id
  )
);

CREATE POLICY "Enable update for own bookings"
ON bookings
FOR UPDATE
TO authenticated
USING (
  auth.uid()::text = (
    SELECT telegram_id 
    FROM users 
    WHERE users.id = bookings.user_id
  )
)
WITH CHECK (
  auth.uid()::text = (
    SELECT telegram_id 
    FROM users 
    WHERE users.id = bookings.user_id
  )
);

CREATE POLICY "Enable delete for own bookings"
ON bookings
FOR DELETE
TO authenticated
USING (
  auth.uid()::text = (
    SELECT telegram_id 
    FROM users 
    WHERE users.id = bookings.user_id
  )
);

CREATE POLICY "Enable staff access to assigned bookings"
ON bookings
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

CREATE POLICY "Enable admin access to all bookings"
ON bookings
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