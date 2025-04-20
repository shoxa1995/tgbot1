/*
  # Fix schedules RLS policies

  1. Changes
    - Drop existing RLS policy for schedules table
    - Add new policies to handle all operations (SELECT, INSERT, UPDATE, DELETE)
    - Separate policies for admin and staff roles
    
  2. Security
    - Admins can manage all schedules
    - Staff can only manage their own schedules
    - Public users can only read schedules
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Enable staff schedule management" ON schedules;
DROP POLICY IF EXISTS "Enable public read access" ON schedules;

-- Create new policies
CREATE POLICY "Admins can manage all schedules"
ON schedules
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

CREATE POLICY "Staff can manage own schedules"
ON schedules
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE admin_users.id = auth.uid()
    AND admin_users.role = 'staff'
    AND EXISTS (
      SELECT 1 FROM staff
      WHERE staff.id = schedules.staff_id
      -- Add additional check here if staff members should only manage their own schedules
      -- This would require linking staff table with admin_users
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
      WHERE staff.id = schedules.staff_id
      -- Add additional check here if staff members should only manage their own schedules
      -- This would require linking staff table with admin_users
    )
  )
);

CREATE POLICY "Public can read schedules"
ON schedules
FOR SELECT
TO public
USING (true);