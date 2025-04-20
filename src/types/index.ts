// Staff Member types
export type Language = 'en' | 'ru' | 'uz';

export type StaffMember = {
  id: string;
  name: string;
  position: string;
  photo_url: string;
  description_en: string;
  description_ru: string;
  description_uz: string;
  pricing: number;
  available: boolean;
};

// Availability types
export type TimeSlot = {
  id?: string;
  start: string;
  end: string;
};

export type DaySchedule = {
  id?: string;
  date: string;
  dayOfWeek: number;
  isWorking: boolean;
  timeSlots: TimeSlot[];
};

export type WeekSchedule = {
  weekStart: string;
  weekEnd: string;
  days: DaySchedule[];
};

export type StaffSchedule = {
  staffId: string;
  schedule: WeekSchedule[];
};

// Booking types
export type BookingStatus = 'pending' | 'confirmed' | 'cancelled' | 'completed';

export type Booking = {
  id: string;
  staff_id: string;
  user_id: string;
  date: string;
  start_time: string;
  end_time: string;
  status: BookingStatus;
  payment_id?: string;
  zoom_link?: string;
  bitrix_event_id?: string;
  created_at: string;
  updated_at: string;
  // Joined fields
  users?: {
    name: string;
    phone?: string;
  };
  staff?: {
    name: string;
  };
};

// User types
export type User = {
  id: string;
  telegram_id: string;
  name: string;
  phone?: string;
  language: Language;
  created_at: string;
};

// Analytics types
export type DailyStats = {
  date: string;
  totalBookings: number;
  confirmedBookings: number;
  cancelledBookings: number;
  revenue: number;
};

export type StaffStats = {
  staffId: string;
  staffName: string;
  totalBookings: number;
  revenue: number;
};

export type Analytics = {
  dailyStats: DailyStats[];
  staffStats: StaffStats[];
  totalUsers: number;
  totalBookings: number;
  totalRevenue: number;
};