/*
  # Fix Booking Validation

  1. Changes
    - Add composite type for validation result
    - Drop objects in correct dependency order
    - Recreate functions with improved validation
    
  2. Security
    - Maintain existing security policies
    - Ensure proper validation of all booking requests
*/

-- Create composite type if it doesn't exist
DO $$ BEGIN
  CREATE TYPE booking_validation_result AS (
    is_valid boolean,
    message text
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Drop objects in correct order
DROP TRIGGER IF EXISTS validate_booking_trigger ON bookings;
DROP FUNCTION IF EXISTS validate_booking();
DROP FUNCTION IF EXISTS check_booking_availability(uuid, date, time, time, uuid, integer);
DROP FUNCTION IF EXISTS get_available_time_slots(uuid, date, integer);

-- Create improved get_available_time_slots function
CREATE OR REPLACE FUNCTION get_available_time_slots(
  p_staff_id uuid,
  p_date date,
  p_buffer_minutes integer DEFAULT 15
)
RETURNS TABLE (
  start_time time without time zone,
  end_time time without time zone,
  is_available boolean
) AS $$
BEGIN
  RETURN QUERY
  WITH schedule_slots AS (
    -- Get all time slots from the schedule
    SELECT 
      ts.start_time::time without time zone as slot_start,
      ts.end_time::time without time zone as slot_end
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
      (b.start_time - make_interval(mins := p_buffer_minutes))::time without time zone as buffer_start,
      (b.end_time + make_interval(mins := p_buffer_minutes))::time without time zone as buffer_end
    FROM bookings b
    WHERE 
      b.staff_id = p_staff_id 
      AND b.date = p_date
      AND b.status != 'cancelled'
  )
  SELECT 
    ss.slot_start,
    ss.slot_end,
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

-- Create improved check_booking_availability function
CREATE OR REPLACE FUNCTION check_booking_availability(
  p_staff_id uuid,
  p_date date,
  p_start_time time without time zone,
  p_end_time time without time zone,
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
  v_buffer interval;
BEGIN
  -- Basic validation
  IF p_start_time >= p_end_time THEN
    RETURN (false, 'Start time must be before end time')::booking_validation_result;
  END IF;

  IF p_date < CURRENT_DATE THEN
    RETURN (false, 'Cannot book appointments in the past')::booking_validation_result;
  END IF;

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
      AND ts.start_time <= p_start_time
      AND ts.end_time >= p_end_time
  ) INTO v_slot_exists;

  IF NOT v_slot_exists THEN
    RETURN (false, 'Requested time slot is not in the schedule')::booking_validation_result;
  END IF;

  -- Calculate buffer interval
  v_buffer := make_interval(mins := p_buffer_minutes);

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
        (p_start_time - v_buffer, p_end_time + v_buffer)
        OVERLAPS
        (b.start_time::time without time zone, b.end_time::time without time zone)
      )
  ) THEN
    RETURN (false, 'Time slot conflicts with existing booking')::booking_validation_result;
  END IF;

  -- All checks passed
  RETURN (true, 'Time slot is available')::booking_validation_result;
END;
$$;

-- Create improved validate_booking trigger function
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

  -- Basic validation
  IF NEW.start_time >= NEW.end_time THEN
    RAISE EXCEPTION 'Start time must be before end time';
  END IF;

  IF NEW.date < CURRENT_DATE THEN
    RAISE EXCEPTION 'Cannot book appointments in the past';
  END IF;

  -- Check booking availability
  SELECT * FROM check_booking_availability(
    NEW.staff_id,
    NEW.date,
    NEW.start_time::time without time zone,
    NEW.end_time::time without time zone,
    NEW.id
  ) INTO v_validation;

  IF NOT v_validation.is_valid THEN
    RAISE EXCEPTION 'Booking validation failed: %', v_validation.message;
  END IF;

  RETURN NEW;
END;
$$;

-- Create the trigger
CREATE TRIGGER validate_booking_trigger
  BEFORE INSERT OR UPDATE ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION validate_booking();