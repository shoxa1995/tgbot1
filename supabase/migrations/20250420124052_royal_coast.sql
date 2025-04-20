/*
  # Add Bot Integration Functions

  1. Changes
    - Add function to handle bot user creation/updates
    - Add function to handle bot bookings
    - Add function to get available time slots for bot
    - Add function to validate bot bookings
    
  2. Security
    - Ensure proper access control for bot operations
    - Maintain data integrity
*/

-- Function to handle bot user management
CREATE OR REPLACE FUNCTION bot_manage_user(
  p_telegram_id text,
  p_name text,
  p_phone text,
  p_language text DEFAULT 'en'
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  -- Try to find existing user
  SELECT id INTO v_user_id
  FROM users
  WHERE telegram_id = p_telegram_id;
  
  IF v_user_id IS NULL THEN
    -- Create new user
    INSERT INTO users (
      telegram_id,
      name,
      phone,
      language
    ) VALUES (
      p_telegram_id,
      p_name,
      p_phone,
      p_language
    )
    RETURNING id INTO v_user_id;
  ELSE
    -- Update existing user
    UPDATE users
    SET
      name = p_name,
      phone = p_phone,
      language = p_language
    WHERE id = v_user_id;
  END IF;
  
  RETURN v_user_id;
END;
$$;

-- Function to create bot booking
CREATE OR REPLACE FUNCTION bot_create_booking(
  p_telegram_id text,
  p_staff_id uuid,
  p_date date,
  p_start_time time,
  p_end_time time
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid;
  v_booking_id uuid;
  v_validation booking_validation_result;
BEGIN
  -- Get user ID
  SELECT id INTO v_user_id
  FROM users
  WHERE telegram_id = p_telegram_id;
  
  IF v_user_id IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'User not found'
    );
  END IF;
  
  -- Validate booking
  SELECT * FROM check_booking_availability(
    p_staff_id,
    p_date,
    p_start_time,
    p_end_time
  ) INTO v_validation;
  
  IF NOT v_validation.is_valid THEN
    RETURN json_build_object(
      'success', false,
      'error', v_validation.message
    );
  END IF;
  
  -- Create booking
  INSERT INTO bookings (
    user_id,
    staff_id,
    date,
    start_time,
    end_time,
    status
  ) VALUES (
    v_user_id,
    p_staff_id,
    p_date,
    p_start_time,
    p_end_time,
    'pending'
  )
  RETURNING id INTO v_booking_id;
  
  RETURN json_build_object(
    'success', true,
    'booking_id', v_booking_id
  );
END;
$$;

-- Function to get staff schedule for bot
CREATE OR REPLACE FUNCTION bot_get_staff_schedule(
  p_staff_id uuid,
  p_date date
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
  SELECT * FROM get_available_time_slots(p_staff_id, p_date);
END;
$$;

-- Function to update booking status from bot
CREATE OR REPLACE FUNCTION bot_update_booking_status(
  p_booking_id uuid,
  p_status text,
  p_payment_id text DEFAULT NULL,
  p_zoom_link text DEFAULT NULL,
  p_bitrix_event_id text DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE bookings
  SET
    status = p_status,
    payment_id = COALESCE(p_payment_id, payment_id),
    zoom_link = COALESCE(p_zoom_link, zoom_link),
    bitrix_event_id = COALESCE(p_bitrix_event_id, bitrix_event_id),
    updated_at = now()
  WHERE id = p_booking_id;
  
  RETURN FOUND;
END;
$$;