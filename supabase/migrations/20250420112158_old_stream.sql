/*
  # Fix ambiguous column references in get_available_time_slots function

  1. Changes
    - Update get_available_time_slots function to properly qualify column references
    - Add table aliases for better readability
    - Ensure proper handling of time slot availability checks
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
BEGIN
  RETURN QUERY
  WITH staff_schedule AS (
    SELECT s.id as schedule_id, s.is_working
    FROM schedules s
    WHERE s.staff_id = p_staff_id 
    AND s.date = p_date
  ),
  all_slots AS (
    SELECT 
      ts.id as slot_id,
      ts.start_time,
      ts.end_time
    FROM staff_schedule ss
    JOIN time_slots ts ON ts.schedule_id = ss.schedule_id
    WHERE ss.is_working = true
  ),
  existing_bookings AS (
    SELECT 
      b.start_time as booking_start,
      b.end_time as booking_end
    FROM bookings b
    WHERE b.staff_id = p_staff_id
    AND b.date = p_date
    AND b.status != 'cancelled'
  )
  SELECT 
    s.start_time,
    s.end_time,
    NOT EXISTS (
      SELECT 1 
      FROM existing_bookings b
      WHERE (
        -- Check if the slot overlaps with any existing booking
        (s.start_time, s.end_time) OVERLAPS 
        (
          b.booking_start - (p_buffer_minutes || ' minutes')::interval,
          b.booking_end + (p_buffer_minutes || ' minutes')::interval
        )
      )
    ) as is_available
  FROM all_slots s
  ORDER BY s.start_time;
END;
$$ LANGUAGE plpgsql;