import React from 'react';
import { DailyStats } from '../../types';

type BookingChartProps = {
  data: DailyStats[];
};

const BookingChart: React.FC<BookingChartProps> = ({ data }) => {
  const maxBookings = Math.max(...data.map(day => day.totalBookings));
  
  return (
    <div className="bg-white rounded-xl shadow-sm p-6">
      <div className="flex justify-between items-center mb-6">
        <h3 className="text-lg font-semibold text-gray-900">Booking Trends</h3>
        <select className="text-sm border border-gray-300 rounded-md px-3 py-1.5">
          <option>Last 7 days</option>
          <option>Last 30 days</option>
          <option>Last 3 months</option>
        </select>
      </div>
      
      <div className="h-64">
        <div className="flex h-full items-end space-x-2">
          {data.map((day, index) => {
            const height = (day.totalBookings / maxBookings) * 100;
            const confirmedHeight = (day.confirmedBookings / day.totalBookings) * height;
            const cancelledHeight = (day.cancelledBookings / day.totalBookings) * height;
            const pendingHeight = height - confirmedHeight - cancelledHeight;
            
            const dayOfWeek = new Date(day.date).toLocaleDateString('en-US', { weekday: 'short' });
            
            return (
              <div key={index} className="flex-1 flex flex-col items-center justify-end">
                <div className="w-full relative" style={{ height: `${height}%` }}>
                  <div 
                    className="absolute bottom-0 w-full bg-green-500 rounded-t-sm" 
                    style={{ height: `${confirmedHeight}%` }}
                  />
                  <div 
                    className="absolute bottom-0 w-full bg-yellow-500 rounded-t-sm" 
                    style={{ height: `${pendingHeight}%`, marginBottom: `${confirmedHeight}%` }}
                  />
                  <div 
                    className="absolute bottom-0 w-full bg-red-500 rounded-t-sm" 
                    style={{ height: `${cancelledHeight}%`, marginBottom: `${confirmedHeight + pendingHeight}%` }}
                  />
                </div>
                <div className="text-xs text-gray-500 mt-2">{dayOfWeek}</div>
              </div>
            );
          })}
        </div>
      </div>
      
      <div className="flex justify-center space-x-6 mt-4">
        <div className="flex items-center">
          <div className="w-3 h-3 rounded-full bg-green-500 mr-2"></div>
          <span className="text-xs text-gray-600">Confirmed</span>
        </div>
        <div className="flex items-center">
          <div className="w-3 h-3 rounded-full bg-yellow-500 mr-2"></div>
          <span className="text-xs text-gray-600">Pending</span>
        </div>
        <div className="flex items-center">
          <div className="w-3 h-3 rounded-full bg-red-500 mr-2"></div>
          <span className="text-xs text-gray-600">Cancelled</span>
        </div>
      </div>
    </div>
  );
};

export default BookingChart;