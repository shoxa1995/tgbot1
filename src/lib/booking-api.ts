import { supabase } from './supabase';
import { Booking } from '../types';

export const bookingAPI = {
  async getBookings() {
    const { data, error } = await supabase
      .from('bookings')
      .select(`
        *,
        users (
          name,
          phone
        ),
        staff (
          name
        )
      `)
      .order('date', { ascending: false });

    if (error) throw error;
    return data;
  },

  async checkAvailability({
    staff_id,
    date,
    start_time,
    end_time,
    booking_id = null
  }: {
    staff_id: string;
    date: string;
    start_time: string;
    end_time: string;
    booking_id?: string | null;
  }): Promise<{ is_valid: boolean; message: string }> {
    const { data, error } = await supabase
      .rpc('check_booking_availability', {
        p_staff_id: staff_id,
        p_date: date,
        p_start_time: start_time,
        p_end_time: end_time,
        p_booking_id: booking_id,
        p_buffer_minutes: 15
      });

    if (error) {
      throw new Error('Failed to check availability: ' + error.message);
    }

    return data;
  },

  async getAvailableTimeSlots(staffId: string, date: string) {
    const { data, error } = await supabase
      .rpc('get_available_time_slots', {
        p_staff_id: staffId,
        p_date: date,
        p_buffer_minutes: 15
      });

    if (error) throw error;
    return data;
  },

  async createBooking(booking: Omit<Booking, 'id' | 'created_at' | 'updated_at'>) {
    // First check availability
    const availabilityCheck = await this.checkAvailability({
      staff_id: booking.staff_id,
      date: booking.date,
      start_time: booking.start_time,
      end_time: booking.end_time
    });

    if (!availabilityCheck.is_valid) {
      throw new Error(availabilityCheck.message || 'Time slot is not available');
    }

    const { data, error } = await supabase
      .from('bookings')
      .insert([booking])
      .select(`
        *,
        users (
          name,
          phone
        ),
        staff (
          name
        )
      `)
      .single();

    if (error) throw error;
    return data;
  },

  async updateBooking(id: string, updates: Partial<Booking>) {
    // Check availability if time-related fields are being updated
    if (updates.start_time || updates.end_time || updates.date || updates.staff_id) {
      const availabilityCheck = await this.checkAvailability({
        staff_id: updates.staff_id!,
        date: updates.date!,
        start_time: updates.start_time!,
        end_time: updates.end_time!,
        booking_id: id
      });

      if (!availabilityCheck.is_valid) {
        throw new Error(availabilityCheck.message || 'Time slot is not available');
      }
    }

    const { data, error } = await supabase
      .from('bookings')
      .update(updates)
      .eq('id', id)
      .select(`
        *,
        users (
          name,
          phone
        ),
        staff (
          name
        )
      `)
      .single();

    if (error) throw error;
    return data;
  },

  async deleteBooking(id: string) {
    const { error } = await supabase
      .from('bookings')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
};