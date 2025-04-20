/*
  # Update Bookings Table RLS Policies

  1. Changes
    - Add new RLS policy to allow users to create their own bookings
    - Modify existing policies to be more specific about operations
    - Ensure proper access control for different user roles

  2. Security
    - Users can only create bookings for themselves
    - Users can only read their own bookings
    - Staff can manage bookings assigned to them
    - Admins retain full control over all bookings
*/

-- Drop existing policies to recreate them with proper permissions
DROP POLICY IF EXISTS "Users can create their own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can read own bookings" ON bookings;
DROP POLICY IF EXISTS "Admins can manage all bookings" ON bookings;
DROP POLICY IF EXISTS "Staff can read and update their assigned bookings" ON bookings;

-- Create new policies with proper permissions
CREATE POLICY "Users can create their own bookings"
ON bookings
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id
);

CREATE POLICY "Users can read their own bookings"
ON bookings
FOR SELECT
TO authenticated
USING (
  auth.uid() = user_id
);

CREATE POLICY "Admins can manage all bookings"
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

CREATE POLICY "Staff can manage their assigned bookings"
ON bookings
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE admin_users.id = auth.uid()
    AND admin_users.role = 'staff'
    AND bookings.staff_id IN (
      SELECT staff.id
      FROM staff
      WHERE staff.id = bookings.staff_id
    )
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE admin_users.id = auth.uid()
    AND admin_users.role = 'staff'
    AND bookings.staff_id IN (
      SELECT staff.id
      FROM staff
      WHERE staff.id = bookings.staff_id
    )
  )
);