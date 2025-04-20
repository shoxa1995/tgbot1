/*
  # Fix bookings table RLS policies

  1. Changes
    - Drop existing RLS policies for bookings table
    - Create new, properly structured RLS policies that:
      - Allow users to create and manage their own bookings
      - Allow staff to manage their assigned bookings
      - Allow admins to manage all bookings
    
  2. Security
    - Policies ensure users can only access their own bookings
    - Staff can only access bookings assigned to them
    - Admins have full access to all bookings
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can create own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can read own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can update own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can delete own bookings" ON bookings;
DROP POLICY IF EXISTS "Staff can manage assigned bookings" ON bookings;
DROP POLICY IF EXISTS "Admins can manage all bookings" ON bookings;

-- Create new policies
-- Users policies
CREATE POLICY "Users can create own bookings" 
ON bookings FOR INSERT 
TO authenticated
WITH CHECK (
  auth.uid() = user_id AND
  check_booking_overlap(staff_id, date, start_time, end_time)
);

CREATE POLICY "Users can view own bookings" 
ON bookings FOR SELECT 
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can update own bookings" 
ON bookings FOR UPDATE 
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (
  auth.uid() = user_id AND
  check_booking_overlap(staff_id, date, start_time, end_time, id)
);

CREATE POLICY "Users can delete own bookings" 
ON bookings FOR DELETE 
TO authenticated
USING (auth.uid() = user_id);

-- Staff policies
CREATE POLICY "Staff can view assigned bookings" 
ON bookings FOR SELECT 
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM admin_users 
    WHERE admin_users.id = auth.uid() 
    AND admin_users.role = 'staff'
    AND bookings.staff_id IN (
      SELECT id FROM staff 
      WHERE staff.id = bookings.staff_id
    )
  )
);

CREATE POLICY "Staff can update assigned bookings" 
ON bookings FOR UPDATE 
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM admin_users 
    WHERE admin_users.id = auth.uid() 
    AND admin_users.role = 'staff'
    AND bookings.staff_id IN (
      SELECT id FROM staff 
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
      SELECT id FROM staff 
      WHERE staff.id = bookings.staff_id
    )
  ) AND
  check_booking_overlap(staff_id, date, start_time, end_time, id)
);

-- Admin policies
CREATE POLICY "Admins can manage all bookings" 
ON bookings FOR ALL 
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