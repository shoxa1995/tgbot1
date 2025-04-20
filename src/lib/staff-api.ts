import { supabase } from './supabase';
import { StaffMember } from '../types';

export const staffAPI = {
  async getStaff() {
    const { data, error } = await supabase
      .from('staff')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
  },

  async createStaff(staff: Omit<StaffMember, 'id'>) {
    const { data, error } = await supabase
      .from('staff')
      .insert([staff])
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async updateStaff(id: string, updates: Partial<StaffMember>) {
    const { data, error } = await supabase
      .from('staff')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async deleteStaff(id: string) {
    const { error } = await supabase
      .from('staff')
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
};