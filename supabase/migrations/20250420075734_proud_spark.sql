/*
  # Fix schedules table RLS policies

  1. Changes
    - Drop all existing RLS policies for schedules table
    - Add new comprehensive policies for all operations
    - Enable public read access
    - Allow authenticated users to manage schedules
    
  2. Security
    - Public users can read schedules
    - Authenticated users can manage schedules
    - Maintains data integrity while allowing necessary operations
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can read schedules" ON schedules;
DROP POLICY IF EXISTS "Admins can manage all schedules" ON schedules;
DROP POLICY IF EXISTS "Staff can manage own schedules" ON schedules;
DROP POLICY IF EXISTS "Public can read schedules" ON schedules;

-- Create new policies
CREATE POLICY "Enable public read access"
ON schedules
FOR SELECT
TO public
USING (true);

CREATE POLICY "Enable authenticated users to manage schedules"
ON schedules
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);