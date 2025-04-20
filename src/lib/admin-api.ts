import { supabase } from './supabase';
import { DailyStats, StaffStats } from '../types';
import { startOfDay, subDays, format } from 'date-fns';

export const adminAPI = {
  async login(email: string, password: string) {
    const { data, error } = await supabase.rpc('admin_login', {
      p_email: email,
      p_password: password
    });

    if (error) throw error;
    return data;
  },

  async getDashboardStats(): Promise<{
    dailyStats: DailyStats[];
    staffStats: StaffStats[];
    totalBookings: number;
    totalRevenue: number;
    totalUsers: number;
  }> {
    const today = startOfDay(new Date());
    const startDate = subDays(today, 6);

    // Get daily stats
    const { data: dailyStats, error: dailyError } = await supabase
      .from('bookings')
      .select(`
        date,
        status,
        staff!inner (
          pricing
        )
      `)
      .gte('date', format(startDate, 'yyyy-MM-dd'))
      .lte('date', format(today, 'yyyy-MM-dd'));

    if (dailyError) throw dailyError;

    // Get staff stats
    const { data: staffStats, error: staffError } = await supabase
      .from('staff')
      .select(`
        id,
        name,
        bookings (
          id,
          status
        )
      `);

    if (staffError) throw staffError;

    // Get totals
    const { data: totals, error: totalsError } = await supabase
      .from('bookings')
      .select(`
        id,
        status,
        staff!inner (
          pricing
        )
      `);

    if (totalsError) throw totalsError;

    // Get total users
    const { count: userCount, error: userError } = await supabase
      .from('users')
      .select('id', { count: 'exact' });

    if (userError) throw userError;

    // Process daily stats
    const dailyStatsMap = new Map<string, DailyStats>();
    for (let i = 0; i <= 6; i++) {
      const date = format(subDays(today, i), 'yyyy-MM-dd');
      dailyStatsMap.set(date, {
        date,
        totalBookings: 0,
        confirmedBookings: 0,
        cancelledBookings: 0,
        revenue: 0
      });
    }

    dailyStats.forEach(booking => {
      const stats = dailyStatsMap.get(booking.date);
      if (stats) {
        stats.totalBookings++;
        if (booking.status === 'confirmed' || booking.status === 'completed') {
          stats.confirmedBookings++;
          stats.revenue += booking.staff.pricing;
        } else if (booking.status === 'cancelled') {
          stats.cancelledBookings++;
        }
      }
    });

    // Process staff stats
    const processedStaffStats = staffStats.map(staff => ({
      staffId: staff.id,
      staffName: staff.name,
      totalBookings: staff.bookings.length,
      revenue: staff.bookings.reduce((sum, booking) => 
        booking.status === 'confirmed' || booking.status === 'completed' ? sum + 1 : sum, 
        0
      )
    }));

    // Calculate totals
    const totalBookings = totals.length;
    const totalRevenue = totals.reduce((sum, booking) => 
      (booking.status === 'confirmed' || booking.status === 'completed') ? 
      sum + booking.staff.pricing : sum, 
      0
    );

    return {
      dailyStats: Array.from(dailyStatsMap.values()),
      staffStats: processedStaffStats,
      totalBookings,
      totalRevenue,
      totalUsers: userCount || 0
    };
  },

  async getAuditLogs(limit = 10) {
    const { data, error } = await supabase
      .from('audit_logs')
      .select(`
        *,
        admin_users (
          email
        )
      `)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw error;
    return data;
  }
};