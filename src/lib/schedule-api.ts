import { supabase } from './supabase';
import { DaySchedule, TimeSlot } from '../types';

export const scheduleAPI = {
  async getStaffSchedule(staffId: string, startDate: string, endDate: string) {
    // Get schedules for the date range
    const { data: schedules, error: schedulesError } = await supabase
      .from('schedules')
      .select(`
        id,
        date,
        is_working,
        time_slots (
          id,
          start_time,
          end_time
        )
      `)
      .eq('staff_id', staffId)
      .gte('date', startDate)
      .lte('date', endDate)
      .order('date');

    if (schedulesError) throw schedulesError;

    // Convert to DaySchedule format
    const days: DaySchedule[] = [];
    const currentDate = new Date(startDate);
    const end = new Date(endDate);

    while (currentDate <= end) {
      const dateStr = currentDate.toISOString().split('T')[0];
      const schedule = schedules?.find(s => s.date === dateStr);
      
      days.push({
        id: schedule?.id,
        date: dateStr,
        dayOfWeek: currentDate.getDay(),
        isWorking: schedule?.is_working ?? false,
        timeSlots: schedule?.time_slots.map(slot => ({
          id: slot.id,
          start: slot.start_time,
          end: slot.end_time
        })) ?? []
      });

      currentDate.setDate(currentDate.getDate() + 1);
    }

    return days;
  },

  async setWorkingDay(staffId: string, date: string, isWorking: boolean) {
    // First check if a schedule exists
    const { data: existingSchedule } = await supabase
      .from('schedules')
      .select('id')
      .eq('staff_id', staffId)
      .eq('date', date)
      .limit(1)
      .maybeSingle();

    if (existingSchedule) {
      // Update existing schedule
      const { data, error } = await supabase
        .from('schedules')
        .update({ is_working: isWorking })
        .eq('id', existingSchedule.id)
        .select()
        .single();

      if (error) throw error;
      return data;
    } else {
      // Create new schedule
      const { data, error } = await supabase
        .from('schedules')
        .insert({
          staff_id: staffId,
          date,
          is_working: isWorking
        })
        .select()
        .single();

      if (error) throw error;
      return data;
    }
  },

  async addTimeSlot(staffId: string, date: string, slot: TimeSlot) {
    // First, get or create the schedule for this date
    const { data: existingSchedule } = await supabase
      .from('schedules')
      .select('id')
      .eq('staff_id', staffId)
      .eq('date', date)
      .limit(1)
      .maybeSingle();

    let scheduleId;

    if (existingSchedule) {
      scheduleId = existingSchedule.id;
    } else {
      // Create new schedule
      const { data: newSchedule, error: scheduleError } = await supabase
        .from('schedules')
        .insert({
          staff_id: staffId,
          date,
          is_working: true
        })
        .select()
        .single();

      if (scheduleError) throw scheduleError;
      scheduleId = newSchedule.id;
    }

    // Add the time slot
    const { data: timeSlot, error: slotError } = await supabase
      .from('time_slots')
      .insert({
        schedule_id: scheduleId,
        start_time: slot.start,
        end_time: slot.end
      })
      .select()
      .single();

    if (slotError) throw slotError;
    return timeSlot;
  },

  async removeTimeSlot(scheduleId: string, slotId: string) {
    const { error } = await supabase
      .from('time_slots')
      .delete()
      .eq('id', slotId)
      .eq('schedule_id', scheduleId);

    if (error) throw error;
  }
};