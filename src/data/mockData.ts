import { StaffMember, StaffSchedule, Booking, User, Analytics, DaySchedule, WeekSchedule } from '../types';

// Generate mock time slots
const generateTimeSlots = (count: number, startHour: number = 9) => {
  const slots = [];
  for (let i = 0; i < count; i++) {
    const start = `${startHour + Math.floor(i)}:${i % 2 === 0 ? '00' : '30'}`;
    const end = `${startHour + Math.floor(i + 0.5)}:${(i + 1) % 2 === 0 ? '00' : '30'}`;
    slots.push({ start, end });
  }
  return slots;
};

// Generate a week of daily schedules
const generateWeekSchedule = (weekStartDate: Date): WeekSchedule => {
  const days: DaySchedule[] = [];
  const weekStart = new Date(weekStartDate);
  
  for (let i = 0; i < 7; i++) {
    const date = new Date(weekStart);
    date.setDate(date.getDate() + i);
    const isWeekend = date.getDay() === 0 || date.getDay() === 6;
    
    days.push({
      date: date.toISOString().split('T')[0],
      dayOfWeek: date.getDay(),
      isWorking: !isWeekend,
      timeSlots: !isWeekend ? generateTimeSlots(8) : []
    });
  }
  
  const weekEnd = new Date(weekStart);
  weekEnd.setDate(weekEnd.getDate() + 6);
  
  return {
    weekStart: weekStart.toISOString().split('T')[0],
    weekEnd: weekEnd.toISOString().split('T')[0],
    days
  };
};

// Mock staff members
export const mockStaffMembers: StaffMember[] = [
  {
    id: '1',
    name: 'Alina Kim',
    position: 'Senior English Tutor',
    photo: 'https://images.pexels.com/photos/762020/pexels-photo-762020.jpeg?auto=compress&cs=tinysrgb&w=800',
    descriptions: {
      en: 'Experienced English teacher with 10+ years of teaching experience. Specializes in IELTS and advanced conversation.',
      ru: 'Опытный преподаватель английского языка с более чем 10-летним стажем. Специализируется на IELTS и продвинутом разговорном курсе.',
      uz: 'Ingliz tili bo\'yicha 10 yildan ortiq tajribaga ega tajribali o\'qituvchi. IELTS va ilg\'or suhbat kurslarida ixtisoslashgan.'
    },
    pricing: 250000,
    available: true
  },
  {
    id: '2',
    name: 'Rustam Karimov',
    position: 'Math Tutor',
    photo: 'https://images.pexels.com/photos/1681010/pexels-photo-1681010.jpeg?auto=compress&cs=tinysrgb&w=800',
    descriptions: {
      en: 'Math specialist with a focus on SAT and university entrance preparation.',
      ru: 'Специалист по математике с упором на подготовку к SAT и поступлению в университет.',
      uz: 'SAT va universitet kirish imtihonlariga tayyorgarlik ko\'rishga e\'tibor qaratgan matematika mutaxassisi.'
    },
    pricing: 200000,
    available: true
  },
  {
    id: '3',
    name: 'Zarina Azimova',
    position: 'Russian Language Tutor',
    photo: 'https://images.pexels.com/photos/733872/pexels-photo-733872.jpeg?auto=compress&cs=tinysrgb&w=800',
    descriptions: {
      en: 'Russian language expert with a focus on conversation and literature.',
      ru: 'Эксперт по русскому языку с упором на разговорную речь и литературу.',
      uz: 'Suhbat va adabiyotga e\'tibor qaratgan rus tili mutaxassisi.'
    },
    pricing: 180000,
    available: false
  }
];

// Generate mock schedules for staff
export const mockStaffSchedules: StaffSchedule[] = mockStaffMembers.map(staff => {
  const today = new Date();
  const thisWeek = new Date(today);
  thisWeek.setDate(thisWeek.getDate() - thisWeek.getDay()); // Start of current week (Sunday)
  
  const nextWeek = new Date(thisWeek);
  nextWeek.setDate(nextWeek.getDate() + 7);
  
  return {
    staffId: staff.id,
    schedule: [
      generateWeekSchedule(thisWeek),
      generateWeekSchedule(nextWeek)
    ]
  };
});

// Generate mock bookings
export const mockBookings: Booking[] = [
  {
    id: '1',
    staffId: '1',
    userId: 'user1',
    userName: 'Alex Johnson',
    userPhone: '+998901234567',
    date: new Date().toISOString().split('T')[0],
    timeSlot: { start: '10:00', end: '11:00' },
    status: 'confirmed',
    paymentId: 'pay_123456',
    zoomLink: 'https://zoom.us/j/1234567890',
    bitrixEventId: 'event_12345',
    createdAt: new Date(Date.now() - 86400000).toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: '2',
    staffId: '2',
    userId: 'user2',
    userName: 'Maria Smith',
    userPhone: '+998907654321',
    date: new Date(Date.now() + 86400000).toISOString().split('T')[0],
    timeSlot: { start: '15:00', end: '16:00' },
    status: 'pending',
    createdAt: new Date(Date.now() - 43200000).toISOString(),
    updatedAt: new Date(Date.now() - 43200000).toISOString()
  },
  {
    id: '3',
    staffId: '1',
    userId: 'user3',
    userName: 'Bobur Aliyev',
    userPhone: '+998912345678',
    date: new Date(Date.now() - 86400000).toISOString().split('T')[0],
    timeSlot: { start: '14:00', end: '15:00' },
    status: 'completed',
    paymentId: 'pay_123457',
    zoomLink: 'https://zoom.us/j/0987654321',
    bitrixEventId: 'event_12346',
    createdAt: new Date(Date.now() - 172800000).toISOString(),
    updatedAt: new Date(Date.now() - 86400000).toISOString()
  }
];

// Mock users
export const mockUsers: User[] = [
  {
    id: 'user1',
    telegramId: '12345678',
    name: 'Alex Johnson',
    phone: '+998901234567',
    language: 'en',
    createdAt: new Date(Date.now() - 864000000).toISOString()
  },
  {
    id: 'user2',
    telegramId: '87654321',
    name: 'Maria Smith',
    phone: '+998907654321',
    language: 'ru',
    createdAt: new Date(Date.now() - 432000000).toISOString()
  },
  {
    id: 'user3',
    telegramId: '13572468',
    name: 'Bobur Aliyev',
    phone: '+998912345678',
    language: 'uz',
    createdAt: new Date(Date.now() - 259200000).toISOString()
  }
];

// Mock analytics data
export const mockAnalytics: Analytics = {
  dailyStats: [
    {
      date: new Date(Date.now() - 6 * 86400000).toISOString().split('T')[0],
      totalBookings: 3,
      confirmedBookings: 2,
      cancelledBookings: 1,
      revenue: 450000
    },
    {
      date: new Date(Date.now() - 5 * 86400000).toISOString().split('T')[0],
      totalBookings: 5,
      confirmedBookings: 4,
      cancelledBookings: 1,
      revenue: 850000
    },
    {
      date: new Date(Date.now() - 4 * 86400000).toISOString().split('T')[0],
      totalBookings: 2,
      confirmedBookings: 2,
      cancelledBookings: 0,
      revenue: 400000
    },
    {
      date: new Date(Date.now() - 3 * 86400000).toISOString().split('T')[0],
      totalBookings: 4,
      confirmedBookings: 3,
      cancelledBookings: 1,
      revenue: 600000
    },
    {
      date: new Date(Date.now() - 2 * 86400000).toISOString().split('T')[0],
      totalBookings: 6,
      confirmedBookings: 5,
      cancelledBookings: 1,
      revenue: 900000
    },
    {
      date: new Date(Date.now() - 86400000).toISOString().split('T')[0],
      totalBookings: 3,
      confirmedBookings: 3,
      cancelledBookings: 0,
      revenue: 630000
    },
    {
      date: new Date().toISOString().split('T')[0],
      totalBookings: 2,
      confirmedBookings: 1,
      cancelledBookings: 0,
      revenue: 250000
    }
  ],
  staffStats: [
    {
      staffId: '1',
      staffName: 'Alina Kim',
      totalBookings: 15,
      revenue: 3750000
    },
    {
      staffId: '2',
      staffName: 'Rustam Karimov',
      totalBookings: 8,
      revenue: 1600000
    },
    {
      staffId: '3',
      staffName: 'Zarina Azimova',
      totalBookings: 2,
      revenue: 360000
    }
  ],
  totalUsers: 25,
  totalBookings: 25,
  totalRevenue: 5710000
};