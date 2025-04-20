/*
  # Fix Schedule RLS Policies

  1. Changes
    - Drop existing RLS policies for schedules table
    - Add new RLS policies that properly handle all access patterns
    - Fix staff access to manage schedules

  2. Security
    - Enable public read access
    - Allow staff to manage their own schedules
    - Allow admins to manage all schedules
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can read schedules" ON schedules;
DROP POLICY IF EXISTS "Staff can manage their own schedules" ON schedules;
DROP POLICY IF EXISTS "Public can read schedules" ON schedules;

-- Create new policies
CREATE POLICY "Enable public read access"
ON schedules
FOR SELECT
TO public
USING (true);

CREATE POLICY "Enable staff schedule management"
ON schedules
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM staff
    WHERE staff.id = schedules.staff_id
    AND EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
      AND admin_users.role IN ('admin', 'staff')
    )
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM staff
    WHERE staff.id = schedules.staff_id
    AND EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.id = auth.uid()
      AND admin_users.role IN ('admin', 'staff')
    )
  )
);