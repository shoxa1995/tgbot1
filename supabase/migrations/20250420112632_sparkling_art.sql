/*
  # Fix schedule synchronization

  1. Changes
    - Fix the join between schedules and time slots in get_available_time_slots function
    - Add proper schedule validation
    - Ensure buffer time is correctly applied
    
  2. Security
    - Maintain existing security checks
    - Ensure data integrity
*/

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
DECLARE
  v_schedule_id uuid;
BEGIN
  -- First get the schedule ID for the given staff and date
  SELECT id INTO v_schedule_id
  FROM schedules
  WHERE staff_id = p_staff_id 
  AND date = p_date
  AND is_working = true;

  -- If no schedule exists or staff is not working, return empty result
  IF v_schedule_id IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH time_slot_ranges AS (
    -- Get all time slots for the schedule
    SELECT 
      ts.start_time,
      ts.end_time
    FROM time_slots ts
    WHERE ts.schedule_id = v_schedule_id
  ),
  booked_ranges AS (
    -- Get all booked time ranges including buffer
    SELECT 
      (start_time - (p_buffer_minutes || ' minutes')::interval)::time as buffer_start,
      (end_time + (p_buffer_minutes || ' minutes')::interval)::time as buffer_end
    FROM bookings
    WHERE staff_id = p_staff_id
    AND date = p_date
    AND status != 'cancelled'
  )
  SELECT 
    tsr.start_time,
    tsr.end_time,
    NOT EXISTS (
      SELECT 1 
      FROM booked_ranges br
      WHERE (tsr.start_time, tsr.end_time) OVERLAPS (br.buffer_start, br.buffer_end)
    ) as is_available
  FROM time_slot_ranges tsr
  ORDER BY tsr.start_time;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update the booking validation function to use the same logic
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
  v_schedule_id uuid;
BEGIN
  -- First check if there's a valid schedule
  SELECT id INTO v_schedule_id
  FROM schedules
  WHERE staff_id = p_staff_id 
  AND date = p_date
  AND is_working = true;

  IF v_schedule_id IS NULL THEN
    RETURN (false, 'No available schedule for this date')::booking_validation_result;
  END IF;

  -- Check if the requested time slot exists in the schedule
  IF NOT EXISTS (
    SELECT 1
    FROM time_slots
    WHERE schedule_id = v_schedule_id
    AND start_time <= p_start_time
    AND end_time >= p_end_time
  ) THEN
    RETURN (false, 'Requested time slot is not in the schedule')::booking_validation_result;
  END IF;

  -- Check for overlapping bookings
  IF EXISTS (
    SELECT 1
    FROM bookings b
    WHERE b.staff_id = p_staff_id
    AND b.date = p_date
    AND b.id IS DISTINCT FROM p_booking_id
    AND b.status != 'cancelled'
    AND (
      (p_start_time - (p_buffer_minutes || ' minutes')::interval,
       p_end_time + (p_buffer_minutes || ' minutes')::interval)
      OVERLAPS
      (b.start_time, b.end_time)
    )
  ) THEN
    RETURN (false, 'Time slot conflicts with existing booking')::booking_validation_result;
  END IF;

  -- All checks passed
  RETURN (true, 'Time slot is available')::booking_validation_result;
END;
$$;