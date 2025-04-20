import React, { useEffect, useState } from 'react';
import MainLayout from '../components/Layout/MainLayout';
import StatsCard from '../components/Dashboard/StatsCard';
import BookingChart from '../components/Dashboard/BookingChart';
import StaffPerformance from '../components/Dashboard/StaffPerformance';
import RecentBookings from '../components/Dashboard/RecentBookings';
import { Users, CalendarDays, CreditCard, TrendingUp, Loader2 } from 'lucide-react';
import { adminAPI } from '../lib/admin-api';
import { bookingAPI } from '../lib/booking-api';
import { DailyStats, StaffStats, Booking } from '../types';

const Dashboard: React.FC = () => {
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [stats, setStats] = useState<{
    dailyStats: DailyStats[];
    staffStats: StaffStats[];
    totalBookings: number;
    totalRevenue: number;
    totalUsers: number;
  } | null>(null);
  const [recentBookings, setRecentBookings] = useState<Booking[]>([]);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      setIsLoading(true);
      const [dashboardStats, bookings] = await Promise.all([
        adminAPI.getDashboardStats(),
        bookingAPI.getBookings()
      ]);

      setStats(dashboardStats);
      setRecentBookings(bookings.slice(0, 5));
      setError(null);
    } catch (err) {
      console.error('Error loading dashboard data:', err);
      setError('Failed to load dashboard data');
    } finally {
      setIsLoading(false);
    }
  };

  if (isLoading) {
    return (
      <MainLayout title="Dashboard">
        <div className="flex items-center justify-center h-64">
          <Loader2 size={40} className="animate-spin text-blue-600" />
        </div>
      </MainLayout>
    );
  }

  if (error || !stats) {
    return (
      <MainLayout title="Dashboard">
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded relative">
          {error || 'Failed to load dashboard data'}
        </div>
      </MainLayout>
    );
  }

  const { totalBookings, totalRevenue, totalUsers, dailyStats, staffStats } = stats;
  
  // Calculate week-over-week changes
  const currentWeekBookings = dailyStats.reduce((sum, day) => sum + day.totalBookings, 0);
  const previousWeekBookings = currentWeekBookings * 0.8; // Mock data for example
  const bookingChange = Math.round(((currentWeekBookings - previousWeekBookings) / previousWeekBookings) * 100);

  const currentWeekRevenue = dailyStats.reduce((sum, day) => sum + day.revenue, 0);
  const previousWeekRevenue = currentWeekRevenue * 0.9; // Mock data for example
  const revenueChange = Math.round(((currentWeekRevenue - previousWeekRevenue) / previousWeekRevenue) * 100);

  return (
    <MainLayout title="Dashboard">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <StatsCard 
          title="Total Bookings" 
          value={totalBookings} 
          icon={<CalendarDays size={18} />} 
          change={bookingChange}
        />
        <StatsCard 
          title="Total Revenue" 
          value={new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'UZS',
            minimumFractionDigits: 0
          }).format(totalRevenue)} 
          icon={<CreditCard size={18} />} 
          change={revenueChange}
        />
        <StatsCard 
          title="Total Users" 
          value={totalUsers} 
          icon={<Users size={18} />} 
          change={5} 
        />
        <StatsCard 
          title="Conversion Rate" 
          value={`${Math.round((dailyStats.reduce((sum, day) => sum + day.confirmedBookings, 0) / totalBookings) * 100)}%`}
          icon={<TrendingUp size={18} />} 
          change={3} 
        />
      </div>
      
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
        <div className="lg:col-span-2">
          <BookingChart data={dailyStats} />
        </div>
        <div>
          <StaffPerformance data={staffStats} />
        </div>
      </div>
      
      <RecentBookings bookings={recentBookings} />
    </MainLayout>
  );
};

export default Dashboard;