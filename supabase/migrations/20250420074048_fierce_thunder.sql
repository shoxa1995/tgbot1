/*
  # Add RLS policies for schedules table

  1. Changes
    - Add INSERT policy for authenticated users to create schedules for their staff ID
    - Add UPDATE policy for authenticated users to modify schedules for their staff ID
    - Add DELETE policy for authenticated users to remove schedules for their staff ID

  2. Security
    - Policies ensure users can only manage schedules where they are the staff member
    - Maintains existing SELECT policy for public read access
*/

-- Allow staff to create their own schedules
CREATE POLICY "Staff can create their own schedules"
ON public.schedules
FOR INSERT
TO authenticated
WITH CHECK (staff_id = auth.uid());

-- Allow staff to update their own schedules
CREATE POLICY "Staff can update their own schedules"
ON public.schedules
FOR UPDATE
TO authenticated
USING (staff_id = auth.uid())
WITH CHECK (staff_id = auth.uid());

-- Allow staff to delete their own schedules
CREATE POLICY "Staff can delete their own schedules"
ON public.schedules
FOR DELETE
TO authenticated
USING (staff_id = auth.uid());