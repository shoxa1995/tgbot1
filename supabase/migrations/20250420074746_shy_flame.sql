/*
  # Fix schedules table RLS policies

  1. Changes
    - Drop existing RLS policies for schedules table
    - Add new comprehensive RLS policies for schedule management
    - Enable proper access for staff and admin users

  2. Security
    - Staff can manage their own schedules
    - Admins can manage all schedules
    - Public read access maintained
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can read schedules" ON schedules;
DROP POLICY IF EXISTS "Staff can manage their own schedules" ON schedules;

-- Create new policies
CREATE POLICY "Enable public read access for schedules"
ON schedules FOR SELECT
TO public
USING (true);

CREATE POLICY "Enable staff schedule management"
ON schedules FOR ALL
TO authenticated
USING (
  staff_id = auth.uid() OR 
  EXISTS (
    SELECT 1 FROM admin_users 
    WHERE id = auth.uid() AND role = 'admin'
  )
)
WITH CHECK (
  staff_id = auth.uid() OR 
  EXISTS (
    SELECT 1 FROM admin_users 
    WHERE id = auth.uid() AND role = 'admin'
  )
);