-- Drop existing policies and function
DROP POLICY IF EXISTS "Admins can manage all bookings" ON bookings;
DROP POLICY IF EXISTS "Staff can manage assigned bookings" ON bookings;
DROP POLICY IF EXISTS "Users can read own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can create own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can update own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can delete own bookings" ON bookings;
DROP FUNCTION IF EXISTS check_booking_overlap;

-- Create improved booking overlap check function
CREATE OR REPLACE FUNCTION check_booking_overlap(
  p_staff_id uuid,
  p_date date,
  p_start_time time,
  p_end_time time,
  p_booking_id uuid DEFAULT NULL
) RETURNS boolean AS $$
DECLARE
  v_exists boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 
    FROM bookings b
    WHERE b.staff_id = p_staff_id
    AND b.date = p_date
    AND b.id IS DISTINCT FROM p_booking_id
    AND b.status != 'cancelled'
    AND (
      (p_start_time, p_end_time) OVERLAPS (b.start_time, b.end_time)
    )
  ) INTO v_exists;
  
  RETURN NOT v_exists;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create new policies with proper permissions
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

CREATE POLICY "Staff can manage assigned bookings"
ON bookings
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE admin_users.id = auth.uid()
    AND admin_users.role = 'staff'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE admin_users.id = auth.uid()
    AND admin_users.role = 'staff'
  )
  AND check_booking_overlap(staff_id, date, start_time, end_time, id)
);

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