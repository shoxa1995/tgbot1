/*
  # Fix Bookings RLS Policies

  1. Changes
    - Update RLS policies for the bookings table to allow users to create their own bookings
    - Add policy for users to update their own bookings
    - Add policy for users to delete their own bookings

  2. Security
    - Ensure users can only manage their own bookings
    - Maintain existing admin and staff policies
    - Add explicit policies for all CRUD operations
*/

-- Drop existing user-related policies if they exist
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'bookings' 
    AND policyname = 'Users can create their own bookings'
  ) THEN
    DROP POLICY "Users can create their own bookings" ON public.bookings;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'bookings' 
    AND policyname = 'Users can read their own bookings'
  ) THEN
    DROP POLICY "Users can read their own bookings" ON public.bookings;
  END IF;
END $$;

-- Create comprehensive policies for users
CREATE POLICY "Users can create their own bookings" ON public.bookings
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = user_id
    AND NOT EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.staff_id = bookings.staff_id
      AND b.date = bookings.date
      AND (
        (b.start_time, b.end_time) OVERLAPS (bookings.start_time, bookings.end_time)
      )
    )
  );

CREATE POLICY "Users can read their own bookings" ON public.bookings
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own bookings" ON public.bookings
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own bookings" ON public.bookings
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);