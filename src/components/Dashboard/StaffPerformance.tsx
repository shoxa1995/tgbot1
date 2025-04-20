import React from 'react';
import { StaffStats } from '../../types';

type StaffPerformanceProps = {
  data: StaffStats[];
};

const StaffPerformance: React.FC<StaffPerformanceProps> = ({ data }) => {
  // Sort staff by total bookings descending
  const sortedStaff = [...data].sort((a, b) => b.totalBookings - a.totalBookings);
  
  return (
    <div className="bg-white rounded-xl shadow-sm p-6">
      <div className="flex justify-between items-center mb-6">
        <h3 className="text-lg font-semibold text-gray-900">Staff Performance</h3>
        <select className="text-sm border border-gray-300 rounded-md px-3 py-1.5">
          <option>By Bookings</option>
          <option>By Revenue</option>
        </select>
      </div>
      
      <div className="space-y-5">
        {sortedStaff.map((staff) => {
          // Calculate percentage of bookings compared to the top performer
          const percentOfTop = (staff.totalBookings / sortedStaff[0].totalBookings) * 100;
          
          return (
            <div key={staff.staffId}>
              <div className="flex justify-between items-center mb-1">
                <span className="font-medium text-gray-700">{staff.staffName}</span>
                <span className="text-sm text-gray-500">{staff.totalBookings} bookings</span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2.5">
                <div 
                  className="bg-blue-600 h-2.5 rounded-full" 
                  style={{ width: `${percentOfTop}%` }}
                ></div>
              </div>
              <div className="flex justify-between items-center mt-1 text-xs text-gray-500">
                <span>Revenue: {new Intl.NumberFormat('en-US', {
                  style: 'currency',
                  currency: 'UZS',
                  minimumFractionDigits: 0
                }).format(staff.revenue)}</span>
                <span>Avg: {new Intl.NumberFormat('en-US', {
                  style: 'currency',
                  currency: 'UZS',
                  minimumFractionDigits: 0
                }).format(staff.revenue / staff.totalBookings)}</span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default StaffPerformance;