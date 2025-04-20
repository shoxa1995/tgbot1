/*
  # Fix users table RLS policies

  1. Changes
    - Drop existing RLS policies on users table
    - Add new policies to allow:
      - Authenticated users to create user records
      - Public read access for user data
      - Users to update their own records

  2. Security
    - Maintains data integrity while allowing necessary operations
    - Restricts users to managing only their own data
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can read own data" ON users;

-- Create new policies
CREATE POLICY "Enable insert for authenticated users"
ON users FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Enable read access for all users"
ON users FOR SELECT
TO public
USING (true);

CREATE POLICY "Enable update for own records"
ON users FOR UPDATE
TO authenticated
USING (auth.uid()::text = telegram_id)
WITH CHECK (auth.uid()::text = telegram_id);