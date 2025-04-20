/*
  # Fix time slots table RLS policies

  1. Changes
    - Drop existing RLS policies for time_slots table
    - Add comprehensive policies for all operations
    - Enable public read access
    - Allow authenticated users to manage time slots
    
  2. Security
    - Public users can read time slots
    - Authenticated users can manage time slots
    - Maintains data integrity while allowing necessary operations
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can read time slots" ON time_slots;
DROP POLICY IF EXISTS "Enable public read access" ON time_slots;
DROP POLICY IF EXISTS "Enable authenticated users to manage time slots" ON time_slots;

-- Create new policies
CREATE POLICY "Enable public read access"
ON time_slots
FOR SELECT
TO public
USING (true);

CREATE POLICY "Enable authenticated users to manage time slots"
ON time_slots
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);