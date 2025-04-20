/*
  # Add RLS policies for bookings table

  1. Security Changes
    - Add RLS policies for the bookings table to allow:
      - Users to create their own bookings
      - Users to read their own bookings (already exists)
      - Staff to read and update bookings assigned to them
      - Admins to manage all bookings
*/

-- Policy for users to create their own bookings
CREATE POLICY "Users can create their own bookings"
ON public.bookings
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id
);

-- Policy for staff to read and update their bookings
CREATE POLICY "Staff can read and update their assigned bookings"
ON public.bookings
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE admin_users.id = auth.uid()
    AND admin_users.role = 'staff'
    AND bookings.staff_id IN (
      SELECT id FROM staff WHERE staff.id = bookings.staff_id
    )
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE admin_users.id = auth.uid()
    AND admin_users.role = 'staff'
    AND bookings.staff_id IN (
      SELECT id FROM staff WHERE staff.id = bookings.staff_id
    )
  )
);

-- Policy for admins to manage all bookings
CREATE POLICY "Admins can manage all bookings"
ON public.bookings
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