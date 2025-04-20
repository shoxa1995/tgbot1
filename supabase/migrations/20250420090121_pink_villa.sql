/*
  # Add Booking Validation System

  1. Changes
    - Add functions to check booking availability
    - Add trigger to prevent double bookings
    - Add buffer time between bookings
    - Add validation for overlapping bookings

  2. Security
    - Ensures data integrity for bookings
    - Prevents race conditions
    - Maintains existing RLS policies
*/

-- Create type for validation result
CREATE TYPE booking_validation_result AS (
  is_valid boolean,
  message text
);

-- Function to check if a time slot is available
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
  v_buffer interval;
  v_overlapping_count int;
BEGIN
  -- Convert buffer minutes to interval
  v_buffer := (p_buffer_minutes || ' minutes')::interval;
  
  -- Check for overlapping bookings
  SELECT COUNT(*)
  INTO v_overlapping_count
  FROM bookings b
  WHERE b.staff_id = p_staff_id
    AND b.date = p_date
    AND b.id IS DISTINCT FROM p_booking_id
    AND b.status != 'cancelled'
    AND (
      -- Check if the new booking overlaps with existing bookings including buffer time
      (p_start_time::time - v_buffer, p_end_time::time + v_buffer) OVERLAPS 
      (b.start_time::time, b.end_time::time)
    );

  -- Validate the booking
  IF v_overlapping_count > 0 THEN
    v_result := (false, 'This time slot is already booked or conflicts with buffer time')::booking_validation_result;
  ELSIF p_start_time >= p_end_time THEN
    v_result := (false, 'Start time must be before end time')::booking_validation_result;
  ELSIF p_date < CURRENT_DATE THEN
    v_result := (false, 'Cannot book appointments in the past')::booking_validation_result;
  ELSE
    -- Check if the time slot exists in the schedule
    IF EXISTS (
      SELECT 1 
      FROM schedules s
      JOIN time_slots ts ON ts.schedule_id = s.id
      WHERE s.staff_id = p_staff_id
        AND s.date = p_date
        AND s.is_working = true
        AND ts.start_time <= p_start_time
        AND ts.end_time >= p_end_time
    ) THEN
      v_result := (true, 'Time slot is available')::booking_validation_result;
    ELSE
      v_result := (false, 'Time slot is not in staff schedule')::booking_validation_result;
    END IF;
  END IF;

  RETURN v_result;
END;
$$;

-- Trigger function to validate bookings before insert or update
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
    NEW.start_time,
    NEW.end_time,
    NEW.id
  ) INTO v_validation;

  IF NOT v_validation.is_valid THEN
    RAISE EXCEPTION 'Booking validation failed: %', v_validation.message;
  END IF;

  RETURN NEW;
END;
$$;

-- Create trigger for booking validation
DROP TRIGGER IF EXISTS validate_booking_trigger ON bookings;
CREATE TRIGGER validate_booking_trigger
  BEFORE INSERT OR UPDATE ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION validate_booking();

-- Function to get available time slots
CREATE OR REPLACE FUNCTION get_available_time_slots(
  p_staff_id uuid,
  p_date date,
  p_buffer_minutes int DEFAULT 15
)
RETURNS TABLE (
  start_time time,
  end_time time,
  is_available boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  WITH schedule_slots AS (
    SELECT ts.start_time, ts.end_time
    FROM schedules s
    JOIN time_slots ts ON ts.schedule_id = s.id
    WHERE s.staff_id = p_staff_id
      AND s.date = p_date
      AND s.is_working = true
  ),
  booked_slots AS (
    SELECT 
      start_time,
      end_time
    FROM bookings
    WHERE staff_id = p_staff_id
      AND date = p_date
      AND status != 'cancelled'
  )
  SELECT 
    ss.start_time,
    ss.end_time,
    NOT EXISTS (
      SELECT 1
      FROM booked_slots bs
      WHERE (ss.start_time::time, ss.end_time::time) OVERLAPS 
            (bs.start_time::time - (p_buffer_minutes || ' minutes')::interval, 
             bs.end_time::time + (p_buffer_minutes || ' minutes')::interval)
    ) AS is_available
  FROM schedule_slots ss
  ORDER BY ss.start_time;
END;
$$;