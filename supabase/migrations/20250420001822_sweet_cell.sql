/*
  # Add RLS policies for staff table

  1. Changes
    - Add RLS policies for INSERT, UPDATE, and DELETE operations on staff table
    - Keep existing SELECT policy

  2. Security
    - Authenticated users can read staff data (existing policy)
    - Only authenticated users can manage staff data
*/

-- Add policy for inserting staff
CREATE POLICY "Authenticated users can insert staff"
ON public.staff
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Add policy for updating staff
CREATE POLICY "Authenticated users can update staff"
ON public.staff
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Add policy for deleting staff
CREATE POLICY "Authenticated users can delete staff"
ON public.staff
FOR DELETE
TO authenticated
USING (true);