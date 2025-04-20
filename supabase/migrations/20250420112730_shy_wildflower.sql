/*
  # Fix ambiguous column reference in get_available_time_slots function

  1. Changes
    - Update get_available_time_slots function to explicitly reference table names
    for start_time and end_time columns to resolve ambiguity
    - Add proper table aliases to improve query readability
    - Ensure proper handling of time slot availability checks

  2. Technical Details
    - Modify the function to use explicit table references
    - Update the query to properly join schedules and time slots
    - Maintain existing functionality while fixing the ambiguity issue
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
  WITH booked_slots AS (
    SELECT 
      b.start_time as booked_start,
      b.end_time as booked_end
    FROM bookings b
    WHERE 
      b.staff_id = p_staff_id 
      AND b.date = p_date
      AND b.status != 'cancelled'
  )
  SELECT 
    ts.start_time,
    ts.end_time,
    NOT EXISTS (
      SELECT 1 
      FROM booked_slots bs
      WHERE 
        (ts.start_time, ts.end_time) OVERLAPS 
        (
          bs.booked_start - (p_buffer_minutes || ' minutes')::interval,
          bs.booked_end + (p_buffer_minutes || ' minutes')::interval
        )
    ) as is_available
  FROM schedules s
  JOIN time_slots ts ON ts.schedule_id = s.id
  WHERE 
    s.staff_id = p_staff_id 
    AND s.date = p_date
    AND s.is_working = true
  ORDER BY ts.start_time;
END;
$$ LANGUAGE plpgsql;