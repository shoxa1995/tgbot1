/*
  # Fix schedules RLS policies

  1. Changes
    - Drop existing RLS policies for schedules table that are causing issues
    - Add new RLS policies that properly handle staff schedule management:
      - Staff can manage their own schedules
      - Admin users can manage all schedules
      - Anyone can read schedules (already exists)

  2. Security
    - Ensures staff members can only manage their own schedules
    - Maintains public read access
    - Adds admin override capability
*/

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Staff can create their own schedules" ON schedules;
DROP POLICY IF EXISTS "Staff can delete their own schedules" ON schedules;
DROP POLICY IF EXISTS "Staff can update their own schedules" ON schedules;

-- Create new comprehensive policies
CREATE POLICY "Staff can manage their own schedules"
ON schedules
USING (
  (staff_id = auth.uid()) OR
  ((SELECT role FROM admin_users WHERE id = auth.uid()) = 'admin')
)
WITH CHECK (
  (staff_id = auth.uid()) OR
  ((SELECT role FROM admin_users WHERE id = auth.uid()) = 'admin')
);

-- Note: Keeping the existing public read policy
-- "Anyone can read schedules" policy should already exist