/*
  # Fix staff table RLS policies

  1. Changes
    - Drop existing RLS policies on staff table
    - Create new, properly configured RLS policies
      - Enable public read access
      - Restrict write operations to authenticated users

  2. Security
    - Ensures anyone can read staff data
    - Maintains write protection for authenticated users only
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can read staff" ON staff;
DROP POLICY IF EXISTS "Authenticated users can delete staff" ON staff;
DROP POLICY IF EXISTS "Authenticated users can insert staff" ON staff;
DROP POLICY IF EXISTS "Authenticated users can update staff" ON staff;

-- Create new policies
CREATE POLICY "Enable read access for all users"
ON staff FOR SELECT
TO public
USING (true);

CREATE POLICY "Enable insert for authenticated users only"
ON staff FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Enable update for authenticated users only"
ON staff FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Enable delete for authenticated users only"
ON staff FOR DELETE
TO authenticated
USING (true);