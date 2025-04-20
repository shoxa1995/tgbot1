/*
  # Fix Schedule RLS Policies

  1. Changes
    - Drop existing RLS policies for schedules table
    - Add new comprehensive RLS policies for schedules table that properly handle:
      - Staff members managing their own schedules
      - Admins managing all schedules
      - Public read access for available schedules

  2. Security
    - Enable RLS on schedules table (already enabled)
    - Add policies for:
      - Staff reading and managing their own schedules
      - Admins managing all schedules
      - Public read access
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Enable staff schedule management" ON schedules;
DROP POLICY IF EXISTS "Enable public read access for schedules" ON schedules;

-- Add new policies
CREATE POLICY "Staff can manage their own schedules"
ON schedules
FOR ALL
TO authenticated
USING (
  staff_id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE admin_users.id = auth.uid()
    AND admin_users.role IN ('admin', 'staff')
  )
)
WITH CHECK (
  staff_id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE admin_users.id = auth.uid()
    AND admin_users.role IN ('admin', 'staff')
  )
);

CREATE POLICY "Public can read schedules"
ON schedules
FOR SELECT
TO public
USING (true);