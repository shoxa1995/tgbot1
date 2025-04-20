/*
  # Fix Schedule RLS Policies

  1. Changes
    - Drop existing RLS policies on schedules table
    - Add new policies that properly handle staff and admin access
    - Ensure public read access is maintained
    - Fix policy conditions to work with admin_users table

  2. Security
    - Public can read all schedules
    - Staff members can manage schedules for any staff
    - Admins can manage all schedules
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Enable public read access" ON schedules;
DROP POLICY IF EXISTS "Enable staff schedule management" ON schedules;

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
    SELECT 1
    FROM admin_users
    WHERE admin_users.id = auth.uid()
    AND admin_users.role = ANY (ARRAY['admin'::text, 'staff'::text])
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM admin_users
    WHERE admin_users.id = auth.uid()
    AND admin_users.role = ANY (ARRAY['admin'::text, 'staff'::text])
  )
);