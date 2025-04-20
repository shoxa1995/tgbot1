/*
  # Fix booking validation and time slot availability

  1. Changes
    - Drop and recreate get_available_time_slots function with proper column references
    - Update check_booking_availability function to handle edge cases
    - Add proper type casting for time comparisons
    
  2. Security
    - Maintain existing security policies
    - Ensure proper validation of bookings
*/

-- Drop existing functions
DROP FUNCTION IF EXISTS get_available_time_slots(uuid, date, integer);
DROP FUNCTION IF EXISTS check_booking_availability(uuid, date, time, time, uuid, integer);

-- Recreate get_available_time_slots with fixed column references
CREATE OR REPLACE FUNCTION get_available_time_slots(
  p_staff_id uuid,
  p_date date,
  p_buffer_minutes integer DEFAULT 15
)
RETURNS TABLE (
  start_time time,
  end_time time,
  is_available boolean
) AS $$
BEGIN
  RETURN QUERY
  WITH schedule_slots AS (
    -- Get all time slots from the schedule
    SELECT 
      ts.start_time::time as slot_start,
      ts.end_time::time as slot_end
    FROM schedules s
    JOIN time_slots ts ON ts.schedule_id = s.id
    WHERE 
      s.staff_id = p_staff_id 
      AND s.date = p_date
      AND s.is_working = true
  ),
  booked_slots AS (
    -- Get all booked slots with buffer
    SELECT 
      (b.start_time - (p_buffer_minutes || ' minutes')::interval)::time as buffer_start,
      (b.end_time + (p_buffer_minutes || ' minutes')::interval)::time as buffer_end
    FROM bookings b
    WHERE 
      b.staff_id = p_staff_id 
      AND b.date = p_date
      AND b.status != 'cancelled'
  )
  SELECT 
    ss.slot_start as start_time,
    ss.slot_end as end_time,
    NOT EXISTS (
      SELECT 1 
      FROM booked_slots bs
      WHERE 
        (ss.slot_start, ss.slot_end) OVERLAPS (bs.buffer_start, bs.buffer_end)
    ) as is_available
  FROM schedule_slots ss
  ORDER BY ss.slot_start;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate check_booking_availability with improved validation
CREATE OR REPLACE FUNCTION check_booking_availability(
  p_staff_id uuid,
  p_date date,
  p_start_time time,
  p_end_time time,
  p_booking_id uuid DEFAULT NULL,
  p_buffer_minutes int DEFAULT 15
)
RETURNS booking_validation_result
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result booking_validation_result;
  v_schedule_exists boolean;
  v_slot_exists boolean;
BEGIN
  -- Check if schedule exists
  SELECT EXISTS (
    SELECT 1
    FROM schedules s
    WHERE 
      s.staff_id = p_staff_id 
      AND s.date = p_date
      AND s.is_working = true
  ) INTO v_schedule_exists;

  IF NOT v_schedule_exists THEN
    RETURN (false, 'No available schedule for this date')::booking_validation_result;
  END IF;

  -- Check if time slot exists in schedule
  SELECT EXISTS (
    SELECT 1
    FROM schedules s
    JOIN time_slots ts ON ts.schedule_id = s.id
    WHERE 
      s.staff_id = p_staff_id 
      AND s.date = p_date
      AND s.is_working = true
      AND ts.start_time <= p_start_time::time
      AND ts.end_time >= p_end_time::time
  ) INTO v_slot_exists;

  IF NOT v_slot_exists THEN
    RETURN (false, 'Requested time slot is not in the schedule')::booking_validation_result;
  END IF;

  -- Check for overlapping bookings
  IF EXISTS (
    SELECT 1
    FROM bookings b
    WHERE 
      b.staff_id = p_staff_id
      AND b.date = p_date
      AND b.id IS DISTINCT FROM p_booking_id
      AND b.status != 'cancelled'
      AND (
        (p_start_time::time - (p_buffer_minutes || ' minutes')::interval,
         p_end_time::time + (p_buffer_minutes || ' minutes')::interval)
        OVERLAPS
        (b.start_time::time, b.end_time::time)
      )
  ) THEN
    RETURN (false, 'Time slot conflicts with existing booking')::booking_validation_result;
  END IF;

  -- All checks passed
  RETURN (true, 'Time slot is available')::booking_validation_result;
END;
$$;

-- Update the validate_booking trigger function
CREATE OR REPLACE FUNCTION validate_booking()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_validation booking_validation_result;
BEGIN
  -- Skip validation for cancelled bookings
  IF NEW.status = 'cancelled' THEN
    RETURN NEW;
  END IF;

  -- Check booking availability
  SELECT * FROM check_booking_availability(
    NEW.staff_id,
    NEW.date,
    NEW.start_time::time,
    NEW.end_time::time,
    NEW.id
  ) INTO v_validation;

  IF NOT v_validation.is_valid THEN
    RAISE EXCEPTION 'Booking validation failed: %', v_validation.message;
  END IF;

  RETURN NEW;
END;
$$;