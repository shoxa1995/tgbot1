/*
  # Fix staff table RLS policies

  1. Changes
    - Drop existing SELECT policy and create a new one that explicitly allows public access
    - This ensures anyone can read staff data without authentication

  2. Security
    - Enables public read access to staff data
    - Maintains existing authenticated-only policies for INSERT/UPDATE/DELETE
*/

-- Drop the existing SELECT policy
DROP POLICY IF EXISTS "Enable read access for all users" ON "public"."staff";

-- Create a new SELECT policy that explicitly allows public access
CREATE POLICY "Enable public read access for staff" 
ON "public"."staff"
FOR SELECT 
TO public
USING (true);