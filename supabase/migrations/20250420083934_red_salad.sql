/*
  # Fix booking policies to prevent recursion

  1. Changes
    - Drop existing problematic policies
    - Create new policies for admin and staff access
    - Create non-recursive policy for user bookings
    - Add proper overlap checking without recursion

  2. Security
    - Maintain existing security rules
    - Prevent double bookings without recursion
    - Keep admin and staff access intact
*/

-- Drop all existing policies on bookings
DO $$ 
BEGIN
  -- Drop policies if they exist
  IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname LIKE '%bookings%' AND tablename = 'bookings') THEN
    DROP POLICY IF EXISTS "Users can create their own bookings" ON bookings;
    DROP POLICY IF EXISTS "Users can read their own bookings" ON bookings;
    DROP POLICY IF EXISTS "Users can update their own bookings" ON bookings;
    DROP POLICY IF EXISTS "Users can delete their own bookings" ON bookings;
    DROP POLICY IF EXISTS "Admins can manage all bookings" ON bookings;
    DROP POLICY IF EXISTS "Staff can manage their assigned bookings" ON bookings;
  END IF;
END $$;

-- Create function to check for booking overlaps
CREATE OR REPLACE FUNCTION check_booking_overlap(
  p_staff_id uuid,
  p_date date,
  p_start_time time,
  p_end_time time,
  p_booking_id uuid DEFAULT NULL
) RETURNS boolean AS $$
BEGIN
  RETURN NOT EXISTS (
    SELECT 1 
    FROM bookings b
    WHERE b.staff_id = p_staff_id
    AND b.date = p_date
    AND b.id IS DISTINCT FROM p_booking_id
    AND (
      (p_start_time, p_end_time) OVERLAPS (b.start_time, b.end_time)
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create new policies
-- Admin policy
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

-- Staff policy
CREATE POLICY "Staff can manage assigned bookings"
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
  AND check_booking_overlap(staff_id, date, start_time, end_time, id)
);

-- User policies
CREATE POLICY "Users can read own bookings"
ON bookings
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can create own bookings"
ON bookings
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id
  AND check_booking_overlap(staff_id, date, start_time, end_time)
);

CREATE POLICY "Users can update own bookings"
ON bookings
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (
  auth.uid() = user_id
  AND check_booking_overlap(staff_id, date, start_time, end_time, id)
);

CREATE POLICY "Users can delete own bookings"
ON bookings
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);