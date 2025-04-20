import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { CalendarDays, Users, BarChart2, Settings, Calendar, LogOut } from 'lucide-react';

type NavItemProps = {
  to: string;
  icon: React.ReactNode;
  label: string;
  active: boolean;
};

const NavItem: React.FC<NavItemProps> = ({ to, icon, label, active }) => {
  return (
    <Link
      to={to}
      className={`flex items-center space-x-3 px-4 py-3 rounded-lg transition-colors ${
        active
          ? 'bg-blue-100 text-blue-700'
          : 'text-gray-700 hover:bg-gray-100'
      }`}
    >
      <div className="flex-shrink-0">{icon}</div>
      <span className="font-medium">{label}</span>
    </Link>
  );
};

const Sidebar: React.FC = () => {
  const location = useLocation();
  const currentPath = location.pathname;

  const navItems = [
    {
      to: '/dashboard',
      icon: <BarChart2 size={20} />,
      label: 'Dashboard',
    },
    {
      to: '/bookings',
      icon: <Calendar size={20} />,
      label: 'Bookings',
    },
    {
      to: '/staff',
      icon: <Users size={20} />,
      label: 'Staff',
    },
    {
      to: '/schedule',
      icon: <CalendarDays size={20} />,
      label: 'Schedule',
    },
    {
      to: '/settings',
      icon: <Settings size={20} />,
      label: 'Settings',
    },
  ];

  return (
    <div className="w-64 h-full bg-white border-r border-gray-200 flex flex-col">
      <div className="p-6">
        <div className="flex items-center space-x-2">
          <Calendar className="h-8 w-8 text-blue-600" />
          <h1 className="text-xl font-bold text-gray-900">BookingBot</h1>
        </div>
      </div>
      <div className="flex-1 px-3 py-4 space-y-1">
        {navItems.map((item) => (
          <NavItem
            key={item.to}
            to={item.to}
            icon={item.icon}
            label={item.label}
            active={currentPath === item.to}
          />
        ))}
      </div>
      <div className="p-4 border-t border-gray-200">
        <button className="flex items-center space-x-3 px-4 py-3 w-full rounded-lg text-gray-700 hover:bg-gray-100 transition-colors">
          <LogOut size={20} />
          <span className="font-medium">Logout</span>
        </button>
      </div>
    </div>
  );
};

export default Sidebar;