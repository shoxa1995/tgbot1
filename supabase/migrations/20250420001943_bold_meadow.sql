/*
  # Update staff table RLS policies

  1. Changes
    - Modify SELECT policy to allow public read access to staff table
    - Keep existing policies for INSERT, UPDATE, and DELETE

  2. Security
    - Enable public read access to staff information
    - Maintain authenticated-only access for modifications
*/

-- Drop existing SELECT policy
DROP POLICY IF EXISTS "Anyone can read staff" ON public.staff;

-- Create new public read policy
CREATE POLICY "Anyone can read staff" 
ON public.staff
FOR SELECT 
USING (true);